class Hands::RaisesController < ApplicationController
    include DomainScoped
    include HandWidget

    before_action :require_member

    # GET /<slug>/hand — the student widget (full page in standalone mode)
    def show
        render_widget
    end

    # POST /<slug>/hand — raise a hand (or ask a new question)
    def create
        open_or_reuse_hand(
            subject: params[:subject],
            question: params[:question],
            location: params[:location],
            source_label: "standalone"
        )
        render_widget
    end

    # DELETE /<slug>/hand — cancel the current question (soft close)
    def destroy
        current_membership.hands.open.update_all(done: true, closed_at: Time.current)
        render_widget
    end

    # PATCH /<slug>/hand/set_location — check-in / remember the student's location
    def set_location
        if params[:location].present?
            current_membership.update(last_location: params[:location])
            current_membership.hands.open.first&.update(location: params[:location])
        end
        render_widget
    end
end
