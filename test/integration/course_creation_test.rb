require "test_helper"

class CourseCreationTest < ActionDispatch::IntegrationTest
    def course_params(name: "Compilers")
        { course_domain: { name: name, location_type: "table", locale: "en" } }
    end

    test "a teacher without a course sees the create link and can create one" do
        sign_in_as users(:newteacher)
        get root_path
        assert_select "a[href=?]", new_course_path, text: "Create a course"

        get new_course_path
        assert_response :success
        # only the three decisions a teacher makes up front
        assert_select "input[name=?]", "course_domain[name]"
        assert_select "input[name=?]", "course_domain[location_type]"
        assert_select "select[name=?]", "course_domain[locale]"
        %w[enrollment_open ask_location location_bumper link_mode].each do |field|
            assert_select "[name=?]", "course_domain[#{field}]", count: 0
        end

        assert_difference -> { CourseDomain.count }, 1 do
            post courses_path, params: course_params
        end
        course = CourseDomain.find_by(name: "Compilers")
        assert_redirected_to domain_root_path(course.slug)
        assert_equal users(:newteacher), course.created_by
        assert course.membership_for(users(:newteacher)).teacher?
        assert course.enrollment_open?, "a new course lets students join by default"
    end

    test "a teacher may not create a second course" do
        sign_in_as users(:teacher)
        get root_path
        assert_select "a[href=?]", new_course_path, count: 0

        get new_course_path
        assert_response :forbidden

        assert_no_difference -> { CourseDomain.count } do
            post courses_path, params: course_params
        end
        assert_response :forbidden
    end

    test "an invalid course is re-rendered without being created" do
        sign_in_as users(:newteacher)
        assert_no_difference -> { CourseDomain.count } do
            post courses_path, params: course_params(name: "")
        end
        assert_response :unprocessable_entity
    end

    test "a student may not create a course" do
        sign_in_as users(:student)
        get new_course_path
        assert_response :forbidden

        assert_no_difference -> { CourseDomain.count } do
            post courses_path, params: course_params
        end
        assert_response :forbidden
    end

    test "a signed-out visitor is sent home" do
        get new_course_path
        assert_redirected_to root_path
    end

    test "the creator can edit the name, label and language" do
        sign_in_as users(:teacher)
        domain = course_domains(:algorithms)

        get edit_course_path(domain)
        assert_response :success
        # the same three fields as on the create form, and nothing else
        assert_select "input[name=?]", "course_domain[location_type]"
        %w[enrollment_open ask_location location_bumper link_mode].each do |field|
            assert_select "[name=?]", "course_domain[#{field}]", count: 0
        end

        patch course_path(domain), params: { course_domain: { name: "Algorithms II", locale: "nl" } }
        assert_redirected_to domain_root_path(domain.reload.slug)
        assert_equal "Algorithms II", domain.name
        assert_equal "nl", domain.locale
    end

    test "a teacher cannot change the other settings by posting them" do
        sign_in_as users(:teacher)
        domain = course_domains(:algorithms)
        assert domain.enrollment_open?

        patch course_path(domain), params: {
            course_domain: { name: "Algorithms", enrollment_open: "0", link_mode: "1" }
        }
        assert domain.reload.enrollment_open?, "enrollment_open is not a teacher setting"
        assert_not domain.link_mode?
    end

    test "a teacher may not edit someone else's course" do
        sign_in_as users(:newteacher)
        get edit_course_path(course_domains(:algorithms))
        assert_response :forbidden

        patch course_path(course_domains(:algorithms)), params: { course_domain: { name: "Hijacked" } }
        assert_response :forbidden
        assert_equal "Algorithms", course_domains(:algorithms).reload.name
    end

    test "staff without ownership may not edit the course" do
        sign_in_as users(:ta)
        get edit_course_path(course_domains(:algorithms))
        assert_response :forbidden
    end

    test "an admin can edit any course through this path" do
        sign_in_as users(:admin)
        get edit_course_path(course_domains(:databases))
        assert_response :success
    end

    test "staff can read the invite link for their course" do
        sign_in_as users(:ta)
        domain = course_domains(:algorithms)

        get domain_invite_path(domain.slug)
        assert_response :success
        assert_select "body", /#{Regexp.escape(domain_root_url(domain.slug))}/
    end

    test "a student cannot read the invite link" do
        sign_in_as users(:student)
        get domain_invite_path(course_domains(:algorithms).slug)
        assert_response :forbidden
    end
end
