require 'active_support/concern'

module Feedbacker
  module FeedbackerMainController
    extend ActiveSupport::Concern
    
    included do
        # method to add to controller

        #around_action :switch_locale
        before_action :load_site

        before_action :load_site_menu,:load_site_roles, :load_site_sub_menu

      end
  
  
  private

  def load_site
    require "browser/aliases"
    Browser::Base.include(Browser::Aliases)
    browser = Browser.new(request.headers['User-Agent'])

#   <%= request.host %>: <%= request.domain %>
   
   @app_site = Site.where(domain:request.host).first if defined?(Site)
   # ActiveRecord::StatementInvalid (PG::InsufficientPrivilege: (occurs if heroku blocks the permission)
   begin
     impressionist @app_site unless @app_site.nil? || !defined?(Impression)
   rescue ActiveRecord::StatementInvalid => e

   end
   load_langs
   set_locale
  end

  # main NAV links
  def load_site_menu
    @site_menu = []
    @site_menu_admin = []
    @site_menu.push [dbt('users',default:"People"),main_app.users_path,controller_name == 'users']


=begin
    @site_menu = [
      [dbt('menu.books',d:'Books').capitalize || 'Books',books_path,controller_name == 'books'],
      [dbt('menu.about',d:'About').capitalize || 'About',about_path,controller_name == 'welcome' && action_name == 'about'],
      [dbt('menu.updates',d:'Updates').capitalize,site_updates_path,controller_name == 'admin' && action_name == 'updates',5]
    ]

    if is_admin?
      @site_menu.push([dbt('projects',d:'Projects'),projects_path,controller_name=='projects',Project.count])
      @site_menu.push([dbt('menu.admin',d:'Admin'),admin_path,controller_name=='admin' && action_name!='updates'])
    end
=end

#    @site_menu_admin.push [dbt('feedback',default:"Feedback"),feedbacker.admin_path,controller_name == "admin" && (respond_to?(:feedbacker?) && feedbacker?)]

    @site_menu_admin.push [dbt('admin',default:"Admin"),main_app.admin_path,controller_name == 'admin' && !respond_to?(:feedbacker?)]
  end


  # links BELOW the main nav
  def load_site_sub_menu
    @site_links = []
      tab_key = "siteMenu"

      @site_links.push(Feedbacker::UiTab.new(
        {id:1, key: tab_key,name:"Home",url: main_app.root_path,controller:"home",action:nil,is_parent:true}
        ))
      @site_links.push(Feedbacker::UiTab.new(
        {id:1, key: tab_key,name:"Posts",url: main_app.posts_path,controller:"posts",is_parent:true}
        ))
      @site_links.push(Feedbacker::UiTab.new(
        {id:3, key: tab_key,name:"Users",url: main_app.users_path,controller:"users",is_parent:true}
        ))
      @site_links.push(Feedbacker::UiTab.new(
        {id:4, key: tab_key,name:"Orgs",url: main_app.orgs_path,controller:"orgs",is_parent:true}
        )) if defined?(Community::Org)

  end

  


=begin
  # adds a default parameter to paths within the site 
  def default_url_options
    { locale: I18n.locale }
  end
=end
  
  def switch_locale(&action)
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end



  def read_lang_header
    lang_header = request.env['HTTP_ACCEPT_LANGUAGE']
    lang_header.downcase.scan(/[a-z]{2}\-[a-z]{2}/).first unless lang_header.nil?
  end


  def authenticate_admin!
    authenticate_user!

    if is_first_user? && !is_admin? && no_admins?
      redirect_to first_admin_path
    else
      redirect_to root_path, notice: "Permission denied" unless is_admin?
    end
  end

  def is_first_user?
    current_user.id == 1
  end

  def no_admins?
    User.with_role(:admin).count == 0
  end

  def is_admin?
    user_signed_in? && current_user.respond_to?(:has_role?) && current_user.has_role?(:admin)
  end
  
  def all_locales
    Feedbacker.languages #["en","sw"] # en-us
  end

  def get_all_langs
    Feedbacker.languages #["en","sw"] #en-us
  end
  def load_langs
    @languages = get_all_langs
  end
  def get_all_roles
    ["admin","moderator","subscriber","donor"]
  end

  def load_site_roles
    @site_roles = get_all_roles
  end


  def old_set_locale
    default_locale = @app_site.nil? ? Feedbacker.default_language : @app_site.default_locale
    begin
      if params[:locale] != nil
        all_locales.include?(params[:locale]) ? params[:locale] : all_locales[0]
          cookies.permanent[:locale] = params[:locale]
      end
      I18n.locale = (user_signed_in? && current_user.try(:locale)) || cookies[:locale] || read_lang_header || default_locale 
    rescue I18n::InvalidLocale
      I18n.locale = default_locale
    end
  end

  def set_locale
    default_locale = @app_site.nil? ? Feedbacker.default_language : @app_site.default_locale
    begin
      if params[:locale] != nil
          new_locale = all_locales.include?(params[:locale]) ? params[:locale] : all_locales[0]
          cookies.permanent[:locale] = new_locale #params[:locale].to_sym
          current_user.settings(:site).update!(:language => new_locale) if !(current_user.nil? || current_user.id.nil?) && current_user.respond_to?(:settings)
          I18n.locale = new_locale.to_sym

          redirect_to params[:r] if params[:r]
      else
        I18n.locale = (user_signed_in? && current_user.try(:locale)) || cookies[:locale] || read_lang_header || default_locale 
      end

      #I18n.locale = (user_signed_in?) || cookies[:locale] || read_lang_header || default_locale 
#      I18n.locale = (user_signed_in? && Feedbacker.languages.include?(params[:locale]) ? params[:locale].to_sym : false ) || cookies[:locale] || read_lang_header || default_locale 
    rescue I18n::InvalidLocale
      logger.debug "INVALID LOCALE"
      I18n.locale = default_locale
    end
  end




    module ClassMethods


    end


  end
end
