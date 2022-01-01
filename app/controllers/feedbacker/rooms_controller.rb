module Feedbacker
class RoomsController < ::ApplicationController

	before_action :load_entities
	def self.controller_path
		"community/rooms"
	end

	def show
	
		if !@room.can_view? current_user  
		    logger.debug "cannot view"
		    redirect_to room_join_path @room
		end

		@room_message = RoomMessage.new room: @room
		load_room_to_show
	end

	private

	 def load_entities
	    #@rooms = Room.all
	    @room = Room.find(params[:id]) if params[:id] && params[:id].to_i > 0
	    @user = current_user
	end

	 def load_room_to_show guest_view = false, top = false
	    suggest_links rescue nil


	    #TODO: index the colors and cache it so people share the same colors. OR use chat colors to indicate something else

	    @otype    = params[:otype] ? params[:otype].singularize : nil

	    load_previews rescue nil

	    @room_message = RoomMessage.new room: @room
	    if top
	      @room_messages =RoomMessage.select("room_messages.*").customsort("interesting", label: "interesting",recency_key: 3)
	      .where(room_id:@room.id,parent_id:0)
	    else
	      messages = @room.room_messages.includes(:user).where(parent_id:0).order("room_messages.created_at ASC")

	      @room_messages = RoomMessage.process_removed messages
	    end

	    #@users = @room.users

	    
	#    @gradient = Gradient.new(:steps=>11,:colors=>["#2abe05","#ffeb00","#f8ab08","#ff2c03"]).hex
	    
	    load_user_colors rescue nil
	 end

	

end
end