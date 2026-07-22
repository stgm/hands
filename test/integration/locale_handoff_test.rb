require "test_helper"

class LocaleHandoffTest < ActionDispatch::IntegrationTest
    setup { @domain = course_domains(:algorithms) }

    def token(locale:, email: "nl.student@example.com")
        payload = {
            "email" => email,
            "name" => "Nina NL",
            "student_number" => "42",
            "slug" => @domain.slug,
            "site_label" => "coursesite-nl",
            "locale" => locale,
            "nonce" => SecureRandom.hex(8)
        }
        Embed::Token.encode(payload, @domain.link_secret, @domain.slug)
    end

    test "the embedded widget renders in the language the course-site hands over" do
        get embed_hand_path, headers: { "Authorization" => "Bearer #{token(locale: 'nl')}" }
        assert_response :success
        assert_match "Geef aan wat je wil bespreken", response.body   # Dutch
        assert_no_match(/Provide a summary/, response.body)
    end

    test "an English course-site gets the English widget" do
        get embed_hand_path, headers: { "Authorization" => "Bearer #{token(locale: 'en')}" }
        assert_match "Provide a summary of what you would like to discuss", response.body
    end

    test "the handed-over locale is remembered on the membership" do
        get embed_hand_path, headers: { "Authorization" => "Bearer #{token(locale: 'nl')}" }
        membership = @domain.membership_for(User.find_by(email: "nl.student@example.com"))
        assert_equal "nl", membership.locale
    end

    test "realtime broadcasts also render in the remembered language" do
        get embed_hand_path, headers: { "Authorization" => "Bearer #{token(locale: 'nl')}" }
        membership = @domain.membership_for(User.find_by(email: "nl.student@example.com"))
        Hand.create!(course_domain: @domain, membership: membership, help_question: "vraag")

        # WidgetRenderer is what the broadcaster pushes; it must not depend on
        # ambient I18n state (a request may have left it in English).
        I18n.with_locale(:en) do
            assert_match "in de wachtrij", WidgetRenderer.render(membership)
        end
    end

    test "an unsupported locale falls back to the domain language" do
        get embed_hand_path, headers: { "Authorization" => "Bearer #{token(locale: 'xx')}" }
        assert_response :success
        membership = @domain.membership_for(User.find_by(email: "nl.student@example.com"))
        assert_nil membership.locale
        assert_match "Provide a summary", response.body # domain default (en)
    end

    test "the standalone widget uses the course domain's language" do
        @domain.update!(locale: "nl")
        sign_in_as(users(:student))
        get domain_hand_path(@domain.slug)
        assert_match "Geef aan wat je wil bespreken", response.body
    end
end
