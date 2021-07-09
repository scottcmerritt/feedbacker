module Feedbacker
	class DemoController < ::ApplicationController
		def index
			render json: {:test=>"Hey world"}
		end
	end
end