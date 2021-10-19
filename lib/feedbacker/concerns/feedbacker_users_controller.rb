require 'active_support/concern'

module Feedbacker
  module FeedbackerUsersController
    extend ActiveSupport::Concern
    
    included do
      before_action :set_user, only: %i[ show destroy ] # update
      before_action :authenticate_admin!, only: %i[ destroy ]

    end

      # method to add to controller
      def index

        @users = User.all
        if User.respond_to?(:page)
          @users = @users.page(params[:page]).per(5)
        end

        #render json: {result: "all users"}
        #render "feedbacker_index"
      end

      def show
        @user = User.find(params[:id])
      end

    def destroy
      @user.update(removed:true,removed_at:Time.now,removed_by:current_user.id)
      flash[:notice] = "User removed"
      #redirect_to controller: "admin", action: "users"
      redirect_to feedbacker.admin_users_path
    end






    module ClassMethods


    end


    private
    
    def set_user
      @user = User.find_by(id:params[:id])
    end


  end
end