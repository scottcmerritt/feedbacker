module Feedbacker
  	module TranslatesHelper
	    include Rails.application.routes.url_helpers
		def engine_prefix
			@engine_name + "/" unless @engine_name.blank? 

		end

		# database translation
		#TODO: cache results, do automatic translations, etc...
		# TODO: build list of unfulfilled/auto-translated domain.keys (saved by pages loading)
		def dbt text, d:nil, default:nil
			d = d || default
			begin
				phrase = Feedbacker::Translate.lookup text, locale:I18n.locale.to_s
			rescue

			end
			tdomain = text.split(".",2).first if text.split(".",2).length > 1
			tkey = text.split(".",2).last
			#return Translate.object_hashkey(tdomain:tdomain,tkey:tkey,lang:I18n.locale.to_s) \#{tdomain} \#{tkey}"

			phrase.nil? ? st(text,d:d) : phrase
		end

		def dbt_debug text
			tdomain = text.split(".",2).first if text.split(".",2).length > 1
			tkey = text.split(".",2).last

			Feedbacker::Translate.object_to_cache(tdomain:tdomain,tkey:tkey,lang:I18n.locale.to_s).to_s + " " + Feedbacker::Translate.object_hashkey(tdomain:tdomain,tkey:tkey,lang:I18n.locale)
		end

		# safe translation
		def st text, d:nil, default: nil
			t(text, default: d || default || text)
		end

	end
end

