require "test_helper"

class NotesAndAttendanceTest < ActionDispatch::IntegrationTest
    setup { @domain = course_domains(:algorithms) }

    test "staff can write a note about a student" do
        sign_in_as(users(:ta))
        assert_difference -> { @domain.notes.written.count }, 1 do
            post domain_notes_path(@domain.slug), params: {
                membership_id: memberships(:student_algorithms).id,
                text: "Great progress today"
            }
        end
        note = @domain.notes.written.last
        assert_equal memberships(:ta_algorithms), note.author
        assert_equal "Great progress today", note.text.to_plain_text
        assert_redirected_to domain_student_notes_path(@domain.slug, memberships(:student_algorithms).id)
    end

    test "staff cannot post an empty note" do
        sign_in_as(users(:ta))
        assert_no_difference -> { @domain.notes.written.count } do
            post domain_notes_path(@domain.slug), params: {
                membership_id: memberships(:student_algorithms).id,
                text: ""
            }
        end
        assert_redirected_to domain_student_notes_path(@domain.slug, memberships(:student_algorithms).id)
        follow_redirect!
        assert_select ".alert-danger", /can.t be blank/
    end

    test "students may not access notes" do
        sign_in_as(users(:student))
        get domain_notes_path(@domain.slug)
        assert_response :forbidden
    end

    test "recent notes list links to the student's personal notes page" do
        note = @domain.notes.create!(
            membership: memberships(:student_algorithms),
            author: memberships(:ta_algorithms),
            text: "Great progress today"
        )
        sign_in_as(users(:ta))
        get domain_notes_path(@domain.slug)
        assert_response :success
        assert_select "a[href=?]", domain_student_notes_path(@domain.slug, note.membership_id), /Sam Student/
    end

    test "a student's personal notes page lists only their notes" do
        student = memberships(:student_algorithms)
        note = @domain.notes.create!(membership: student, author: memberships(:ta_algorithms), text: "Solid work")
        sign_in_as(users(:ta))
        get domain_student_notes_path(@domain.slug, student.id)
        assert_response :success
        assert_select ".list-group-item", text: /Solid work/
    end

    test "attendance grid marks students with an open widget as present and reaps stale ones" do
        Presence.touch_open!(memberships(:student_algorithms), source_label: "coursesite-a", location: "7")
        sign_in_as(users(:ta))
        get domain_attendance_path(@domain.slug)
        assert_response :success
        assert_select ".student-card--present .card-title", /Sam Student/

        travel (Settings.presence_stale_after + 5).seconds do
            get domain_attendance_path(@domain.slug)
            assert_select ".student-card--present", count: 0
            assert_select ".card-title", /Sam Student/
        end
    end
end
