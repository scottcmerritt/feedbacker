module Feedbacker
	class Ui
		attr_accessor :filter
		def initialize params:
			@filter = {within: {days: params[:within] || 0.5 }}
			@filter[:within][:mins] = @filter[:within][:days].to_f * 24 * 60

		end

	end
end