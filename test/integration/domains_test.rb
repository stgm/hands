require "test_helper"

class DomainsTest < ActionDispatch::IntegrationTest
    test "an unknown slug returns not found" do
        sign_in_as(users(:student))
        get domain_root_path("does-not-exist")
        assert_response :not_found
    end

    test "a member sees the ask-a-question entry point" do
        sign_in_as(users(:student))
        get domain_root_path(course_domains(:algorithms).slug)
        assert_response :success
        assert_select "a", text: "Ask a question"
    end

    test "staff see the queue link" do
        sign_in_as(users(:ta))
        get domain_root_path(course_domains(:algorithms).slug)
        assert_select "a", text: "Open the queue"
    end

    test "a non-member can self-join an open domain" do
        sign_in_as(users(:outsider))
        assert_difference -> { Membership.count }, 1 do
            post domain_join_path(course_domains(:algorithms).slug)
        end
        assert course_domains(:algorithms).member?(users(:outsider))
    end

    test "self-join is refused when enrollment is closed" do
        sign_in_as(users(:outsider))
        assert_no_difference -> { Membership.count } do
            post domain_join_path(course_domains(:databases).slug)
        end
        assert_redirected_to domain_root_path(course_domains(:databases).slug)
        assert_match(/closed/i, flash[:alert])
    end

    test "unauthenticated access to a domain redirects to sign in and remembers the target" do
        target = domain_root_path(course_domains(:algorithms).slug)
        get target
        assert_redirected_to auth_mail_login_path
        assert_equal target, session[:return_to]
    end
end
