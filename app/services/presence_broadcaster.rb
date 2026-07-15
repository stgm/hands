# Pushes realtime updates over ActionCable/Turbo Streams to the staff
# "who's here" view whenever presence changes (student appears, moves, or leaves).
class PresenceBroadcaster
    def initialize(course_domain)
        @domain = course_domain
    end

    def refresh
        Turbo::StreamsChannel.broadcast_update_to(
            [ @domain, :attendance ],
            target: "attendance",
            partial: "hands/attendance/grid",
            locals: { students: students, presences_by_membership: presences_by_membership, course_domain: @domain }
        )
    end

    private

    def students
        @domain.memberships.students.includes(:user).sort_by(&:display_name)
    end

    def presences_by_membership
        @domain.presences.active.includes(:membership).group_by(&:membership_id)
    end
end
