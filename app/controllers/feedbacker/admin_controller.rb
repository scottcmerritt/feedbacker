module Feedbacker
	class AdminController < ApplicationController
		include Feedbacker::FeedbackerAdminController

		def index
			#@engine_name = "feedbacker"
			#render json: {:test=>"Hey admin of Feedbacker"}
		end
	end
end