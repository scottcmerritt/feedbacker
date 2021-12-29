module Feedbacker
module TranslatesHelper
	include Rails.application.routes.url_helpers
	def engine_prefix
		@engine_name + "/" unless @engine_name.blank? 
	end

	def admin_engine_prefix
		@admin_engine_name.blank? ? "feedbacker/" : @admin_engine_name + "/"
	end

	# database translation
	#TODO: cache results, do automatic translations, etc...
	# TODO: build list of unfulfilled/auto-translated domain.keys (saved by pages loading)
	def Olddbt text, d:nil, default:nil, admin: false, locale: I18n.locale.to_s
		d = d || default
		phrase = Translate.lookup text, locale:I18n.locale.to_s
		
		tdomain = text.split(".",2).first if text.split(".",2).length > 1
		tkey = text.split(".",2).last
		#return Translate.object_hashkey(tdomain:tdomain,tkey:tkey,lang:I18n.locale.to_s) #{tdomain} #{tkey}"

		phrase.nil? ? st(text,d:d) : phrase
	end

	def dbt text, d:nil, default:nil, admin: false, locale: I18n.locale.to_s
		logger.debug "DBT: #{text}, #{request.fullpath}"
		cn = controller_name
		an = action_name
		Translate.dbt(text,d:d,default:default,admin:admin,locale:locale,page:request.fullpath,logger:logger,controller:cn,action:an)
	end


	def dbt_tag text, d:nil, default:nil, admin: false, locale: I18n.locale.to_s
		#d = d || default || text
		#dbt("info::tag.#{text}",d:d,default:default,admin:admin).capitalize
		Translate.dbt_tag text, d:d, default:default, admin:admin, locale: locale
	end

	def dbt_cms text, d:nil, default:nil, admin: false
		d = d || default
		tdomain = text.split(".",2).first if text.split(".",2).length > 1
		tkey = text.split(".",2).last

		content = dbt(text,d:d)
		if admin
			admin_edit = tag.div link_to(icon(icon:"edit"), flexi_cms_router(tdomain,tkey),class:"cmsAdminEdit")
			tag.div(safe_join([admin_edit,raw(content)]), class: "cmsAdmin")
		else
			content
		end
	end

	def flexi_cms_router tdomain, tkey
		begin
			main_app.translates_cms_path(tdomain:tdomain,tkey:tkey)
		rescue
			feedbacker.translates_cms_path(tdomain:tdomain,tkey:tkey)
		end
		#respond_to?(:translates_cms_path) ? "/" : feedbacker.translates_cms_path(tdomain:tdomain,tkey:tkey)
	end

	def dbt_debug text
		tdomain = text.split(".",2).first if text.split(".",2).length > 1
		tkey = text.split(".",2).last

		Translate.object_to_cache(tdomain:tdomain,tkey:tkey,lang:I18n.locale.to_s).to_s + " " + Translate.object_hashkey(tdomain:tdomain,tkey:tkey,lang:I18n.locale)
	end

	# safe translation
	def st text, d:nil, default: nil
		t(text, default: d || default || text)
	end

	def translated_site_name default: "My site"
		@app_site.nil? ? dbt('site_title', default: default) : dbt("site:#{@app_site.id}-site_title", default:@app_site.blank? ? default : @app_site.name)
	end
end
end