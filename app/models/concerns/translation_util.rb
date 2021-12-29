module TranslationUtil
  extend ActiveSupport::Concern
  include ActionView::Helpers
  # ApplicationController.helpers.my_helper_method
  # ActionController::Base.helpers.sanitize(str) [for Rails 3??]

  # this is a method thats called when you include the module in a class.
  def self.included(base)
    base.extend ClassMethods
  end

  def object_to_cache
    Feedbacker::Translate.object_to_cache(tdomain:tdomain,tkey:tkey,lang:self.lang)
  end

  def object_hashkey
    object_to_cache.hashed
  end

  def build_translate_key! tdomain:, tkey:, createdby: nil
    params = {tdomain:tdomain,tkey:tkey}
    tk = Feedbacker::TranslateKey.exists?(params) ? Feedbacker::TranslateKey.find_by(params) : Feedbacker::TranslateKey.create(params.merge({createdby:createdby}))
    self.translate_key_id = tk.id if self.respond_to?(:translate_key_id) && !tk.nil?
  end

  def cache! cache_duration: nil, logger: nil
    feedback = []
    if has_translate_key?
      Feedbacker::Cache.set_obj(cache_key,self.phrase,logger,cache_duration)

      # remove from missed cache log
      Feedbacker::Translate.remove_cache_miss_key! object_hashkey
      feedback.push "Removed: #{object_hashkey}"
      feedback.push object_to_cache

      tmp_cache_clear = self.translate_key.missed_keys_count(refresh:true)

      #target_obj = Translate.object_to_cache(tdomain:tdomain,tkey:tkey,lang:self.lang)
      #removed_hashkey = Cache.remove_list_object Translate.cache_miss_log_key, target_obj
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
    Feedbacker::Translate.build_cache_key tdomain,tkey,lang 
  end

 

  # for including static methods
  module ClassMethods


    def phrases_by_controller_and_action_cache_key controller:, action:
      page_key = "#{controller}.#{action}"
      set_cache_key = "TRANSLATIONS_by_CONTROLLER_ACTION::#{page_key}"
    end

    def phrases_by_controller_and_action controller:, action:
      list_cache_key = self.phrases_by_controller_and_action_cache_key controller:controller,action:action
      Feedbacker::Cache.get_list_objects(list_cache_key,load_objects:true,with_keys:true)
    end

    # page_keys in a LIST/SET, so we can reverse lookup
    def log_controller_and_action! phrase, cache_duration: 60*60*24*5, logger:nil, overwrite:false, controller: nil, action: nil
#      cache_key = "PAGE::CONTROLLER::ACTION" + self.phrase_miss_prefix+"::"+phrase

      # by page_key (i.e. controller::action)
      #add_page_key = overwrite || !Feedbacker::CacheBase.exists?(cache_key)
      list_cache_key = self.phrases_by_controller_and_action_cache_key controller:controller,action:action
      #Feedbacker::Cache.set_obj(cache_key,page_key,logger,cache_duration) if add_page_key

      Feedbacker::Cache.add_list_object list_cache_key, phrase, cache_expiration: cache_duration # if add_page_key
    end

    # TODO: add pages to a LIST/SET
    def log_page! phrase, page:, cache_duration: 60*60*24*5, logger:nil, overwrite:false
      cache_key = "PAGE::" + self.phrase_miss_prefix+"::"+phrase
      # by url
      add_page = overwrite || !Feedbacker::CacheBase.exists?(cache_key)

      Feedbacker::Cache.set_obj(cache_key,page,logger,cache_duration) if add_page
    end

    def log_default! phrase, default:, cache_duration: 60*60*24*5, logger:nil
      cache_key = "TRANSLATE::DEFAULT::" + self.phrase_miss_prefix+"::"+phrase
      Feedbacker::Cache.set_obj(cache_key,default,logger,cache_duration)
    end

    def log_result! phrase, result:, cache_duration: 60*60*24*5, logger:nil
      cache_key = "TRANSLATE::RESULT::" + self.phrase_miss_prefix+"::"+phrase
      Feedbacker::Cache.set_obj(cache_key,result,logger,cache_duration)
    end

    # gets a sample page for WHERE the translation appears. NOTE: translations could appear on MANY pages and only have 1 sample
    def get_logged_samples phrase
      {page: self.get_logged_page(phrase),default:self.get_logged_default(phrase),result:self.get_logged_result(phrase)}
    end

    # WARNING, could be a slow method
    def get_all_logged_pages page_query: nil
      pages = {}
      Feedbacker::TranslateKey.all.each do |translate_key|
        page = translate_key.logged_samples[:page]
        unless page.blank?
          samples = translate_key.logged_samples
          pages[page.downcase] = {} if pages[page.downcase].nil?
          pages[page.downcase][translate_key.full_key] = samples
        end
      end
      pages

      needed = Feedbacker::Translate.get_cache_misses(grouped:true)
      needed.each do |lang,rows|
        rows.each do |full_row|
          row = full_row.kind_of?(Feedbacker::Translation) ? full_row : (full_row.has_key?(:obj) ? full_row[:obj] : full_row)
          row_translate_full_key = "#{row.tdomain}.#{row.tkey}"
          samples = Feedbacker::Translate.get_logged_samples row_translate_full_key
          page = samples[:page]
          unless samples[:page].nil?
            pages[page.downcase] = {} if pages[page.downcase].nil?
            pages[page.downcase][row_translate_full_key] = samples
          end
        end
      end
      pages = pages.sort_by{|k,v| -k}

#      regex_txt = "/^#{page_query}\d+/" # /^page_query\d+/
      #page_query.blank? ? pages : pages.select{ |key, value| key.to_s.match(regex_txt) }
      page_query.blank? ? pages : pages.select{ |key, value| key.include?(page_query) }
    end

    def get_logged_page phrase, remove_params: [:locale]
      cache_key = "PAGE::" + self.phrase_miss_prefix+"::"+phrase
      page = Feedbacker::Cache.get_obj cache_key
      remove_params.nil? ? page : page
    end
    def get_logged_default phrase
      cache_key = "TRANSLATE::DEFAULT::" + self.phrase_miss_prefix+"::"+phrase
      Feedbacker::Cache.get_obj cache_key
    end
    def get_logged_result phrase
      cache_key = "TRANSLATE::RESULT::" + self.phrase_miss_prefix+"::"+phrase
      Feedbacker::Cache.get_obj cache_key
    end

     def phrase_lookedup_prefix
      "cachelookup::phrase::translate"
    end

    def cache_hits
      Feedbacker::Cache.integer_value(Feedbacker::Translate.hits_key)
    end
    def cache_misses
      Feedbacker::Cache.integer_value(Feedbacker::Translate.misses_key)
    end

    def hits_key
      "cachehit::translate"
    end
    def misses_key
      "cachemiss::translate"
    end

    def phrase_miss_prefix
      "cachemiss::phrase::translate"
    end
    def phrase_hit_prefix
      "cachemiss::hit::translate"
    end

    def hits_and_misses row
      phrase_key = "#{row.tdomain}.#{row.tkey}"
      {updated_at:Feedbacker::Translate.get_phrase_lookup_datetime(phrase_key),hits: Feedbacker::Translate.phrase_hits(phrase_key), misses: Feedbacker::Translate.phrase_misses(phrase_key)}
    end


     # database translation
    #TODO: cache results, do automatic translations, etc...
    # TODO: build list of unfulfilled/auto-translated domain.keys (saved by pages loading)
    # log_default: if FALSE, do NOT log the default
    def dbt text, d:nil, default:nil, admin: false, locale: I18n.locale.to_s, page:nil, logger:nil,controller:nil,action:nil, log_default:true
      d = d || default
      phrase = Feedbacker::Translate.lookup text, locale: locale, page: page, logger:logger, controller:controller,action:action # I18n.locale.to_s
      
      # similar to text.partition(".").first, etc...
      tdomain = text.split(".",2).first if text.split(".",2).length > 1
      tkey = text.split(".",2).last
      #return Translate.object_hashkey(tdomain:tdomain,tkey:tkey,lang:I18n.locale.to_s) #{tdomain} #{tkey}"

      if phrase.nil?

        Feedbacker::Translate.log_default!(text, default: d) if log_default
        res = ApplicationController.helpers.st(text,d:d)
        Feedbacker::Translate.log_result!(text, result: res) if res!=d
        
        return res
      else
        return phrase
      end
    end

    def dbt_tag text, d:nil, default:nil, admin: false, locale: I18n.locale.to_s
      d = d || default || text
      text = text.name unless text.kind_of?(String)
      self.dbt("info::tag.#{text}",d:d,default:default,admin:admin,locale: locale).capitalize
    end

    def lookup text, locale:, use_cache: true, page:nil, logger:nil, controller:nil,action:nil
      tdomain = text.split(".",2).first if text.split(".",2).length > 1
      tkey = text.split(".",2).last
      logger.debug "lookup: #{text}" unless logger.nil?
      if use_cache

        res = self.from_cache tdomain,tkey,locale
        logger.debug "lookup w cache: #{res}" unless logger.nil?
        if res.nil?
          self.cache_miss! phrase: text, page: page, controller:controller,action:action
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

    def top_translation tdomain:, tkey:, locale:
      tdomain.blank? ? Feedbacker::Translate.joins(:translate_key).where("(translate_keys.tdomain is null or translate_keys.tdomain = '') AND translate_keys.tkey = ?", tkey).order("translates.updated_at DESC").where(lang:locale).first : Feedbacker::Translate.joins(:translate_key).where(translate_keys: {tdomain:tdomain,tkey:tkey},lang:locale).order("translates.updated_at DESC").first
    end

    def object_to_cache tdomain:, tkey:, lang:
      #{"tdomain"=>tdomain,"tkey"=>tkey,"lang"=>lang}
      Feedbacker::Translation.new(tdomain:tdomain,tkey:tkey,lang:lang)
    end
    def object_hashkey tdomain:, tkey:, lang:
      Feedbacker::Translate.object_to_cache(tdomain:tdomain,tkey:tkey,lang:lang).hashed
    end

    def reset_miss_log!
      Feedbacker::CacheBase.destroy_list! Feedbacker::Translate.cache_miss_log_key
    end

    def remove_cache_miss_key! misskey
    # params[:remove_misskey] if params[:remove_misskey]
     Feedbacker::CacheBase.destroy_list_object! Feedbacker::Translate.cache_miss_log_key, misskey
    end
    
    def get_all_cache_misses with_keys: true
      Feedbacker::CacheBase.get_list_objects Feedbacker::Translate.cache_miss_log_key, load_objects: true, with_keys: with_keys
    end

    # exact_match requires an exact match (a == b) between tdomain and tkey, otherwise it does .include?
    def get_cache_misses grouped:false,sorted:true, tdomain_filter:nil, tkey_filter:nil, exact_match: false
      #data = get_all_cache_misses with_keys: true
      data = Feedbacker::CacheBase.get_list_objects Feedbacker::Translate.cache_miss_log_key, load_objects: true, with_keys: true
      
      if grouped
        idx = {}    
        data.each do |full_row|
          row = full_row[:obj]

          unless row.nil? 
            idx[row.lang] = [] if idx[row.lang].nil? #['lang']].nil?
            if exact_match
              idx[row.lang].push(full_row) if (!row.tdomain.nil? && row.tdomain == tdomain_filter) && (!tkey_filter.nil? && !row.tkey.nil? && row.tkey == tkey_filter)
            else
              if tdomain_filter.nil?
                idx[row.lang].push full_row
              else
                idx[row.lang].push(full_row) if (!row.tdomain.nil? && row.tdomain.include?(tdomain_filter)) || (!tkey_filter.nil? && !row.tkey.nil? && row.tkey.include?(tkey_filter))
              end
            end
          end
        end
        #data = idx

        data = {}
        if sorted
          idx.each do |k,v|
            data[k] = v.sort_by{|row| row[:obj].tdomain.to_s}.reverse # sort_by{|row| row[:obj].tdomain}, # collect{|row| row[:obj]}
          end
        else
          data = idx          
        end
      else
        idx = []
        data.each do |full_row|
          row = full_row[:obj]
          idx.push(full_row) if tdomain_filter.nil? || (!row.tdomain.nil? && row.tdomain.include?(tdomain_filter))
        end
        data = idx
      end
      data
  #     !sorted ? data : data.sort_by{|k,v| v[:obj].tdomain}
    end

    def get_cache_miss_keys
      Feedbacker::Cache.get_list_items Feedbacker::Translate.cache_miss_log_key
    end

    def cache_miss_log_key
      "translate::cache_miss_log"
    end

    def build_cache_key tdomain, tkey, lang
      "translate::#{lang}::#{tdomain}::#{tkey}"
    end

    def from_cache tdomain,tkey,locale
      Feedbacker::Cache.get_obj Feedbacker::Translate.build_cache_key tdomain,tkey,locale
    end





  end

end
