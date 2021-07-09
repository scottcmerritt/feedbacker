module Feedbacker
  	module TranslatesHelper
	    include Rails.application.routes.url_helpers
		def engine_prefix
			@engine_name + "/" unless @engine_name.blank? 

		end
	end
end
