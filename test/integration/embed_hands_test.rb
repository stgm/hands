require "test_helper"

class EmbedHandsTest < ActionDispatch::IntegrationTest
    setup { @domain = course_domains(:algorithms) }

    # A fresh token per call (nonce is single-use).
    def token(**overrides)
        payload = {
            "email" => "embed.student@example.com",
            "name" => "Ed Embed",
            "student_number" => "55554444",
            "slug" => @domain.slug,
            "site_label" => "coursesite-a",
            "exp" => Time.now.to_i + 120,
            "nonce" => SecureRandom.hex(8)
        }.merge(overrides.transform_keys(&:to_s))
        Embed::Token.encode(payload, @domain.link_secret)
    end

    def auth_header(**o)
        { "Authorization" => "Bearer #{token(**o)}" }
    end

    test "GET returns the widget fragment for a valid token" do
        get embed_hand_path, headers: auth_header
        assert_response :success
        assert_select "form" # the ask form
        assert_select "h1", count: 0 # fragment only, no page chrome
    end

    test "the token can also be passed as a query param" do
        get embed_hand_path(token: token)
        assert_response :success
    end

    test "missing or invalid tokens are unauthorized" do
        get embed_hand_path
        assert_response :unauthorized

        get embed_hand_path, headers: { "Authorization" => "Bearer garbage" }
        assert_response :unauthorized
    end

    test "POST raises a hand and returns the waiting fragment" do
        assert_difference -> { @domain.hands.waiting.count }, 1 do
            post embed_hand_path, headers: auth_header, params: { question: "Cross-origin help?", location: "3" }
        end
        assert_response :success
        assert_select "*", /in line/i
    end

    test "DELETE cancels the current hand" do
        # first raise one
        post embed_hand_path, headers: auth_header, params: { question: "help" }
        user = User.find_by(email: "embed.student@example.com")
        assert @domain.memberships.find_by(user: user).hands.open.exists?

        delete embed_hand_path, headers: auth_header
        assert_response :success
        assert @domain.memberships.find_by(user: user).hands.open.none?
    end

    test "the widget auto-enrolls the student on first use" do
        assert_difference -> { @domain.memberships.count }, 1 do
            get embed_hand_path, headers: auth_header
        end
    end
end
