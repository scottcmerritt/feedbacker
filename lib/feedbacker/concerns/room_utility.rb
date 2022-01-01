module Feedbacker
module RoomUtility
  extend ActiveSupport::Concern

  included do
    #before_action :method_here
  
  

  end


  private

   def load_user_colors
    @user_color = UserColor.new({:room=>@room,:users=>@users})
    @colors_indexed = @user_color.user_colors
  end

  def get_user_color user = nil
    #UserColor.new({:indexed=>})
    @user_color = UserColor.new({:room=>@room,:users=>@room.room_users.where("role_id>0")}) if @user_color.nil?
    
    _color = @user_color.get_color(user.nil? ? current_user : user)
    @colors_indexed = @user_color.user_colors
    return _color
  end

  def load_room_people
    # NOTE: any time we render the people, it is VERY slow 
    @users = @room.users
    #load_user_colors

    # (also, there are bugs based on the UI of the sender gets sent to the other people
    locals = {:users=>@users,:colors=>@colors_indexed,:room=>@room,:room_orgs=>@room.room_orgs.order("id asc"),:show=>{stats:false,msg_counts:false}}
    render_to_string(:partial=>"users/participants/list",:locals=>locals,:layout=>false)
  end

  def add_room_preview otype, oid
    unless RoomPreview.where(room_id:@room.id,preview_type:otype,preview_id:oid).exists?
      RoomPreview.create(room_id:@room.id,preview_type:otype,preview_id:oid,created_by:current_user.id)
      @item = Community::Preview.get(otype,oid,is_admin?)
    end
  end
    
end
end