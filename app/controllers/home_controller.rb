class HomeController < ApplicationController
    def index
        return unless logged_in?

        @memberships = current_user.memberships.includes(:course_domain)
            .joins(:course_domain).order("course_domains.name")

        # A student with exactly one course has nothing else to do here — send
        # them straight to the assistance form instead of a one-item list.
        single = @memberships.first if @memberships.one?
        redirect_to domain_hand_path(single.course_domain.slug) if single && student_only?(single)
    end

    private

    def student_only?(membership)
        !current_user.admin? && !membership.staff?
    end
    helper_method :student_only?
end
