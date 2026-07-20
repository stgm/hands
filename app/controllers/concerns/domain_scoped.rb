module DomainScoped
    extend ActiveSupport::Concern

    included do
        before_action :set_course_domain
        before_action :require_login
        before_action :set_membership
        before_action :set_locale
        helper_method :current_course_domain, :current_membership, :acting_staff?, :acting_senior?
    end

    private

    # Standalone pages render in the member's locale when we know it, else the
    # course domain's own language.
    def set_locale
        I18n.locale = @membership&.effective_locale || SafeLocale.resolve(@course_domain&.locale)
    end

    def set_course_domain
        @course_domain = CourseDomain.friendly.find(params[:course_domain_slug])
        Current.course_domain = @course_domain
    rescue ActiveRecord::RecordNotFound
        head :not_found
    end

    def current_course_domain
        @course_domain
    end

    # Standalone domain pages require a full login. Unlike the embed path
    # (token-authed), this uses the session cookie and remembers where to return
    # after signing in. The profile requirement is enforced globally by
    # Authentication#require_profile, which runs before this.
    def require_login
        return if logged_in?

        session[:return_to] = request.fullpath if request.get?
        redirect_to auth_mail_login_path
    end

    def set_membership
        @membership = current_user.membership_in(@course_domain)
        Current.membership = @membership
    end

    def current_membership
        @membership
    end

    def require_member
        redirect_to domain_root_path(@course_domain.slug) unless @membership
    end

    def require_staff
        head :forbidden unless acting_staff?
    end

    def require_senior
        head :forbidden unless acting_senior?
    end

    # Site-wide admins count as (senior) staff in every domain, matching
    # course-site where `admin?` was staff.
    def acting_staff?
        @membership&.staff? || current_user.admin?
    end

    def acting_senior?
        @membership&.senior? || current_user.admin?
    end

    # The membership credited when the current user takes a staff action. A
    # site-wide admin who isn't already staff here is enrolled as a teacher so
    # they can help and be recorded as the assisting staff member.
    def staff_membership!
        return @membership if @membership&.staff?
        return @membership unless current_user.admin?

        if @membership
            @membership.update!(role: :teacher)
        else
            @membership = @course_domain.memberships.create!(
                user: current_user, role: :teacher, source_label: "admin"
            )
        end
        Current.membership = @membership
        @membership
    end
end
