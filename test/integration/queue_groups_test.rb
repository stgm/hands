require "test_helper"

class QueueGroupsTest < ActionDispatch::IntegrationTest
    setup do
        @domain = course_domains(:algorithms)
        @student = memberships(:student_algorithms)
    end

    test "a course without groups shows no tabs and no group badges" do
        @domain.hands.create!(membership: @student, help_question: "Pointers?")
        sign_in_as(users(:teacher))
        get domain_queue_hands_path(@domain.slug)

        assert_response :success
        assert_select ".queue-tabs", count: 0
        assert_select ".badge--group", count: 0
    end

    test "the group shows on the request and as a tab" do
        @student.update!(group: "Group 2")
        @domain.hands.create!(membership: @student, help_question: "Pointers?")
        sign_in_as(users(:teacher))
        get domain_queue_hands_path(@domain.slug)

        assert_select ".badge--group", "Group 2"
        assert_select ".queue-tab", "Group 2"
        assert_select "li[data-group=?]", "Group 2"
    end

    test "group tabs sort naturally and offer a no-group tab only when needed" do
        @student.update!(group: "Group 10")
        outsider = @domain.memberships.create!(user: users(:outsider), role: :student, group: "Group 2")
        sign_in_as(users(:teacher))

        get domain_queue_hands_path(@domain.slug)
        assert_equal [ "All", "Group 2", "Group 10" ], css_select(".queue-tab").map(&:text)

        # the teacher's own membership has no group, but staff are not students
        assert_select ".queue-tab", text: "No group", count: 0

        outsider.update!(group: nil)
        get domain_queue_hands_path(@domain.slug)
        assert_select ".queue-tab", text: "No group", count: 1
    end

    test "the selected tab is remembered on the staff member's membership" do
        @student.update!(group: "Group 2")
        teacher = memberships(:teacher_algorithms)
        sign_in_as(users(:teacher))

        patch filter_domain_queue_hands_path(@domain.slug), params: { group: "Group 2" }
        assert_response :no_content
        assert_equal "Group 2", teacher.reload.queue_group_filter

        get domain_queue_hands_path(@domain.slug)
        assert_select ".queue-tab--active", "Group 2"

        # no group param means the "All" tab
        patch filter_domain_queue_hands_path(@domain.slug)
        assert_nil teacher.reload.queue_group_filter
        get domain_queue_hands_path(@domain.slug)
        assert_select ".queue-tab--active", "All"
    end

    test "a stored group that no longer exists falls back to All" do
        @student.update!(group: "Group 2")
        memberships(:teacher_algorithms).update!(queue_group_filter: "Group 7")
        sign_in_as(users(:teacher))
        get domain_queue_hands_path(@domain.slug)

        assert_select ".queue-tab--active", "All"
    end

    test "students may not set a queue filter" do
        sign_in_as(users(:student))
        patch filter_domain_queue_hands_path(@domain.slug), params: { group: "Group 2" }
        assert_response :forbidden
    end
end
