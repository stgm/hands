module Authentication
    extend ActiveSupport::Concern

    included do
        helper_method :authenticated?, :logged_in?, :current_user
        before_action :current_user
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
        session.delete(:return_to) || root_path
    end
end
