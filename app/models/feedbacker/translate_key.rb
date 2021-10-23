module Feedbacker
	class TranslateKey < ApplicationRecord
		self.table_name = "translate_keys"
		has_many :translates
		scope :tdomain_grouped, -> { select('tdomain').where.not(tdomain:nil).group("tdomain")}

		def languages
			translates.distinct(:lang)
#			translates.select('DISTINCT(lang)') #group("lang")
		end
		
		def langs_used
			languages.pluck(:lang)
		end

		def creator
			User.find_by(id:self.createdby)
		end

#		def self.lookup
#			TranslateKey.where()
#		end
		def full_key
			(self.tdomain.nil? ? "" : self.tdomain) +"." + (self.tkey.nil? ? "" : +self.tkey)
		end
		
		
	end
end