class Embed::HandsController < Embed::BaseController
    include HandWidget # reuse open_or_reuse_hand

    # GET /embed/hand — the current widget fragment (course-site injects it)
    def show
        render_fragment
    end

    # POST /embed/hand — raise a hand from the widget
    def create
        open_or_reuse_hand(
            subject: params[:subject],
            question: params[:question],
            location: params[:location],
            source_label: current_membership.source_label
        )
        render_fragment
    end

    # DELETE /embed/hand — cancel the current question
    def destroy
        current_membership.hands.open.each(&:cancel!)
        render_fragment
    end

    # PATCH /embed/hand/set_location — check-in / remember the student's location
    def set_location
        if params[:location].present?
            current_membership.update(last_location: params[:location])
            current_membership.hands.open.first&.update(location: params[:location])
        end
        render_fragment
    end

    private

    # Bare widget fragment (no layout, no page chrome). Live updates arrive over
    # the cross-origin WidgetChannel that course-site's JS subscribes to.
    def render_fragment
        state = WidgetState.for(current_membership)
        render partial: "hands/raises/widget", locals: state.locals, layout: false
    end
end
