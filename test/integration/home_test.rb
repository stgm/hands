require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
    test "a student with a single course skips the list and lands on the hand page" do
        sign_in_as(users(:student))
        get root_path
        assert_redirected_to domain_hand_path(course_domains(:algorithms).slug)
    end

    test "a student in more than one course still sees the list" do
        memberships(:student_algorithms).user
            .memberships.create!(course_domain: course_domains(:databases), role: :student)
        sign_in_as(users(:student))
        get root_path
        assert_response :success
        assert_select "body", /Algorithms/
        assert_select "body", /Databases/
    end

    test "a logged-in user without a name is asked for one, wherever they are" do
        users(:ta).update!(name: nil)
        sign_in_as(users(:ta))
        get root_path
        assert_redirected_to edit_profile_path
        assert_equal root_path, session[:return_to]
    end

    test "the profile form and signing out stay reachable without a name" do
        users(:ta).update!(name: nil)
        sign_in_as(users(:ta))

        get edit_profile_path
        assert_response :success

        delete logout_path
        assert_nil session[:user_id]
    end

    test "an anonymous visitor still gets the public homepage, not a redirect loop" do
        get root_path
        assert_response :success
    end

    test "staff see the list even with a single course" do
        sign_in_as(users(:ta))
        get root_path
        assert_response :success
        assert_select "body", /Algorithms/
    end
end
