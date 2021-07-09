module Feedbacker
  class TranslateKeysController < ApplicationController
    before_action :set_translate_key, only: %i[ show edit update destroy ]

    # GET /translate_keys or /translate_keys.json
    def index
      @lang_colors = {"en"=> "primary","sw"=> "secondary","other"=> "dark"}
      cache_all! if params[:refresh_cache]

      Translate.reset_miss_log! if params[:reset_log]

      @translate_keys = TranslateKey.order("tdomain,tkey")
      if params[:tdomain]
        @translate_keys = @translate_keys.where(tdomain:params[:tdomain])
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

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_translate_key
        @translate_key = TranslateKey.find(params[:id])
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
