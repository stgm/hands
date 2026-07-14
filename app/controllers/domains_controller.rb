class DomainsController < ApplicationController
    include DomainScoped

    # Landing page for a course domain at /<slug>. Members see their entry
    # points (ask a question, and staff tools); non-members see a join prompt.
    def show
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
