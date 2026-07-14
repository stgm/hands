module HandWidget
    extend ActiveSupport::Concern

    private

    # Create a fresh hand, or revive a recently-closed unsuccessful one (within
    # 30 minutes) so a student who was cut off keeps their place in spirit.
    # No-op when the member already has an open hand.
    def open_or_reuse_hand(subject:, question:, location:, source_label:)
        return if current_membership.hands.open.exists?

        reuse = current_membership.hands
            .where(done: true, success: false)
            .where("closed_at > ?", 30.minutes.ago)
            .order(:closed_at).last

        if reuse
            reuse.update(done: false, assist_membership_id: nil, claimed_at: nil, closed_at: nil,
                subject: subject, help_question: question, location: location)
        else
            current_membership.hands.create(course_domain: current_course_domain,
                subject: subject, help_question: question, location: location, source_label: source_label)
        end

        # Remember the location for pre-filling next time / attendance.
        current_membership.update(last_location: location) if location.present?
    end

    # Render the widget. A fetch from the widget Stimulus controller (flagged with
    # X-Widget-Fragment) gets the bare inner fragment to swap in; a normal request
    # gets the full standalone page. Live pushes come from HandBroadcaster.
    def render_widget
        @domain = current_course_domain
        @widget_state = WidgetState.for(current_membership)
        @source_label ||= "standalone"

        if request.headers["X-Widget-Fragment"].present?
            render partial: "hands/raises/widget", locals: @widget_state.locals, layout: false
        else
            render "hands/raises/show"
        end
    end
end
