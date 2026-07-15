class Hands::AttendanceController < ApplicationController
    include DomainScoped

    before_action :require_staff

    def index
        Presence.reap_stale!
        @students = current_course_domain.memberships.students.includes(:user)
            .sort_by(&:display_name)
        @presences_by_membership = current_course_domain.presences.active
            .includes(:membership).group_by(&:membership_id)
    end
end
