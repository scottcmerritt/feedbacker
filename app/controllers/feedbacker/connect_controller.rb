module Feedbacker
class ConnectController < ::ApplicationController
	# used for "friendships" between users, AND also for indicating PUBLIC interest for items
  before_action :authenticate_user!, only: [:engage, :list]

	def self.controller_path
    "feedbacker/community/connect" # sets the path from app/views/... to something else
  end

  # '/engage/:resource/:id/:scope'
  # engage_comment_path
  # '/engage/:otype/:id/:scope'
  def engage
    @otypes = ["comment","post"]
    @otype = params[:otype]
    @otype = @otypes.include?(@otype) ? @otype : nil


    @frame = params[:frame]

    scope_keys = Feedbacker.engage_keys #{"flag"=>"flagged","like"=>"liked","love"=>"loved","agree"=>"agreed"}
    @scope = params[:scope] if scope_keys.include?(params[:scope])

    unless @scope.nil?
      @resource = @otype == "post" ? Post.find_by(id: params[:id]) : Comment.find_by(id: params[:id])
      if params[:undo]
        current_user.unfavorite(@resource, scope: scope_keys[@scope].to_sym) if scope_keys[@scope]
      else
        current_user.favorite(@resource, scope: scope_keys[@scope].to_sym) if scope_keys[@scope]
        @resource.announce_engage! sender:current_user, engage_key: @scope
      end
    end
  end


  	def list

      # TURNED OFF for feedbacker
      #@items = current_user.favorited_by_type('Newsify::Item') #current_user.requested_friends.collect {|obj| obj if obj.friendable_type == "Item"}
      #@items_requested = [] #current_user.requested_friends.collect {|obj| obj if obj.friendable_type == "Item"}

=begin
      # randomly assign some of current user's favorites to the other users
      User.all.each do |user|
        @items.sample(2).each do |item|
          user.favorite item
        end
      end
=end
      unless current_user.nil?
        @pending = current_user.pending_friends.where("friendships.friendable_type = ?", "User") #.collect {|obj| obj if obj.is_a?(User)}
        @requested = current_user.requested_friends.where("friendships.friendable_type = ?", "User") #.collect {|obj| obj if obj.is_a?(User)}
  		  @connections = current_user.friends.where("friendships.friendable_type = ?", "User") #.collect {|obj| obj if obj.is_a?(User)}
      end
    end


  	def add
      @otype = params[:otype]

  		if ["item","user","source"].include?(@otype)

        if @otype == "user"
    			@target = User.find(params[:id])
          #@target.sample_email!
          UserMailer.sample_email(@target)
          add_connection!

        elsif @otype == "item"
          @target = Item.find(params[:id])
          current_user.favorite(@target)
        elsif @otype == "source"
          @target = Source.find(params[:id])
          current_user.favorite(@target)

#          add_connection! announce: false, force_accept: false
        end

  			respond_to do |format|
		      format.html {redirect_to params[:r] ? path_to_redirect(params[:r],@target) : connections_path}
          format.js {render "add"}
		      format.json { render json: "added" }
		    end
  		end
  	end

    def cancel
      @otype = params[:otype]

      if ["item","user","source"].include?(@otype)
      
        if @otype == "user"
          @target = User.find(params[:id])
          if current_user.friends_with?(@target)
            # .remove_friend(@mac) .block_friend .unblock_friend
            current_user.remove_friend(@target)
          else
            current_user.decline_request(@target)
          end
=begin          
        elsif @otype == "item"
          @target = Newsify::Item.find(params[:id])
          current_user.unfavorite(@target)
        elsif @otype == "source"
          @target = Newsify::Source.find(params[:id])
          current_user.unfavorite(@target)
=end          
        end

        respond_to do |format|
          format.html {redirect_to params[:r] ? path_to_redirect(params[:r],@target) : connections_path}
          format.js {render "add"}
          format.json { render json: "added" }
        end
      end
    end

    private 

    def path_to_redirect redirect_key, target
      if redirect_key == "int_e"
        return profile_interests_edit_path(id:user_id)
      else
        return target
      end
    end

    def add_connection! announce: true, force_accept: false
      unless current_user.friends_with?(@target)
          if current_user.requested_friends.include?(@target)
           
           current_user.accept_request(@target)
           # now they are connected, announe it
            announce_request!(true) if announce
         else
          current_user.friend_request(@target)
          if force_accept
            @target.friend_request current_user
            @target.accept_request current_user
          end

          announce_request! if announce
         end
         #@user.accept_request(current_user)
        end
    end

    def announce_request! approved=false
         unless @target.nil? || @target.blocked_friends.include?(current_user)
           @target.announce_request!(current_user,approved) #if @target.respond_to?(:announce_request!)
           locals = {:actor=>current_user,:current_user=>@target,:users=>@target.requested_friends,:user_limit=>3,:approved=>approved}
           request_html = render_to_string(:partial=>"/users/participants/requests",:locals=>locals,:layout=>false)

           NotificationChannel.broadcast_to @target, {:requests=>"requested",:request=>request_html} if defined?(NotificationChannel)
          
         end
    end

    def user_id
      params[:user_id] ? (is_admin? ? params[:user_id] : current_user.id) : current_user.id

    end
end
end