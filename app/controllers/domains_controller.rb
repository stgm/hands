class DomainsController < ApplicationController
    include DomainScoped

    before_action :require_staff, only: [ :invite ]

    # Landing page for a course domain at /<slug>. Members see their entry
    # points (ask a question, and staff tools); non-members see a join prompt.
    def show
    end

    # The link staff hand to students (by email, or in the course site). It is
    # just the domain landing page: students sign in there and join.
    def invite
        @invite_url = domain_root_url(@course_domain.slug)
    end

    # Self-join from the standalone domain URL. Gated by enrollment_open in the
    # model; the widget path (embed) enrolls separately and is always open.
    def join
        if current_membership
            redirect_to domain_root_path(@course_domain.slug)
        elsif membership = @course_domain.self_join!(current_user, source_label: "standalone")
            redirect_to domain_root_path(@course_domain.slug), notice: "You joined #{@course_domain.name}"
        else
            redirect_to domain_root_path(@course_domain.slug), alert: "Enrollment for #{@course_domain.name} is closed"
        end
    end
end
