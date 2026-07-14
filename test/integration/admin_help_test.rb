require "test_helper"

class AdminHelpTest < ActionDispatch::IntegrationTest
    setup { @domain = course_domains(:algorithms) }

    test "a site admin who is not a member can open any domain's queue" do
        assert_nil users(:admin).membership_in(@domain)
        sign_in_as(users(:admin))
        get domain_queue_hands_path(@domain.slug)
        assert_response :success
    end

    test "a site admin can claim and is enrolled as staff to be credited" do
        hand = Hand.create!(course_domain: @domain, membership: memberships(:student_algorithms), help_question: "q")
        sign_in_as(users(:admin))

        assert_difference -> { @domain.memberships.count }, 1 do
            put claim_domain_queue_hand_path(@domain.slug, hand)
        end
        membership = @domain.membership_for(users(:admin))
        assert membership.teacher?
        assert_equal membership, hand.reload.assist
    end

    test "a plain student still cannot access the queue" do
        sign_in_as(users(:student))
        get domain_queue_hands_path(@domain.slug)
        assert_response :forbidden
    end

    test "the domain landing page offers staff tools to a site admin" do
        sign_in_as(users(:admin))
        get domain_root_path(@domain.slug)
        assert_select "a", text: "Open the queue"
    end
end
