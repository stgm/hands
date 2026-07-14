require "test_helper"

class WidgetChannelTest < ActionCable::Channel::TestCase
    setup { @domain = course_domains(:algorithms) }

    test "subscribing streams for the member and records presence" do
        stub_connection(current_user: users(:student), current_membership: nil)
        subscribe(domain: @domain.slug, source_label: "coursesite-a")

        assert subscription.confirmed?
        assert_has_stream_for memberships(:student_algorithms)
        assert memberships(:student_algorithms).presences.where(source_label: "coursesite-a").exists?
    end

    test "rejects a user with no membership in the domain" do
        stub_connection(current_user: users(:outsider), current_membership: nil)
        subscribe(domain: @domain.slug)
        assert subscription.rejected?
    end

    test "an embed (token) connection uses its membership directly" do
        stub_connection(current_user: users(:student), current_membership: memberships(:student_algorithms))
        subscribe(source_label: "embed")
        assert subscription.confirmed?
        assert_has_stream_for memberships(:student_algorithms)
    end

    test "appear refreshes presence and unsubscribe clears it" do
        stub_connection(current_user: users(:student), current_membership: nil)
        subscribe(domain: @domain.slug, source_label: "a")
        perform :appear
        assert_equal 1, memberships(:student_algorithms).presences.count
        unsubscribe
        assert_equal 0, memberships(:student_algorithms).presences.count
    end

    test "a hand change broadcasts refreshed widget HTML to the asker" do
        assert_broadcasts(WidgetChannel.broadcasting_for(memberships(:student_algorithms)), 1) do
            Hand.create!(course_domain: @domain, membership: memberships(:student_algorithms), help_question: "q")
        end
    end
end
