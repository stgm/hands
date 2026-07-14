# Development-only harness to exercise the embed widget flow (token mint +
# embed/widget.js) without a running course-site. Mimics what course-site does.
class DevEmbedHarnessController < ActionController::Base
    before_action :require_dev

    def token
        domain = CourseDomain.find_by!(slug: "demo")
        student = User.find_by!(email: "student@example.com")
        payload = {
            "email" => student.email,
            "name" => student.name.to_s,
            "student_number" => student.student_number.to_s,
            "slug" => domain.slug,
            "site_label" => "dev-harness",
            "locale" => params[:locale].presence || "en",
            "exp" => Time.now.to_i + 120,
            "nonce" => SecureRandom.hex(12)
        }
        # Mirrors course-site: the widget only needs the token back.
        render json: { token: Embed::Token.encode(payload, domain.link_secret) }
    end

    def host
    end

    private

    def require_dev
        head :not_found unless Rails.env.development?
    end
end
