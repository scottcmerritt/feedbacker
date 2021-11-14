module Feedbacker
  # tools for editing emails
  class EmailsController < TranslateKeysController
    before_action :email_descriptions, only: [:index]

    def index
      build_email_keys!
      set_translate_keys
    end

    def show

      @feature_title = "Customize email"
      @filter_locals = {title:@feature_title || "Translations",show_add:false,show_sub_menu:false}

    end

    private

    def build_email_keys!

      # this makes sure keys exist for english 
      @email_keys.keys.each do |email_key|
        @email_parts.each do |email_part|
          full_email_key =  email_key.to_s+email_part #@tdomain+email_key
          TranslateKey.create(tdomain:@tdomain,tkey:full_email_key) unless TranslateKey.exists?(tdomain:@tdomain,tkey:full_email_key)
        end
      end

    end

    
    # Feedbacker::Translate.dbt('email::content.user.recommend_book::body') %>
    def email_descriptions
      @tdomain = "email::content"
      @email_keys = {
        "user.recommend_book", "Send a book recommendation to someone",
        "user.inactive_reminder": "Sent to remind someone to use the site",
        "user.confirmation_instructions": "Sent after someone signs up",
        "user.email_changed": "Sent when an email is changed",
        "user.password_change": "Sent when a password is changed",
        "user.reset_password_instructions": "Sent when someone requets a reset of their password",
        "user.unlock_instructions": "Sent when anaccount is locked"
      }

      @email_keys = @email_keys.with_indifferent_access
      
      @email_parts = ["::subject","::body"]

    end

  end
end