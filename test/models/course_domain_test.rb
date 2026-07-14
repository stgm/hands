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
end
