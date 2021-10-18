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
    Translate.object_to_cache(tdomain:tdomain,tkey:tkey,lang:self.lang)
  end

  def object_hashkey
    object_to_cache.hashed
  end

  def build_translate_key! tdomain:, tkey:, createdby: nil
    params = {tdomain:tdomain,tkey:tkey}
    tk = TranslateKey.exists?(params) ? TranslateKey.find_by(params) : TranslateKey.create(params.merge({createdby:createdby}))
    self.translate_key_id = tk.id
  end

  def cache! cache_duration: nil, logger: nil
    feedback = []
    if has_translate_key?
      Feedbacker::Cache.set_obj(cache_key,self.phrase,logger,cache_duration)

      # remove from missed cache log
      Feedbacker::Translate.remove_cache_miss_key! object_hashkey
      feedback.push "Removed: #{object_hashkey}"
      feedback.push object_to_cache

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

    # TODO: add pages to a LIST/SET
    def log_page! phrase, page:, cache_duration: 60*60*24*5, logger:nil, overwrite:false
      cache_key = "PAGE::" + self.phrase_miss_prefix+"::"+phrase
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

    def get_logged_samples phrase
      {page: self.get_logged_page(phrase),default:self.get_logged_default(phrase),result:self.get_logged_result(phrase)}
    end

    def get_logged_page phrase
      cache_key = "PAGE::" + self.phrase_miss_prefix+"::"+phrase
      Feedbacker::Cache.get_obj cache_key
    end
    def get_logged_default phrase
      cache_key = "TRANSLATE::DEFAULT::" + self.phrase_miss_prefix+"::"+phrase
      Feedbacker::Cache.get_obj cache_key
    end
    def get_logged_result phrase
      cache_key = "TRANSLATE::RESULT::" + self.phrase_miss_prefix+"::"+phrase
      Feedbacker::Cache.get_obj cache_key
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
      {hits: Feedbacker::Translate.phrase_hits(phrase_key), misses: Feedbacker::Translate.phrase_misses(phrase_key)}
    end


     # database translation
    #TODO: cache results, do automatic translations, etc...
    # TODO: build list of unfulfilled/auto-translated domain.keys (saved by pages loading)
    def dbt text, d:nil, default:nil, admin: false, locale: I18n.locale.to_s, page:nil, logger:nil
      d = d || default
      phrase = Feedbacker::Translate.lookup text, locale: locale, page: page, logger:logger # I18n.locale.to_s
      
      tdomain = text.split(".",2).first if text.split(".",2).length > 1
      tkey = text.split(".",2).last
      #return Translate.object_hashkey(tdomain:tdomain,tkey:tkey,lang:I18n.locale.to_s) #{tdomain} #{tkey}"

      if phrase.nil?

        Feedbacker::Translate.log_default! text, default: d
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

    def lookup text, locale:, use_cache: true, page:nil, logger:nil
      tdomain = text.split(".",2).first if text.split(".",2).length > 1
      tkey = text.split(".",2).last
      logger.debug "lookup: #{text}" unless logger.nil?
      if use_cache

        res = self.from_cache tdomain,tkey,locale
        logger.debug "lookup w cache: #{res}" unless logger.nil?
        if res.nil?
          self.cache_miss! phrase: text, page: page
          Feedbacker::Cache.add_list_object self.cache_miss_log_key, self.object_to_cache(tdomain:tdomain,tkey:tkey,lang:locale)
        else
          self.cache_hit! phrase: text, page: page
        end
        res
      else
        row = tdomain.blank? ? Translate.joins(:translate_key).where("(translate_keys.tdomain is null or translate_keys.tdomain = '') AND translate_keys.tkey = ?", tkey).where(lang:locale).first : Translate.joins(:translate_key).where(translate_keys: {tdomain:tdomain,tkey:tkey},lang:locale).first
        row.nil? || !row.has_attribute?(:phrase) ? nil : row.phrase
      end
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
    def get_cache_misses grouped:false,sorted:true, tdomain_filter:nil, tkey_filter:nil
      #data = get_all_cache_misses with_keys: true
      data = Feedbacker::CacheBase.get_list_objects Feedbacker::Translate.cache_miss_log_key, load_objects: true, with_keys: true

      if grouped
        idx = {}
        data.each do |full_row|
          row = full_row[:obj]


          unless row.nil? 
            idx[row.lang] = [] if idx[row.lang].nil? #['lang']].nil?
            if tdomain_filter.nil?
              idx[row.lang].push full_row
            else
              idx[row.lang].push(full_row) if (!row.tdomain.nil? && row.tdomain.include?(tdomain_filter)) || (!tkey_filter.nil? && !row.tkey.nil? && row.tkey.include?(tkey_filter))
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
