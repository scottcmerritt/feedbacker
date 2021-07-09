module Feedbacker
  class ApplicationController < ::ApplicationController # ActionController::Base # 
    before_action :set_engine_name!
    #helper Feedbacker::Engine.helpers
    helper_method :feedbacker? 
    def feedbacker?
      true
    end

    def set_engine_name!
      @engine_name = "feedbacker"
    end

  end
end
