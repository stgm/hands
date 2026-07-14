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
    end

    test "students may not access notes" do
        sign_in_as(users(:student))
        get domain_notes_path(@domain.slug)
        assert_response :forbidden
    end

    test "attendance lists students with an open widget and reaps stale ones" do
        Presence.touch_open!(memberships(:student_algorithms), source_label: "coursesite-a", location: "7")
        sign_in_as(users(:ta))
        get domain_attendance_path(@domain.slug)
        assert_response :success
        assert_select "td", /Sam Student/

        travel (Settings.presence_stale_after + 5).seconds do
            get domain_attendance_path(@domain.slug)
            assert_select "td", { text: /Sam Student/, count: 0 }
        end
    end
end
