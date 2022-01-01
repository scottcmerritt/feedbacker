module Feedbacker
  # tools for editing emails
  class MenusController < TranslateKeysController


    def index
      @tdomain = "menu::content"
      set_translate_keys
    end

    def show
      @feature_title = "Customize menus"
      @filter_locals = {title:@feature_title || "Translations",show_add:false,show_sub_menu:false}
    end

    private


    

  end
end