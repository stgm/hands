require "test_helper"

class InvitationTest < ActiveSupport::TestCase
    setup { @domain = course_domains(:algorithms) }

    test "email is normalized and a token generated" do
        inv = @domain.invitations.create!(email: "  New.TA@Example.COM ", role: :assistant)
        assert_equal "new.ta@example.com", inv.email
        assert inv.token.present?
        assert inv.pending?
    end

    test "accept! creates a staff membership for a new member" do
        inv = @domain.invitations.create!(email: users(:outsider).email, role: :teacher)
        membership = inv.accept!(users(:outsider))
        assert membership.teacher?
        assert_not inv.pending?
    end

    test "accept! upgrades an existing student's role" do
        inv = @domain.invitations.create!(email: users(:student).email, role: :assistant)
        membership = inv.accept!(users(:student))
        assert_equal memberships(:student_algorithms), membership
        assert membership.assistant?
    end

    test "accept! is idempotent once accepted" do
        inv = @domain.invitations.create!(email: users(:outsider).email, role: :assistant)
        first = inv.accept!(users(:outsider))
        assert_no_difference -> { Membership.count } do
            second = inv.accept!(users(:outsider))
            assert_equal first, second
        end
    end

    test "pending scope excludes accepted invitations" do
        pending = @domain.invitations.create!(email: "a@example.com", role: :assistant)
        accepted = @domain.invitations.create!(email: "b@example.com", role: :assistant)
        accepted.accept!(users(:outsider))
        assert_includes @domain.invitations.pending, pending
        assert_not_includes @domain.invitations.pending, accepted
    end
end
