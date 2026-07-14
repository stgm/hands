require "test_helper"

class MembershipTest < ActiveSupport::TestCase
    test "a user can join a domain only once" do
        dup = Membership.new(user: users(:student), course_domain: course_domains(:algorithms), role: :student)
        assert_not dup.valid?
    end

    test "staff? covers assistants and teachers" do
        assert memberships(:ta_algorithms).staff?
        assert memberships(:teacher_algorithms).staff?
        assert_not memberships(:student_algorithms).staff?
    end

    test "senior? is teacher-only" do
        assert memberships(:teacher_algorithms).senior?
        assert_not memberships(:ta_algorithms).senior?
    end

    test "available? and available scope reflect availability window" do
        ta = memberships(:ta_algorithms)
        assert_not ta.available?
        ta.update!(available_until: 1.hour.from_now)
        assert ta.available?
        assert_includes Membership.available, ta
    end

    test "staff and students scopes partition by role" do
        assert_equal [ memberships(:student_algorithms) ].sort, Membership.students.to_a.sort
        assert_includes Membership.staff, memberships(:ta_algorithms)
        assert_not_includes Membership.staff, memberships(:student_algorithms)
    end
end
