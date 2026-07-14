# Drives the student widget in real time AND records "widget open" attendance:
# the lifetime of this subscription is the presence. Works for both the
# standalone page (session-authenticated connection) and the cross-domain embed
# (token-authenticated connection sets current_membership directly).
class WidgetChannel < ApplicationCable::Channel
    def subscribed
        @membership = resolve_membership
        return reject unless @membership

        @source_label = params[:source_label].presence
        stream_for @membership
        Presence.touch_open!(@membership, source_label: @source_label)
        # No initial transmit: the page (or embed fetch) already holds the current
        # widget with a valid CSRF token. Live updates come from broadcasts.
    end

    # Periodic client heartbeat so the reaper keeps live widgets marked present.
    def appear
        Presence.touch_open!(@membership, source_label: @source_label) if @membership
    end

    def unsubscribed
        Presence.close!(@membership, source_label: @source_label) if @membership
    end

    private

    def resolve_membership
        return current_membership if current_membership # embed (token) connection

        domain = CourseDomain.find_by(slug: params[:domain])
        domain && current_user&.membership_in(domain)
    end
end
