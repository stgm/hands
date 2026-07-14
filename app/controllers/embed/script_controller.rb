class Embed::ScriptController < ActionController::Base
    # Serves the self-contained widget loader that linked course-sites embed with
    # a <script src> tag. Public and cacheable; it carries no secrets and reads
    # its configuration from window.HandsEmbed set by the host page.
    #
    # This script is *meant* to be loaded cross-origin, so Rails' cross-origin
    # JavaScript protection (which would 422 a non-XHR .js GET) is turned off.
    # Rails blocks non-XHR cross-origin JS responses by default; this script is
    # deliberately loaded cross-origin via <script src>, so opt out.
    skip_after_action :verify_same_origin_request, raise: false

    def show
        expires_in 5.minutes, public: true
        render template: "embed/script/show", formats: :js, layout: false,
            content_type: "text/javascript"
    end
end
