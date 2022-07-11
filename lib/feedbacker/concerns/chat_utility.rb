module Feedbacker
module ChatUtility
  extend ActiveSupport::Concern

    
  
  included do
    #before_action :method_here
    before_action :authenticate_user!, only: %i[autocomplete_search]

  end


  # most work is done via js
  def search_select
    @user = User.find_by(id:params[:user_id])
    render "community/shared/search/selected"
  end


  def autocomplete_search
    @q = params[:q]
    #@users = User.limit(20)
    if @q.to_i.to_s == @q
      @users = User.search_user_and_id(@q).limit(20)
    else
      @users = User.search_user(@q).limit(20) #.or(User.where(id:@q))
    end

    path_to_click = "search_select_user"
    click_params = {}
    locals = {:js=>false,:people=>@users,target:@target,click_params:click_params,path_to_click:path_to_click}
    html = render_to_string(:partial=>"community/shared/search/users",:locals=>locals,:layout=>false)
  
    render json: {html: html} #{}"<div>#{@q}</div>"}

  end  

  def conversations_add
    target_id = params[:target_id] || params[:room_message][:target_user_id]
    @message = params[:room_message][:message]

    @room, added_message = UserConversation.add_message! message: @message, sender: current_user, recipient_id: target_id, reward: true
=begin
    if target_id
      conv = UserConversation.joins("LEFT JOIN rooms on user_conversations.room_id = rooms.id")
      .where("rooms.closed = ? AND ((user_conversations.user_id = ? AND user_conversations.target_id = ?) OR (user_conversations.target_id = ? AND user_conversations.user_id = ?))",false,current_user.id,target_id,target_id,current_user.id).first
      if conv.nil?
        conv = UserConversation.add user_id:current_user.id, target_id: target_id
      end
    end

    @room = conv.room
    room_message = conv.send_message! message: @message, sender: current_user unless @message.blank?
    RoomChannel.broadcast_to @room, {newMessage:room_message} if defined?(RoomChannel)
=end
    @room_message = RoomMessage.new

    #@conversation = UserConversation.mine(current_user.id).find_by(id:conv.id) # (user_conversations: {id:conv.id})

    respond_to do |format|
      #format.html {redirect_to conv.nil? || conv.room.nil? ? rooms_path : room_path(id:conv.room.id)}
      format.html {redirect_to conv.nil? || @room.nil? ? rooms_path : room_path(id:@room.id)}
      format.js do 
        @feedback = "Message sent"
        render "community/conversations/added"
      end
      #format.json {}
    end
  end

  # /conversations(:status)
  def conversations

    @room_message = RoomMessage.new

    @closed = params[:status] == "closed"

    @conversations = UserConversation.mine current_user.id
    @conversations = @closed ? @conversations.where("rooms.closed = ?",@closed) : @conversations.where("NOT rooms.closed = ?",true)
    

    @conversations.each do |conv|
      if conv.room.nil?
        conv.destroy
      else
        conv.room.update(is_chat: true)
      end
    end

    render "community/conversations/index"
  end


  private

end
end