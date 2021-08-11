require 'active_support/concern'

module Feedbacker
  module FeedbackerUsersController
    extend ActiveSupport::Concern
    
    included do


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






    module ClassMethods


    end


  end
end