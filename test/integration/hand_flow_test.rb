require "test_helper"

class HandFlowTest < ActionDispatch::IntegrationTest
    setup { @domain = course_domains(:algorithms) }

    test "a student raises a hand and sees their queue position" do
        sign_in_as(users(:student))
        get domain_hand_path(@domain.slug)
        assert_select "form" # the ask form

        assert_difference -> { @domain.hands.waiting.count }, 1 do
            post domain_hand_path(@domain.slug), params: { question: "Pointers?", location: "12" }
        end
        assert_select "#hand_widget", /in line/i
        assert_select "#hand_widget", /1/
    end

    test "a widget-fragment request returns the bare widget without page chrome" do
        sign_in_as(users(:student))
        post domain_hand_path(@domain.slug), params: { question: "Fragment?" },
            headers: { "X-Widget-Fragment" => "1" }
        assert_response :success
        assert_select "h1", count: 0           # no page heading
        assert_select "#hand_widget", count: 0 # bare inner fragment, not the wrapper
        assert_match(/in line/i, response.body)
    end

    test "a student cannot open two hands" do
        sign_in_as(users(:student))
        post domain_hand_path(@domain.slug), params: { question: "one" }
        assert_no_difference -> { @domain.hands.count } do
            post domain_hand_path(@domain.slug), params: { question: "two" }
        end
    end

    test "a student cancels their hand" do
        sign_in_as(users(:student))
        post domain_hand_path(@domain.slug), params: { question: "help" }
        delete domain_hand_path(@domain.slug)
        assert @domain.hands.open.none?
        assert_select "#hand_widget form" # back to the ask form
    end

    test "assistants without availability are sent to set it" do
        sign_in_as(users(:ta))
        get domain_queue_hands_path(@domain.slug)
        assert_redirected_to edit_domain_availability_path(@domain.slug)
    end

    test "an assistant claims a hand by opening it and the student sees help coming" do
        # student raises a hand
        sign_in_as(users(:student))
        post domain_hand_path(@domain.slug), params: { question: "recursion" }
        hand = @domain.hands.waiting.first
        reset!

        # TA becomes available and opens the hand (auto-claim)
        sign_in_as(users(:ta))
        patch domain_availability_path(@domain.slug), params: { minutes: 60 }
        get domain_queue_hands_path(@domain.slug)
        assert_response :success
        assert_select "##{ActionView::RecordIdentifier.dom_id(hand)}"

        get domain_queue_hand_path(@domain.slug, hand) # staff show → auto-claim
        assert_equal memberships(:ta_algorithms), hand.reload.assist
        reset!

        # student now sees the "wait is over" helping view
        sign_in_as(users(:student))
        get domain_hand_path(@domain.slug)
        assert_select "#hand_widget", /wait is over/i
    end

    test "an assistant marks a hand done" do
        sign_in_as(users(:ta))
        patch domain_availability_path(@domain.slug), params: { minutes: 60 }
        hand = Hand.create!(course_domain: @domain, membership: memberships(:student_algorithms), help_question: "q")
        hand.claim!(memberships(:ta_algorithms))

        put done_domain_queue_hand_path(@domain.slug, hand, success: true)
        assert hand.reload.done?
        assert hand.success?
    end
end
