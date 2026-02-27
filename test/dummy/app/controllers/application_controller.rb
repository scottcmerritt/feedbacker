class ApplicationController < ActionController::Base
  helper_method :current_user, :user_signed_in?, :is_admin?, :is_first_user?, :no_admins?

  # Auth stubs: work with or without Devise. Override in host app when Devise is present.
  def current_user
    nil
  end

  def user_signed_in?
    return super if defined?(super)
    current_user.present?
  end

  def authenticate_user!
    return super if defined?(super)
    return if user_signed_in?
    redirect_to(main_app.respond_to?(:root_path) ? main_app.root_path : root_path,
                alert: "Please sign in.") and return
  end

  def is_admin?
    return super if defined?(super)
    user_signed_in? && current_user.respond_to?(:has_role?) && current_user.has_role?(:admin)
  end

  def authenticate_admin!
    return super if defined?(super)
    authenticate_user!
    return if performed?
    return if is_admin?
    redirect_to(main_app.respond_to?(:root_path) ? main_app.root_path : root_path,
                notice: "Permission denied.") and return
  end

  def is_first_user?
    return super if defined?(super)
    user_signed_in? && current_user.try(:id) == 1
  end

  def no_admins?
    return super if defined?(super)
    defined?(User) && User.respond_to?(:with_role) ? User.with_role(:admin).count == 0 : true
  end
end
