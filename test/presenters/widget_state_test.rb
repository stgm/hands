require "test_helper"

class WidgetStateTest < ActiveSupport::TestCase
    setup do
        @domain = course_domains(:algorithms)
        @student = memberships(:student_algorithms)
        @ta = memberships(:ta_algorithms)
    end

    test "no open hand → form" do
        assert_equal :form, WidgetState.for(@student).state
    end

    test "open unclaimed hand → waiting with a position" do
        Hand.create!(course_domain: @domain, membership: @student, help_question: "q")
        state = WidgetState.for(@student)
        assert_equal :waiting, state.state
        assert_equal 1, state.position
    end

    test "claimed hand → helping with the assisting staff" do
        hand = Hand.create!(course_domain: @domain, membership: @student, help_question: "q")
        hand.claim!(@ta)
        state = WidgetState.for(@student)
        assert_equal :helping, state.state
        assert_equal @ta, state.assist
    end

    test "locals expose everything the partials need" do
        Hand.create!(course_domain: @domain, membership: @student, help_question: "q")
        locals = WidgetState.for(@student).locals
        assert_equal %i[state hand position assist domain membership greeting].sort, locals.keys.sort
    end

    test "location bumper forces a check-in until we know where the student is" do
        @domain.update!(location_bumper: true, link_mode: false)
        @student.update!(last_location: nil)
        assert_equal :location, WidgetState.for(@student).state

        @student.update!(last_location: "Table 4")
        assert_equal :form, WidgetState.for(@student).state
    end

    test "greeting is one of the time-of-day phrases" do
        assert_includes [ "Good morning", "Good afternoon", "Good evening", "Good night" ],
            WidgetState.for(@student).greeting
    end
end
