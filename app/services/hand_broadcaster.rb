# Pushes realtime updates over ActionCable/Turbo Streams whenever a hand
# changes: refreshes the staff queue and every affected student's widget (queue
# positions shift for everyone still waiting).
class HandBroadcaster
    def initialize(course_domain)
        @domain = course_domain
    end

    def refresh(changed_membership: nil)
        broadcast_queue
        broadcast_widgets(changed_membership)
    end

    def broadcast_queue
        # `update` (not `replace`) so the #queue wrapper element survives and
        # remains the target for subsequent broadcasts.
        Turbo::StreamsChannel.broadcast_update_to(
            [ @domain, :queue ],
            target: "queue",
            partial: "hands/queue/lists",
            locals: { hands: @domain.hands.open.order(:created_at), course_domain: @domain }
        )
    end

    def broadcast_widgets(changed_membership)
        affected_memberships(changed_membership).each do |membership|
            WidgetChannel.broadcast_to(membership, { html: WidgetRenderer.render(membership) })
        end
    end

    private

    # Everyone with an open hand (their position may have moved) plus the member
    # whose hand just changed (they may have just been helped or closed).
    def affected_memberships(changed_membership)
        memberships = @domain.hands.open.includes(:membership).map(&:membership)
        memberships << changed_membership if changed_membership
        memberships.uniq
    end
end
