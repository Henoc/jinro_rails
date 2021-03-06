class RoomsController < ApplicationController
  skip_before_action :authenticate_user!, only: :show
  before_action :set_room, only: :show
  before_action :color_of_navbar

  def show
  end

  private

  def set_room
    @room = Room.find(params[:id])
    authorize @room
    @village = @room.village
    @record = @village.record_from_user(current_user)
  end

  def color_of_navbar
    if @room.for_wolf?
      @color_of_navbar = 'black'
    elsif @room.for_dead?
      @color_of_navbar = 'green'
    else
      @color_of_navbar = 'red'
    end
  end
end
