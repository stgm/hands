class Hands::AttendanceController < ApplicationController
    include DomainScoped

    before_action :require_staff

    def index
        Presence.reap_stale!
        @present = current_course_domain.presences.active
            .includes(membership: :user)
            .sort_by { |p| [ p.location.to_s, p.membership.display_name ] }
    end
end
