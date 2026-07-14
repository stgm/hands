class Embed::StyleController < ActionController::Base
    # Serves the self-contained widget stylesheet. Loaded both into the embed's
    # Shadow DOM (cross-origin <link>) and by the standalone widget page, so the
    # student popup looks the same everywhere. Public, cacheable, no secrets.
    def show
        expires_in 1.hour, public: true
        render template: "embed/style/show", formats: :css, layout: false,
            content_type: "text/css"
    end
end
