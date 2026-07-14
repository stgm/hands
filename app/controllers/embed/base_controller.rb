class Embed::BaseController < ActionController::Base
    # Cross-origin, token-authenticated widget API. No session, no CSRF: the
    # signed embed token is the sole credential.
    allow_browser versions: :modern
    skip_forgery_protection

    before_action :authenticate_embed

    private

    def authenticate_embed
        result = Embed::TokenVerifier.call(embed_token)
        if result.ok?
            @current_membership = result.membership
            @course_domain = result.membership.course_domain
            Current.membership = @current_membership
            Current.course_domain = @course_domain
            Current.user = @current_membership.user
            # Render in the language the course-site handed over in the token.
            I18n.locale = @current_membership.effective_locale
        else
            reason = result.error || (embed_token.blank? ? "no token" : "invalid token")
            Rails.logger.warn("[embed] auth failed: #{reason}")
            render plain: "embed auth failed: #{reason}", status: :unauthorized
        end
    end

    def embed_token
        header = request.headers["Authorization"].to_s
        header.start_with?("Bearer ") ? header.delete_prefix("Bearer ") : params[:token].to_s
    end

    def current_membership
        @current_membership
    end

    def current_course_domain
        @course_domain
    end
    helper_method :current_membership, :current_course_domain
end
