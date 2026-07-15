class Hands::QueueController < ApplicationController
    include DomainScoped

    before_action :require_staff
    before_action :require_availability, only: :index
    before_action :load_hand, only: [ :show, :claim, :done, :helpline ]

    # GET /<slug>/queue — the staff queue (all open hands, viewer-independent)
    def index
        @hands = current_course_domain.hands.open.order(:created_at)
    end

    # GET /<slug>/queue/:id — the request detail page. Opening a request
    # auto-claims it for assistants (as in course-site); seniors/admins use the
    # explicit "Start helping" button.
    def show
        if current_membership&.assistant? && @hand.assist_membership_id.nil? && !@hand.helpline?
            unless @hand.claim!(current_membership)
                redirect_to domain_queue_hands_path(current_course_domain.slug), alert: "Someone was ahead of you" and return
            end
        end
    end

    # PUT /<slug>/hands/:id/claim — manual claim (seniors/admins/assistants)
    def claim
        @hand.claim!(staff_membership!)
        redirect_to domain_queue_hand_path(current_course_domain.slug, @hand)
    end

    # PUT /<slug>/hands/:id/done — close a hand with an outcome
    def done
        @hand.close!(
            success: ActiveModel::Type::Boolean.new.cast(params[:success]),
            evaluation: params[:evaluation],
            note: params[:note]
        )
        redirect_to domain_queue_hands_path(current_course_domain.slug)
    end

    # PUT /<slug>/hands/:id/helpline — send back to the queue as a "helpline" item
    def helpline
        @hand.update(helpline: true, assist_membership_id: nil, claimed_at: nil)
        redirect_to domain_queue_hands_path(current_course_domain.slug)
    end

    private

    def load_hand
        @hand = current_course_domain.hands.find(params[:id])
    end

    def require_availability
        return if acting_senior? || current_membership&.available?

        redirect_to edit_domain_availability_path(current_course_domain.slug)
    end
end
