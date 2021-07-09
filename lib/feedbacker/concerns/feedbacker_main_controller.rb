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
#   <%= request.host %>: <%= request.domain %>
#   @app_site = Site.where(domain:request.host).first
#   impressionist @app_site unless @app_site.nil?
    load_langs
    set_locale
  end

  # main NAV links
  def load_site_menu
    @site_menu = []
    @site_menu.push ["People",main_app.users_path,controller_name == 'users']
    @site_menu.push ["Admin",main_app.admin_path,controller_name == 'admin' && !respond_to?(:feedbacker?)]
    @site_menu.push ["Feedback",feedbacker.admin_path,controller_name == "admin" && (respond_to?(:feedbacker?) && feedbacker?)]
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
    ["en","sw"] # en-us
  end

  def get_all_langs
    ["en","sw"] #en-us
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


  def set_locale
    default_locale = @app_site.nil? ? "en" : @app_site.default_locale
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




    module ClassMethods


    end


  end
end
