require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
    test "the sign-in form renders" do
        get auth_mail_login_path
        assert_response :success
        assert_select "input[type=email]"
    end

    test "email code login signs in an existing user" do
        perform_enqueued_jobs do
            # a TA sees the domain list; a single-course student would be sent
            # straight to the hand page instead (see HomeController#index)
            post auth_mail_create_path, params: { email: "ta@example.com" }
        end
        assert_redirected_to auth_mail_code_path

        post auth_mail_validate_path, params: { code: latest_login_code }
        assert_redirected_to root_path
        follow_redirect!
        # the top-level menu: their domains, plus sign out
        assert_select "body", /Algorithms/
        assert_select "body", /Sign out/
    end

    test "email code login creates a new account and asks for a profile" do
        assert_difference -> { User.count }, 1 do
            perform_enqueued_jobs do
                post auth_mail_create_path, params: { email: "fresh@example.org" }
            end
            post auth_mail_validate_path, params: { code: latest_login_code }
        end
        # a brand-new account has no name yet, so ask before anything else
        assert_redirected_to edit_profile_path
    end

    test "a wrong code does not sign you in" do
        perform_enqueued_jobs do
            post auth_mail_create_path, params: { email: "student@example.com" }
        end
        post auth_mail_validate_path, params: { code: "zzzzzz" }
        assert_redirected_to auth_mail_login_path
        get root_path
        assert_select "a", text: "Sign in"
    end

    test "an invalid email is rejected" do
        post auth_mail_create_path, params: { email: "not-an-email" }
        assert_redirected_to auth_mail_login_path
        assert_equal "Email seems invalid", flash[:alert]
    end

    test "an expired code is rejected" do
        perform_enqueued_jobs do
            post auth_mail_create_path, params: { email: "student@example.com" }
        end
        code = latest_login_code
        travel 16.minutes do
            post auth_mail_validate_path, params: { code: code }
        end
        assert_redirected_to auth_mail_login_path
    end

    test "sign out clears the session" do
        sign_in_as(users(:student))
        delete logout_path
        assert_redirected_to root_path
        get root_path
        assert_select "a", text: "Sign in"
    end
end
