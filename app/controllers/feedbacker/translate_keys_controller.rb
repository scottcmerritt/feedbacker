module Feedbacker
  class TranslateKeysController < ApplicationController
    # /translations
    before_action :set_start_time
    before_action :authenticate_admin!
    before_action :set_translate_key, only: %i[ show edit update destroy ]
    before_action :set_shared, only: %i[ index search email delayed needed ]
    before_action :set_translate_keys, only: %i[ index ]
    protect_from_forgery except: :delayed


    # GET /translate_keys or /translate_keys.json
    def index
      cache_all! if params[:refresh_cache]
      Translate.reset_miss_log! if params[:reset_log]
    end


    # moved needed translations to a new page to speed up page load
    def needed

    end

    def delayed
      do_refresh = true # params[:refresh]
      respond_to do |format|
        format.html {  }
        format.js do 
          html = ""
          cache_duration = 60*10
          side_menu_key = "TRANSLATE_KEY::needed_html:#{@tdomain}"
          side_menu = Feedbacker::Cache.get_obj side_menu_key

          cache_used = true
          if side_menu.blank? || do_refresh
            cache_used = false
            side_menu = render_to_string(:partial=>"feedbacker/translate_keys/parts/needed",:locals=>{tdomain:@tdomain},:layout=>false)
          end  

          sub_menu_key = "TRANSLATE_KEY::tdomain_filters_html:#{@tdomain}"
          sub_menu = Feedbacker::Cache.get_obj sub_menu_key
          sub_menu = render_to_string(:partial=>"feedbacker/translate_keys/parts/tdomain_filters",:locals=>{tdomain:@tdomain},:layout=>false) if sub_menu.blank? || params[:refresh]

          Feedbacker::Cache.set_obj side_menu_key,side_menu,nil,cache_duration
          Feedbacker::Cache.set_obj sub_menu_key,sub_menu,nil,cache_duration

          render json: {html: html, cache_used:cache_used, parts: {side_menu:side_menu,sub_menu:sub_menu}}

        end
        #format.json { head :no_content }
      end

    end    


    # GET /translate_keys/1 or /translate_keys/1.json
    def show
    end

    # GET /translate_keys/new
    def new
      @translate_key = TranslateKey.new
    end

    # GET /translate_keys/1/edit
    def edit
    end

    # POST /translate_keys or /translate_keys.json
    def create
      @translate_key = TranslateKey.new(translate_key_params.merge({createdby:current_user.id}))

      respond_to do |format|
        if @translate_key.save
          format.html { redirect_to @translate_key, notice: "Translate key was successfully created." }
          format.json { render :show, status: :created, location: @translate_key }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @translate_key.errors, status: :unprocessable_entity }
        end
      end


    end

    # PATCH/PUT /translate_keys/1 or /translate_keys/1.json
    def update
      respond_to do |format|
        if @translate_key.update(translate_key_params)
          format.html { redirect_to @translate_key, notice: "Translate key was successfully updated." }
          format.json { render :show, status: :ok, location: @translate_key }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @translate_key.errors, status: :unprocessable_entity }
        end
      end


    end

    # DELETE /translate_keys/1 or /translate_keys/1.json
    def destroy
      @translate_key.destroy
      respond_to do |format|
        format.html { redirect_to translate_keys_url, notice: "Translate key was successfully destroyed." }
        format.json { head :no_content }
      end
    end

      # search both the keys AND the translations
    def search
      @q = params[:q] || params[:tdomain]
      if @q.blank?

        redirect_to controller: "translate_keys", action: "index"
      else
        @query1 = "#{@q.downcase}%"
        @query2 = "%#{@q.downcase}%"
        @translates = Translate.where("LOWER(phrase) LIKE ? OR LOWER(phrase) LIKE ?",@query1,@query2).page(params[:page])
        @translate_keys = TranslateKey.where("LOWER(tdomain) LIKE ? OR LOWER(tkey) LIKE ? OR LOWER(tdomain) LIKE ? OR LOWER(tkey) LIKE ?",@query1,@query1,@query2,@query2).page(params[:page])
        

        if params[:q]
          needed = params[:q] ? Feedbacker::Translate.get_cache_misses(grouped:true,tdomain_filter:params[:q],tkey_filter:params[:q]) : Feedbacker::Translate.get_cache_misses(grouped:true)
        else
          needed = Feedbacker::Translate.get_cache_misses(grouped:true,tdomain_filter:params[:tdomain],tkey_filter:params[:q])
        end

        @needed_translations = Translate.get_cache_misses(grouped:true,tdomain_filter:@q,tkey_filter:@q)
        render "index"
      end      
    end


    private
      def set_start_time
        @timer_action = Time.now
      end

      # Use callbacks to share common setup or constraints between actions.
      def set_translate_key
        @translate_key = TranslateKey.find(params[:id])
      end

      def set_translate_keys
        @translate_keys = TranslateKey.order("tdomain,tkey").page(params[:page]).per(30)
        @translate_keys = @translate_keys.where(tdomain:@tdomain) if @tdomain   
      end

       def set_shared
        @lang_colors = {"en"=> "primary","sw"=> "secondary","es"=>"success","other"=> "dark"}
        @tdomain = params[:tdomain]
        @translators = User.select("users.*,count(translates.id) as translates_count").joins("JOIN translates ON translates.user_id = users.id").group("users.id").order("translates_count DESC")
      end
      


      # Only allow a list of trusted parameters through.
      def translate_key_params
        params.require(:translate_key).permit(:tdomain, :tkey, :createdby, :is_public, :is_global, :approved, :approved_at, :approved_by, :removed, :removed_by, :removed_at)
      end

      def cache_all!
      TranslateKey.all.each do |tk|
        tk.translates.each do |row|
          row.cache!
        end
      end
    end
  end
end
