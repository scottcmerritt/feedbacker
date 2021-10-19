module Feedbacker
	class TranslatesController < ApplicationController
		before_action :authenticate_admin! #:authenticate_user!
		before_action :set_translate
		
		def index
			clear_misskeys!
	#		@translations = Translate.order('translate_key_id ASC').page(params[:page])
			@translations = Translate.select("translates.*").joins("LEFT JOIN translate_keys ON translate_keys.id = translates.translate_key_id").order('translates.created_at DESC')
			
			@tdomain = params[:tdomain]
			@translations = @translations.where("translate_keys.tdomain = ?",@tdomain) if @tdomain
			@translations = @translations.page(params[:page])

			@translators = User.select("users.*,count(translates.id) as translates_count").joins("JOIN translates ON translates.user_id = users.id").group("users.id").order("translates_count DESC")
			
			@needed_translations = Translate.get_cache_misses(grouped:true,tdomain_filter:@tdomain)
		end

		def new
			
			@translate = Feedbacker::Translate.new(translate_key_id:params[:key_id],lang:params[:lang])
			if params[:key_id].blank?
				@translate.build_translate_key! tdomain: params[:tdomain], tkey: params[:tkey], createdby: current_user.id
			end			
			unless @translate.has_translate_key?
				redirect_to controller: "translate_keys", action: "index"
			end
		end
		def edit
			
			flash[:alert] = Digest::SHA256.hexdigest Marshal.dump(Translate.object_to_cache(tdomain:nil,tkey:"ago",lang:"en"))
			flash[:notice] = @translate.cache! if params[:cache]
		end
		def create
			translate = Feedbacker::Translate.create(translate_params.merge({user_id:current_user.id}))
			redirect_to feedbacker.translates_path(tdomain: translate.translate_key.tdomain), notice: "Added, search for similar?", tdomain: translate.translate_key.tdomain

			#redirect_to feedbacker.translates_path, notice: "Added" #controller: "translates", action: "index", notice: "Added"
		end

		def show

		end

		# GET ALL of the keys, and then show those with the most misses
		# AND show the most hits (without OTHER languages)
		def todo
			@results = []
			Feedbacker::TranslateKey.select("*").limit(500).each do |translate_key|
				@results.push({id:translate_key.id,obj:translate_key,fullkey:translate_key.full_key,hits:Feedbacker::Translate.phrase_hits(translate_key.full_key),misses:Feedbacker::Translate.phrase_misses(translate_key.full_key)})
			end
		end

		# translates_cms_path
		# admin/cms?tdomain=page::content&tkey=about_p1
		def cms
			@tdomain = params[:tdomain]
			@tkey = params[:tkey]

			@translate_key = Feedbacker::TranslateKey.new(tdomain:@tdomain,tkey:@tkey)

			@translations = Feedbacker::Translate.select("translates.*").joins("LEFT JOIN translate_keys ON translate_keys.id = translates.translate_key_id").order('translates.created_at DESC')
			@translations = @translations.where("translate_keys.tdomain = ? AND translate_keys.tkey = ?",@tdomain,@tkey)
			@translations = @translations.page(params[:page])

			@tkeys = @tkey.split("_")

			@similar = []
			@tkeys.each do |tkey|
				@similar = @similar + Feedbacker::TranslateKey.where("tkey LIKE ?","%#{tkey}%").to_a
			end

		end

		def destroy
			@translate.destroy
			redirect_to action: "index"
		end

		def update
			@translate.update(translate_params)
			flash[:notice] = @translate.cache!
			redirect_to action:"index" #@translate
		end

		private
		def set_translate
			@translate = Feedbacker::Translate.find_by(id:params[:id])
		end
		def translate_params
	      params.require(:translate).permit(:lang, :phrase,:translate_key_id)
	    end

	    def clear_misskeys!
	    	if params[:remove_misskey]
		    	Feedbacker::Translate.remove_cache_miss_key! params[:remove_misskey]
		    	redirect_to controller: "translates", action: "index", notice: "Miss key removed"
		    end
	    end
	end
end