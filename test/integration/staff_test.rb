require "test_helper"

class StaffTest < ActionDispatch::IntegrationTest
    setup { @domain = course_domains(:algorithms) }

    test "teachers can view staff management" do
        sign_in_as(users(:teacher))
        get domain_staff_path(@domain.slug)
        assert_response :success
        assert_select "h1", /Staff/
    end

    test "assistants may not manage staff" do
        sign_in_as(users(:ta))
        get domain_staff_path(@domain.slug)
        assert_response :forbidden
    end

    test "a teacher invites a staff member and an email is sent" do
        sign_in_as(users(:teacher))
        assert_difference -> { @domain.invitations.pending.count }, 1 do
            assert_emails 1 do
                perform_enqueued_jobs do
                    post domain_staff_invitations_path(@domain.slug), params: { email: "newta@example.org", role: "assistant" }
                end
            end
        end
    end

    test "accepting an invitation makes the invitee staff" do
        invitation = @domain.invitations.create!(email: users(:outsider).email, role: :teacher, invited_by: users(:teacher))
        sign_in_as(users(:outsider))
        get accept_invitation_path(invitation.token)
        assert_redirected_to domain_root_path(@domain.slug)
        assert @domain.membership_for(users(:outsider)).teacher?
    end

    test "a teacher can change a member's role and remove them" do
        sign_in_as(users(:teacher))
        ta = memberships(:ta_algorithms)
        patch domain_staff_member_path(@domain.slug, ta), params: { role: "teacher" }
        assert ta.reload.teacher?

        assert_difference -> { Membership.count }, -1 do
            delete domain_staff_member_path(@domain.slug, ta)
        end
    end

    test "accepting requires login and remembers the target" do
        invitation = @domain.invitations.create!(email: "x@example.org", role: :assistant)
        get accept_invitation_path(invitation.token)
        assert_redirected_to auth_mail_login_path
        assert_equal accept_invitation_path(invitation.token), session[:return_to]
    end
end
