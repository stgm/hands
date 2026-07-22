require "test_helper"

# Origin enforcement lives in ApplicationCable::Connection rather than in Action
# Cable's global allowed_request_origins, so these tests are what stands between
# the embed widget and a silent 404 on the WebSocket handshake — and between the
# session cookie and cross-site WebSocket hijacking.
class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
    tests ApplicationCable::Connection

    # ActionDispatch::TestRequest's own base_url, which same_origin? compares against.
    APP_ORIGIN = "http://test.host".freeze
    FOREIGN_ORIGIN = "https://course-site.example.org".freeze

    test "an embed token connects from a foreign origin" do
        connect "/cable?token=#{token_for(users(:student))}", headers: { "Origin" => FOREIGN_ORIGIN }

        assert_equal users(:student), connection.current_user
        assert_equal memberships(:student_algorithms), connection.current_membership
    end

    test "a session cookie is refused from a foreign origin" do
        sign_in users(:student)

        assert_reject_connection do
            connect "/cable", headers: { "Origin" => FOREIGN_ORIGIN }
        end
    end

    test "a session cookie connects from the app's own origin" do
        sign_in users(:student)

        connect "/cable", headers: { "Origin" => APP_ORIGIN }

        assert_equal users(:student), connection.current_user
        assert_nil connection.current_membership
    end

    test "a session cookie connects when no origin is sent" do
        sign_in users(:student)

        connect "/cable"

        assert_equal users(:student), connection.current_user
    end

    test "an unverifiable token does not fall through to the cookie" do
        sign_in users(:student)

        assert_reject_connection do
            connect "/cable?token=garbage", headers: { "Origin" => FOREIGN_ORIGIN }
        end
    end

    private

    # Wrapped in value: because Action Cable's TestCookies#[]= reads a bare Hash
    # as cookie *options* and would store options[:value] — i.e. nil — instead of
    # the session payload.
    def sign_in(user)
        cookies.encrypted[Rails.application.config.session_options[:key]] =
            { value: { "user_id" => user.id } }
    end

    def token_for(user, domain: course_domains(:algorithms))
        Embed::Token.encode(
            {
                "email" => user.email,
                "name" => user.name,
                "student_number" => user.student_number,
                "slug" => domain.slug,
                "site_label" => "test-site",
                "locale" => "en",
                "nonce" => SecureRandom.hex(8)
            },
            domain.link_secret,
            domain.slug
        )
    end
end
