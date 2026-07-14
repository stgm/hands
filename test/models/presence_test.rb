require "test_helper"

class PresenceTest < ActiveSupport::TestCase
    setup do
        @student = memberships(:student_algorithms)
    end

    test "touch_open! creates then refreshes a single row per source" do
        assert_difference -> { Presence.count }, 1 do
            Presence.touch_open!(@student, source_label: "coursesite-a", location: "12")
        end
        first = Presence.last
        assert_equal @student.course_domain, first.course_domain

        travel 1.minute do
            assert_no_difference -> { Presence.count } do
                Presence.touch_open!(@student, source_label: "coursesite-a")
            end
        end
        assert first.reload.last_ping_at > first.connected_at
    end

    test "different sources are tracked separately" do
        Presence.touch_open!(@student, source_label: "a")
        Presence.touch_open!(@student, source_label: "b")
        assert_equal 2, @student.presences.count
    end

    test "active and stale scopes split on the heartbeat window" do
        Presence.touch_open!(@student, source_label: "a")
        assert_equal 1, Presence.active.count
        assert_equal 0, Presence.stale.count

        travel (Settings.presence_stale_after + 5).seconds do
            assert_equal 0, Presence.active.count
            assert_equal 1, Presence.stale.count
        end
    end

    test "reap_stale! removes only stale presences" do
        Presence.touch_open!(@student, source_label: "old")
        travel (Settings.presence_stale_after + 5).seconds do
            Presence.touch_open!(memberships(:ta_algorithms), source_label: "fresh")
            assert_difference -> { Presence.count }, -1 do
                Presence.reap_stale!
            end
        end
        assert_equal 1, Presence.count
    end

    test "close! removes a member's presence for a source" do
        Presence.touch_open!(@student, source_label: "a")
        Presence.close!(@student, source_label: "a")
        assert_equal 0, @student.presences.count
    end
end
