module Feedbacker
	class Translate < ActiveRecord::Base
		#acts_as_taggable_on :tags	
		self.table_name = "translates"
		include TranslationUtil

		has_paper_trail on: [:update,:destroy], versions: {
			scope: -> { order("created_at desc") }
		  }
	

		belongs_to :user, optional: true
		belongs_to :translate_key
		after_save :cache!
		before_destroy :clear_cache! 

		scope :active, -> { where(active:true) }
		scope :inactive, -> { where(active:false) }

		def sample_page
			self.translate_key.sample_page unless self.translate_key.nil?
		end

		def use_cms?
			!self.tdomain.nil? && self.tdomain.include?('::content')
		end

		def related
			self.translate_key.translates.where.not(translates: {id:self.id})
			.joins("LEFT JOIN translate_keys ON translate_keys.id = translates.translate_key_id").order('translates.created_at DESC')
		end

		# TODO: speed this up AND add other tool for determining the BEST, but for now this should indicate if the phrase is being used
		def best?
			return nil if translate_key.nil?
			top_translation = Translate.top_translation(tdomain:translate_key.tdomain, tkey:translate_key.tkey, locale:self.lang)
			!top_translation.nil? && (self.id == top_translation.id)
		end

		def self.lookup text, locale:, use_cache: true, page:nil, logger:nil, controller:nil,action:nil
			tdomain = text.split(".",2).first if text.split(".",2).length > 1
			tkey = text.split(".",2).last
			logger.debug "lookup: #{text}" unless logger.nil?
			if use_cache
	  
			  res = self.from_cache tdomain,tkey,locale
			  logger.debug "lookup w cache: #{res}" unless logger.nil?
			  if res.nil?
				self.cache_miss! phrase: text, page: page #, controller:controller,action:action
				Feedbacker::Cache.add_list_object self.cache_miss_log_key, self.object_to_cache(tdomain:tdomain,tkey:tkey,lang:locale)
			  else
				self.cache_hit! phrase: text, page: page, controller:controller,action:action
			  end
			  res
			else
			  row = self.top_translation tdomain: tdomain, tkey: tkey, locale: locale
			  row.nil? || !row.has_attribute?(:phrase) ? nil : row.phrase
			end
		  end
=begin

		def self.lookup text, locale:, use_cache: true
			tdomain = text.split(".",2).first if text.split(".",2).length > 1
			tkey = text.split(".",2).last
			if use_cache
				res = Translate.from_cache tdomain,tkey,locale
				if res.nil?
					Translate.cache_miss!(phrase: text)
					Feedbacker::Cache.add_list_object Translate.cache_miss_log_key, Translate.object_to_cache(tdomain:tdomain,tkey:tkey,lang:locale)
				else
					Translate.cache_hit!(phrase: text)
				end
				res
			else
				row = tdomain.blank? ? Translate.joins(:translate_key).where("(translate_keys.tdomain is null or translate_keys.tdomain = '') AND translate_keys.tkey = ?", tkey).where(lang:locale).first : Translate.joins(:translate_key).where(translate_keys: {tdomain:tdomain,tkey:tkey},lang:locale).first
				row.nil? || !row.has_attribute?(:phrase) ? nil : row.phrase
			end
		end


		def self.object_to_cache tdomain:, tkey:, lang:
			#{"tdomain"=>tdomain,"tkey"=>tkey,"lang"=>lang}
			Translation.new(tdomain:tdomain,tkey:tkey,lang:lang)
		end
		def object_to_cache
			Translate.object_to_cache(tdomain:tdomain,tkey:tkey,lang:self.lang)
		end

		def self.object_hashkey tdomain:, tkey:, lang:
			Translate.object_to_cache(tdomain:tdomain,tkey:tkey,lang:lang).hashed
		end
		def object_hashkey
			object_to_cache.hashed
		end

		def self.reset_miss_log!
			Feedbacker::CacheBase.destroy_list! Translate.cache_miss_log_key
		end
		def self.remove_cache_miss_key! misskey
		# params[:remove_misskey] if params[:remove_misskey]
			Feedbacker::CacheBase.destroy_list_object! Translate.cache_miss_log_key, misskey
		end
		
		def self.get_cache_misses grouped:false
			data = Feedbacker::CacheBase.get_list_objects Translate.cache_miss_log_key, load_objects: true, with_keys: true

			if grouped
				idx = {}
				data.each do |full_row|
					row = full_row[:obj]

					idx[row.lang] = [] if idx[row.lang].nil? #['lang']].nil?
					idx[row.lang].push full_row
				end
				data = idx
			end
			data
		end

		def self.get_cache_miss_keys
			Feedbacker::Cache.get_list_items Translate.cache_miss_log_key
		end

		def self.cache_miss_log_key
			"translate::cache_miss_log"
		end

		def self.build_cache_key tdomain, tkey, lang
			"translate::#{lang}::#{tdomain}::#{tkey}"
		end

		def self.from_cache tdomain,tkey,locale
			Feedbacker::Cache.get_obj Translate.build_cache_key tdomain,tkey,locale
		end		

		def build_translate_key! tdomain:, tkey:, createdby: nil
			params = {tdomain:tdomain,tkey:tkey}
			tk = Feedbacker::TranslateKey.exists?(params) ? Feedbacker::TranslateKey.find_by(params) : Feedbacker::TranslateKey.create(params.merge({createdby:createdby}))
			self.translate_key_id = tk.id
		end
=end		


		def tdomain
			translate_key.tdomain unless translate_key.nil?
		end

		def tkey
			translate_key.tkey unless translate_key.nil?
		end

		def has_translate_key?
			!translate_key.nil?
		end
=begin
		def cache! cache_duration: nil, logger: nil
			feedback = []
			if has_translate_key?
				Feedbacker::Cache.set_obj(cache_key,self.phrase,logger,cache_duration)

				# remove from missed cache log
				Translate.remove_cache_miss_key! object_hashkey
				feedback.push "Removed: #{object_hashkey}"
				feedback.push object_to_cache

				#target_obj = Translate.object_to_cache(tdomain:tdomain,tkey:tkey,lang:self.lang)
				#removed_hashkey = Feedbacker::Cache.remove_list_object Translate.cache_miss_log_key, target_obj
				#feedback.push "object removed from miss log: #{removed_hashkey}"
				#feedback.push target_obj
			end
			feedback
		end

		def clear_cache!
			# removes the cached translation
			Feedbacker::Cache.remove_key cache_key
		end

		def cache_key
			Translate.build_cache_key tdomain,tkey,lang 
		end
=end		

	def self.cache_hit! phrase: nil, page: nil, controller:nil,action:nil
		Feedbacker::Cache.increment! Translate.hits_key
		Translate.phrase_hit! phrase unless phrase.nil?
		Feedbacker::Translate.log_page! phrase, page: page unless page.nil?
		Feedbacker::Translate.log_controller_and_action! phrase, controller:controller,action:action unless controller.nil? || action.nil?
		Feedbacker::Translate.log_phrase_lookup_datetime! phrase
		Rails.logger.debug "CONTROLLER: #{controller}, ACTION: #{action}, hit"
	end

	def self.cache_miss! phrase: nil, page: nil, controller:nil,action:nil
		Feedbacker::Cache.increment! Translate.misses_key
		Translate.phrase_miss! phrase unless phrase.nil?
		Feedbacker::Translate.log_page! phrase, page: page unless page.nil?
		Feedbacker::Translate.log_controller_and_action! phrase, controller:controller,action:action unless controller.nil? || action.nil?
		Feedbacker::Translate.log_phrase_lookup_datetime! phrase
		Rails.logger.debug "CONTROLLER: #{controller}, ACTION: #{action}, miss"
	end
	
	

=begin
		def self.cache_hit! phrase: nil
			Translate.phrase_hit!(phrase) unless phrase.nil?
			Feedbacker::Cache.increment! Translate.hits_key			
		end

		def self.cache_miss! phrase: nil
			Translate.phrase_miss!(phrase) unless phrase.nil?
			Feedbacker::Cache.increment! Translate.misses_key
		end
=end

		def self.redis_timestamp
			Time.now.to_s
		end
		def self.log_phrase_lookup_datetime! phrase, cache_expiration = 60000
			Feedbacker::Cache.set_obj self.phrase_lookedup_prefix+"::"+phrase, self.redis_timestamp, nil, cache_expiration
		end
		def self.get_phrase_lookup_datetime phrase
			Feedbacker::Cache.get_obj self.phrase_lookedup_prefix+"::"+phrase
		end

		# experimentally logging phrase misses (and hits)
		def self.phrase_miss! phrase
			Feedbacker::Cache.increment! self.phrase_miss_prefix+"::"+phrase
		end

		def self.phrase_hit! phrase
			Feedbacker::Cache.increment! self.phrase_hit_prefix+"::"+phrase
		end
		def self.phrase_misses phrase
			Feedbacker::Cache.integer_value(self.phrase_miss_prefix+"::"+phrase)
		end
		def self.phrase_hits phrase
			Feedbacker::Cache.integer_value(self.phrase_hit_prefix+"::"+phrase)
		end

		def self.cache_success
			hits = Translate.cache_hits
			misses =  Translate.cache_misses
			hits.to_f / (hits + misses) * 100
		end


	end
end