module Feedbacker
  # could have been called conversations_controller
class ChatController < ::ApplicationController
  include Feedbacker::ChatUtility
  
  before_action :authenticate_user!
  before_action :authenticate_admin!, only: :destroy

  def self.controller_path
    "community/chat"
  end



end
end