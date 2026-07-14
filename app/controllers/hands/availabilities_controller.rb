class Hands::AvailabilitiesController < ApplicationController
    include DomainScoped

    before_action :require_staff

    def edit
    end

    def update
        minutes = params[:minutes].to_i
        staff_membership!&.update(available_until: minutes.positive? ? minutes.minutes.from_now : nil)
        redirect_to domain_queue_hands_path(current_course_domain.slug)
    end
end
