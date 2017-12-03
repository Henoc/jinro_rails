class Api::V1::VillagesController < ApplicationController
  include VillagesHelper

  before_action :set_village

  def remaining_time
    render json: {remaining_time: @village.remaining_time}, status: 200
  end

  def proceed
    if @village.next_update_time <= Time.now
      noon_process
      night_process
      ReloadBroadcastJob.perform_later(@village)
    end
    head :ok
  end

  def divine
    render json: {messages: messages_of_result(@village.divine_results)}, status: 200
  end

  def see_soul
    render json: {messages: messages_of_result(@village.vote_results)}, status: 200
  end

  private

  def noon_process
    @village.lynch
    @village.update_divined_player_of_result
    @village.update_guarded_player_of_result
    @village.room_for_all.posts.create!(content: noon_message(@village), day: @village.day, owner: :system)
    case @village.judge_end
    when :werewolf_win
      @village.update!(status: :ended)
    when :human_win
      @village.update!(status: :ended)
    end
  end

  def night_process
    return if @village.ended?
    @village.attack
    @village.room_for_all.posts.create!(content: night_message(@village), day: @village.day, owner: :system)
    case @village.judge_end
    when :werewolf_win
      @village.update!(status: :ended)
    when :human_win
      @village.update!(status: :ended)
    else
      @village.update!(day: @village.day + 1, next_update_time: Time.now + @village.discussion_time.minutes)
      @village.prepare_records
      @village.prepare_result
      @village.room_for_all.posts.create!(content: morning_message(@village), day: @village.day, owner: :system)
    end
  end

  def set_village
    @village = Village.find(params[:id])
  end
end
