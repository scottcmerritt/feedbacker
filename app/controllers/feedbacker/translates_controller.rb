module Feedbacker
	class TranslatesController < ApplicationController
		before_action :set_start_time
		before_action :authenticate_admin! #:authenticate_user!
		before_action :set_translate
		before_action :set_needed_translations
		
		def index
			clear_misskeys!
	#		@translations = Translate.order('translate_key_id ASC').page(params[:page])
			@translations = Translate.select("translates.*").joins("LEFT JOIN translate_keys ON translate_keys.id = translates.translate_key_id")
			.order('translates.updated_at DESC')
			
			
			@translations = @translations.where("translate_keys.tdomain = ?",@tdomain) if @tdomain
			@translations = @translations.where.not("translates.id = ?",@translate.id) unless @translate.nil?

			@translations = @translations.page(params[:page])

			@translators = User.select("users.*,count(translates.id) as translates_count").joins("JOIN translates ON translates.user_id = users.id").group("users.id").order("translates_count DESC")			
		end

		def approve_default
			@remove_frame = params[:parent_frame]

			@translate = Feedbacker::Translate.new(lang:params[:lang], user_id:current_user.id)
			translate_key_id = @translate.build_translate_key! tdomain: @tdomain, tkey: @tkey, createdby: current_user.id
			samples = Feedbacker::Translate.get_logged_samples "#{@translate.translate_key.tdomain}.#{@translate.translate_key.tkey}"
			unless samples[:default].blank?
				@translate.phrase = samples[:default]
				@translate.save
				@msg = "Translate id: #{@translate.id}, with phrase: #{@translate.phrase}, for lang: #{@translate.lang} was created"
				@msg+=" WITH TK: #{translate_key_id}"
			end
		end

		def suggest
			@frame_id = params[:frame]

			begin
				if defined?(McTranslate)
					translator = McTranslate.new
					@result = translator.results(text: params[:text],lang:params[:lang])["translation"]
				else
					@result = "Not enabled"
				end
			rescue Exception=>ex
				@result = "Error: #{ex}"
			end
		end


		# translates_clear_misskey_path
		def clear_misskey
			# based on the tdomain and tkey, lookup the misskey AND remove it

			@remove_frame = params[:remove_frame]
			if params[:remove_misskey]
				@msg = "Miss key CLEARED!"

				Feedbacker::Translate.remove_cache_miss_key! params[:remove_misskey]
			else
				needed = Feedbacker::Translate.get_cache_misses(grouped:true,tdomain_filter:@tdomain,tkey_filter:@tkey,exact_match:true)
				
				if needed.empty?
					@msg = "No keys found, tdomain: #{@tdomain}, tkey: #{@tkey}"
				else
					miss_keys = []
					needed.each do |lang,rows|
						rows.each do |full_row|
							miss_keys.push full_row[:key] if full_row.has_key?(:key)
						end
					end
					@miss_keys = miss_keys.uniq

					@msg = "Keys found (#{@miss_keys.length}), tdomain: #{@tdomain}, tkey: #{@tkey}, #{@miss_keys}"
					@objs = []
					@miss_keys.each do |k|

						obj = Feedbacker::CacheBase.get_obj k
						@objs.push obj.to_json.to_s
						@msg+=(" " + obj.as_json.to_s)
						Feedbacker::Translate.remove_cache_miss_key! k
					end
				end
			end

		end

		def new
			
			@translate = Feedbacker::Translate.new(translate_key_id:params[:key_id],lang:params[:lang])
			if params[:key_id].blank?
				@translate.build_translate_key! tdomain: params[:tdomain], tkey: params[:tkey], createdby: current_user.id
			end			
			unless @translate.has_translate_key?
				redirect_to controller: "translate_keys", action: "index"
			else
				@translate_key = @translate.translate_key #TranslateKey.find_by(id:params[:key_id])
			end
		end
		def edit
			
			flash[:alert] = Digest::SHA256.hexdigest Marshal.dump(Translate.object_to_cache(tdomain:nil,tkey:"ago",lang:"en"))
			flash[:notice] = @translate.cache! if params[:cache]
		end
		def create
			translate = Feedbacker::Translate.create(translate_params.merge({user_id:current_user.id}))
			flash[:notice] = "Updated, filtering for similar..." #@translate.cache!
			redirect_to feedbacker.translates_path(tdomain: translate.translate_key.tdomain, translate_id: translate.id), tdomain: translate.translate_key.tdomain # notice: "Added, search for similar?", 

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
			@translate_key = Feedbacker::TranslateKey.new(tdomain:@tdomain,tkey:@tkey)

			@translations = Feedbacker::Translate.select("translates.*").joins("LEFT JOIN translate_keys ON translate_keys.id = translates.translate_key_id").order('translates.created_at DESC')
			@translations = @translations.where("translate_keys.tdomain = ? AND translate_keys.tkey = ?",@tdomain,@tkey)
			@translations = @translations.page(params[:page])

			@similar = []
			unless @tkeys.nil?
				@tkeys = @tkey.split("_")
				
				@tkeys.each do |tkey|
					@similar = @similar + Feedbacker::TranslateKey.where("tkey LIKE ?","%#{tkey}%").to_a
				end
			end
		end

		def destroy
			old_tdomain = @translate.translate_key.tdomain.to_s unless @translate.translate_key.nil?
			@translate.destroy
			redirect_to action: "index", tdomain: old_tdomain
		end

		def update
			@translate.update(translate_params)
			flash_msg = "Updated, filtering for similar..." #@translate.cache!
			flash[:notice] = flash_msg
			#redirect_to action:"index" #@translate
			redirect_to feedbacker.translates_path(tdomain: @translate.translate_key.tdomain,translate_id: @translate.id), tdomain: @translate.translate_key.tdomain # notice: "Updated, filtering for similar...",
		end

		private
		
		def set_start_time
	        @timer_action = Time.now
	      end

		def set_translate
			@tdomain = params[:tdomain]
			@tkey = params[:tkey]

			translate_id = params[:translate_id] || params[:id]
			@translate = Feedbacker::Translate.find_by(id:translate_id)
		end

		def set_needed_translations
			filter_q = @tdomain || @q
			@needed_translations = Translate.get_cache_misses(grouped:true,tdomain_filter:filter_q,tkey_filter:filter_q)
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