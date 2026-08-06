require "test_helper"

class CourseDomainTest < ActiveSupport::TestCase
    test "generates a slug from the name" do
        domain = CourseDomain.create!(name: "Intro to Ruby")
        assert_equal "intro-to-ruby", domain.slug
    end

    test "generates a link_secret on create and can rotate it" do
        domain = CourseDomain.create!(name: "Secrets")
        assert domain.link_secret.present?
        old = domain.link_secret
        domain.rotate_link_secret!
        assert_not_equal old, domain.link_secret
    end

    test "enroll_via_widget! always enrolls even when enrollment is closed" do
        domain = course_domains(:databases)
        assert_not domain.enrollment_open?
        membership = domain.enroll_via_widget!(users(:outsider), source_label: "coursesite-x")
        assert membership.student?
        assert_equal "coursesite-x", membership.source_label
    end

    test "enroll_via_widget! is idempotent" do
        domain = course_domains(:algorithms)
        assert_no_difference -> { Membership.count } do
            m = domain.enroll_via_widget!(users(:student), source_label: "x")
            assert_equal memberships(:student_algorithms), m
        end
    end

    test "self_join! respects enrollment_open" do
        assert_nil course_domains(:databases).self_join!(users(:outsider))
        membership = course_domains(:algorithms).self_join!(users(:outsider))
        assert membership.student?
    end

    test "self_join! returns existing membership regardless of enrollment_open" do
        assert_equal memberships(:student_algorithms),
            course_domains(:algorithms).self_join!(users(:student))
    end

    test "managed_by? covers the creator and every admin" do
        algorithms = course_domains(:algorithms)
        assert algorithms.managed_by?(users(:teacher))
        assert algorithms.managed_by?(users(:admin))
        assert_not algorithms.managed_by?(users(:ta))
        assert_not algorithms.managed_by?(users(:newteacher))

        databases = course_domains(:databases)
        assert_nil databases.created_by
        assert_not databases.managed_by?(users(:teacher))
    end

    test "a course has no groups until memberships get one" do
        algorithms = course_domains(:algorithms)
        assert_not algorithms.groups?
        assert_empty algorithms.group_names

        memberships(:student_algorithms).update!(group: "Group 1")
        assert algorithms.groups?
        assert_equal [ "Group 1" ], algorithms.group_names
    end

    test "group_names sorts numbers naturally and lists each group once" do
        algorithms = course_domains(:algorithms)
        memberships(:student_algorithms).update!(group: "Group 10")
        algorithms.memberships.create!(user: users(:outsider), role: :student, group: "Group 2")
        algorithms.memberships.create!(user: users(:newteacher), role: :student, group: "Group 2")

        assert_equal [ "Group 2", "Group 10" ], algorithms.group_names
    end

    test "ungrouped_students? ignores staff without a group" do
        algorithms = course_domains(:algorithms)
        memberships(:student_algorithms).update!(group: "Group 1")
        assert_not algorithms.ungrouped_students?

        algorithms.memberships.create!(user: users(:outsider), role: :student)
        assert algorithms.ungrouped_students?
    end
end
