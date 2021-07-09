module Feedbacker
	class Translation
		attr_accessor :tdomain,:tkey,:lang
		def initialize tdomain:, tkey:, lang:
			@tdomain, @tkey, @lang = tdomain, tkey, lang.to_sym
		end

		def hashed
			Digest::SHA256.hexdigest Marshal.dump(self)
		end
	end
end