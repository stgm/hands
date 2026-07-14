require "test_helper"

class AdminCourseDomainsTest < ActionDispatch::IntegrationTest
    test "non-admins may not manage course domains" do
        sign_in_as(users(:teacher))
        get admin_course_domains_path
        assert_response :forbidden
    end

    test "guests are redirected away from admin" do
        get admin_course_domains_path
        assert_redirected_to root_path
    end

    test "an admin can create a course domain" do
        sign_in_as(users(:admin))
        assert_difference -> { CourseDomain.count }, 1 do
            post admin_course_domains_path, params: { course_domain: { name: "Operating Systems", location_type: "room", enrollment_open: "1" } }
        end
        domain = CourseDomain.find_by(name: "Operating Systems")
        assert_equal "operating-systems", domain.slug
        assert domain.link_secret.present?
        assert_redirected_to admin_course_domains_path
    end

    test "an admin can rotate the link secret" do
        sign_in_as(users(:admin))
        domain = course_domains(:algorithms)
        old = domain.link_secret
        post rotate_secret_admin_course_domain_path(domain)
        assert_not_equal old, domain.reload.link_secret
    end

    test "an admin can delete a course domain" do
        sign_in_as(users(:admin))
        domain = course_domains(:databases)
        assert_difference -> { CourseDomain.count }, -1 do
            delete admin_course_domain_path(domain)
        end
    end
end
