# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  username               :string           not null
#  role                   :integer          default("normal"), not null
#  locked_at              :datetime
#

class User < ApplicationRecord
  after_update_commit :upload_variant_avatar
  after_create_commit :create_profile!

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable

  enum role: {
    normal: 0,
    admin: 1
  }

  has_many :villages
  has_many :players
  has_one_attached :avatar
  has_one :profile, dependent: :destroy

  validates :username, presence: true, length: {in: 1..20}, uniqueness: true
  validates :role, presence: true

  def joining_in_village?
    if players.includes(:village).find { |p| p.village && (p.village.not_started? || p.village.in_play?) }
      true
    else
      false
    end
  end

  def joined_village_count(role: nil)
    p = players.joins(:village).where(villages: {status: :ended})
    p = p.where(role: role) if role
    p.count
  end

  def winned_village_count(role: nil)
    if role.in?(Player.human_side_roles)
      human_winned_village_players.where(role: role).count
    elsif role.in?(Player.werewolf_side_roles)
      werewolf_winned_village_players.where(role: role).count
    else
      human_winned_village_players.where(role: Player.human_side_roles).count +
        werewolf_winned_village_players.where(role: Player.werewolf_side_roles).count
    end
  end

  private

  def human_winned_village_players
    players.joins(:village).where(villages: {winner: :human_win})
  end

  def werewolf_winned_village_players
    players.joins(:village).where(villages: {winner: :werewolf_win})
  end

  def upload_variant_avatar
    return unless avatar.attached?
    UploadVariantAvatarJob.perform_later(self)
  end
end
