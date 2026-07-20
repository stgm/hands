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

    test "staff see the list even with a single course" do
        sign_in_as(users(:ta))
        get root_path
        assert_response :success
        assert_select "body", /Algorithms/
    end
end
