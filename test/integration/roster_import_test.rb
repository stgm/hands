require "test_helper"

class RosterImportFlowTest < ActionDispatch::IntegrationTest
    setup { @domain = course_domains(:algorithms) }

    test "a teacher previews and then confirms an import" do
        sign_in_as(users(:teacher))
        csv = "Email;Name;Group\nnew@student.uva.nl;New Student;Group 1\n#{users(:student).email};Sam Student;Group 2\n"

        assert_no_difference "User.count" do
            post domain_students_import_path(@domain.slug), params: { text: csv }
        end
        assert_response :success
        assert_select "li", /new@student.uva.nl/

        assert_difference "User.count", 1 do
            post domain_confirm_students_import_path(@domain.slug), params: { text: csv }
        end
        assert_redirected_to domain_students_import_path(@domain.slug)

        assert_equal "Group 1", @domain.membership_for(User.find_by(email: "new@student.uva.nl")).group
        assert_equal "Group 2", memberships(:student_algorithms).reload.group
    end

    test "a list without an email column is refused before anything is written" do
        sign_in_as(users(:teacher))

        assert_no_difference "User.count" do
            post domain_students_import_path(@domain.slug), params: { text: "Name,Group\nSomeone,Group 1\n" }
        end
        assert_redirected_to domain_students_import_path(@domain.slug)
        assert_match(/email column/, flash[:alert])
    end

    test "an empty paste is refused" do
        sign_in_as(users(:teacher))
        post domain_students_import_path(@domain.slug), params: { text: "  \n" }

        assert_redirected_to domain_students_import_path(@domain.slug)
        assert_match(/Paste/, flash[:alert])
    end

    test "assistants may not import" do
        sign_in_as(users(:ta))
        get domain_students_import_path(@domain.slug)
        assert_response :forbidden
    end

    test "the students page lists the enrolled count and the groups" do
        memberships(:student_algorithms).update!(group: "Group 2")
        sign_in_as(users(:teacher))
        get domain_students_import_path(@domain.slug)

        assert_response :success
        assert_select ".hands-app", /1 student enrolled/
        assert_select ".badge", "Group 2"
    end
end
