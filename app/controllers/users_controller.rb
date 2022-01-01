class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :hide_news_menu, only: [:conversations]
  include Feedbacker::FeedbackerUsersController
  
  def welcome
    @user = current_user
    #render show, notice: "Welcome #{@user.email}"
  end

  def profile
    @user = current_user
    
    render "show"
  end


  private
  def hide_news_menu
    @hide_news_menu = true
  end
  
=begin
  def index

    if params[:demo]
      10.times.each do |num|
        u1 = User.new(email:"test#{num+3}@test.com")
        u1.password = "testing"
        u1.save!
      end
    end

    @users = User.page(params[:page]).per(5)
  end
=end
=begin
  def show
    @user = User.find(params[:id])
  end
=end



end