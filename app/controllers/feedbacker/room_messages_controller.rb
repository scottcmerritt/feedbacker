module Feedbacker
class RoomMessagesController < ApplicationController
  include Feedbacker::RoomUtility
  before_action :load_entities

  def create
      save_and_broadcast if @room.can_post? current_user
      if !defined?(RoomChannel)
        messages = @room.room_messages.includes(:user).where(parent_id:0).order("room_messages.created_at ASC")
        @room_messages = RoomMessage.process_removed messages
        render "community/rooms/chat_added"
      end
  end

  def soft_remove

    @room_message = RoomMessage.find_by(id: params[:id])
    @room_message.soft_remove!(current_user) if is_admin?
  end

  def show
    render json: RoomMessage.find(params[:id])
  end

  protected

  def save_and_broadcast
    @room_message = RoomMessage.create user: current_user,
                                         room: @room,
                                         message: params.dig(:room_message, :message),
                                         parent_id: params.dig(:room_message, :parent_id) || 0

     is_new = !@room.has_user?(current_user)
     custom = {newMessage:@room_message}
     if is_new

      custom[:newMessage].bg_color = get_user_color
      @room.add_user user:current_user, role_id:2, bg_color:custom[:newMessage].bg_color
      
      custom[:people] =  load_room_people 
     else
      custom[:newMessage].bg_color = get_user_color
     end
     logger.debug "ABOUT TO BROADCAST"

     RoomChannel.broadcast_to @room, custom if defined?(RoomChannel)

     #@test_room = Room.new(:id=>10)
     # this works, or edit the as_json method in the target model
     #UserChannel.broadcast_to current_user, {message: @room_message,sender: @room_message.user} #.includes(:user)
     @room_message.show_room = true
     UserChannel.broadcast_to current_user, @room_message if defined?(UserChannel)

     current_user.add_points(1, category: 'equity-eligible') if current_user.respond_to?(:add_points)
  end 

  def load_entities
    @room = Room.find params.dig(:room_message, :room_id) unless params[:room_message].nil?
  end
end
end