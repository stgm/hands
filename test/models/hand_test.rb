require "test_helper"

class HandTest < ActiveSupport::TestCase
    setup do
        @domain = course_domains(:algorithms)
        @student = memberships(:student_algorithms)
        @ta = memberships(:ta_algorithms)
    end

    def raise_hand(member = @student, **attrs)
        Hand.create!({ course_domain: @domain, membership: member, help_question: "Why?" }.merge(attrs))
    end

    test "a new hand starts waiting and unclaimed" do
        hand = raise_hand
        assert_includes @domain.hands.waiting, hand
        assert_nil hand.assist
    end

    test "a member cannot open two hands at once" do
        raise_hand
        second = Hand.new(course_domain: @domain, membership: @student, help_question: "again")
        assert_not second.valid?
    end

    test "claim! assigns staff and moves the hand out of waiting" do
        hand = raise_hand
        assert hand.claim!(@ta)
        assert_equal @ta, hand.assist
        assert_not_includes @domain.hands.waiting, hand
        assert_includes @domain.hands.claimed, hand
    end

    test "claim! fails when already claimed" do
        hand = raise_hand
        hand.claim!(@ta)
        assert_equal false, hand.claim!(memberships(:teacher_algorithms))
        assert_equal @ta, hand.reload.assist
    end

    test "close! records outcome and closes the hand" do
        hand = raise_hand
        hand.claim!(@ta)
        hand.close!(success: true, evaluation: "solved")
        assert hand.done?
        assert hand.success?
        assert hand.closed_at.present?
        assert_not_includes @domain.hands.open, hand
    end

    test "queue_position counts earlier waiting hands" do
        first = raise_hand(@student)
        # a second member in the same domain
        other = @domain.memberships.create!(user: users(:outsider), role: :student)
        second = raise_hand(other)
        assert_equal 1, first.queue_position
        assert_equal 2, second.queue_position
        first.claim!(@ta)
        assert_nil first.queue_position
        assert_equal 1, second.reload.queue_position
    end

    test "remove_all_stale closes every waiting hand" do
        raise_hand
        Hand.remove_all_stale
        assert @domain.hands.waiting.none?
    end

    test "duration is measured between claim and close" do
        hand = raise_hand
        hand.update!(claimed_at: 10.minutes.ago, closed_at: Time.current)
        assert_in_delta 10, hand.duration, 1
    end
end
