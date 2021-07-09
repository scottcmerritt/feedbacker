module Feedbacker
	class TranslatesController < ApplicationController
		before_action :authenticate_admin! #:authenticate_user!
		before_action :set_translate
		
		def index
			clear_misskeys!
			@translate_domains_grouped = TranslateKey.tdomain_grouped
			@translations = Translate.order('translate_key_id ASC')
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
			Feedbacker::Translate.create(translate_params)
			redirect_to feedbacker.translates_path, notice: "Added" #controller: "translates", action: "index", notice: "Added"
		end

		def show

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