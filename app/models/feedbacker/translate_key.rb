module Feedbacker
	class TranslateKey < ApplicationRecord
		self.table_name = "translate_keys"
		has_many :translates
		scope :tdomain_grouped, -> { select('tdomain,count(tkey) as tkey_count').where.not(tdomain:nil).group("tdomain").order('tkey_count DESC')}


		def self.tdomains_sorted refresh: false, cache_duration: 600
			cache_key = "TRANSLATE_KEY::tdomains_sorted"
			res = Feedbacker::Cache.get_obj cache_key
			if refresh || res.nil?
				res = self.tdomain_grouped.sort_by{|row| -(row.missed_keys.count + row.tkey_count) }
				Feedbacker::Cache.set_obj cache_key,res,nil,cache_duration
			end
			res
		end

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

		def missed_keys
			# tkey_filter: 
			Feedbacker::Translate.get_cache_misses(grouped:false,tdomain_filter:self.tdomain)
		end

		def sample_page
			samples = Translate.get_logged_samples "#{self.tdomain}.#{self.tkey}"
			# samples[:default], samples[:result]
			samples[:page] unless samples[:page].nil?
		end

	end
end