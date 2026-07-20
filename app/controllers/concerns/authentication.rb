module Authentication
    extend ActiveSupport::Concern

    included do
        helper_method :authenticated?, :logged_in?, :current_user
        before_action :current_user
        before_action :require_profile
    end

    # A confirmed login exists when both session keys are present. Mirrors
    # course-site: identity lives entirely in the signed session cookie.
    def authenticated?
        session[:user_id].present? && session[:user_email].present?
    end

    def logged_in?
        authenticated? && current_user.persisted?
    end

    def current_user
        if @current_user.nil?
            found = authenticated? && User.find_by(id: session[:user_id], email: session[:user_email])
            @current_user = found || User.new
        end
        Current.user = @current_user
    end

    def sign_in(user)
        reset_session
        session[:user_id] = user.id
        session[:user_email] = user.email
        @current_user = nil
    end

    def sign_out
        reset_session
        @current_user = nil
    end

    # --- before_action guards (global scope; domain-scoped guards live in
    # DomainScoped) ---

    # Require a confirmed login, but not necessarily a filled-in profile.
    def authenticate
        redirect_to root_path unless authenticated?
    end

    # Knowing a person's name is a precondition for being a logged-in user at
    # all, so this runs everywhere by default; controllers that have to stay
    # reachable while the name is still missing (the login flow and the profile
    # form itself) skip it. Says nothing about anonymous visitors -- public
    # pages stay public, and pages that need a login ask for one separately.
    def require_profile
        return unless logged_in?
        return if current_user.valid_profile?

        session[:return_to] = request.fullpath if request.get?
        redirect_to edit_profile_path
    end

    # Require a logged-in user with a usable profile (we need their name).
    def authorize
        redirect_to(root_path) && return unless logged_in?
        redirect_to(edit_profile_path) unless current_user.valid_profile?
    end

    def require_admin
        head :forbidden unless current_user.admin?
    end

    # After a successful login, return to the page that sent the user to sign in
    # (e.g. a course-domain URL), falling back to the dashboard.
    def after_sign_in_path
        # Ask for the missing profile details right away, keeping :return_to in
        # the session so saving the profile lands the user where they meant to go.
        return edit_profile_path unless current_user.valid_profile?

        session.delete(:return_to) || root_path
    end
end
