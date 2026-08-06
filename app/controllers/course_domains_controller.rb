# Course creation and settings for teachers. A teacher (recognised by their
# email domain) may create one course for themselves and manage that course;
# every further course is created for them by a site admin through
# Admin::CourseDomainsController.
class CourseDomainsController < ApplicationController
    before_action :authorize
    before_action :require_creation_allowed, only: [ :new, :create ]
    before_action :set_course_domain, only: [ :edit, :update ]

    def new
        @course_domain = CourseDomain.new
    end

    def create
        @course_domain = CourseDomain.new(course_domain_params)
        @course_domain.created_by = current_user

        saved = CourseDomain.transaction do
            next false unless @course_domain.save

            @course_domain.memberships.create!(
                user: current_user, role: :teacher, source_label: "creator"
            )
            true
        end

        if saved
            redirect_to domain_root_path(@course_domain.slug), notice: "Created #{@course_domain.name}"
        else
            render :new, status: :unprocessable_entity
        end
    end

    def edit
    end

    def update
        if @course_domain.update(course_domain_params)
            redirect_to domain_root_path(@course_domain.slug), notice: "Updated #{@course_domain.name}"
        else
            render :edit, status: :unprocessable_entity
        end
    end

    private

    def require_creation_allowed
        head :forbidden unless current_user.may_create_course?
    end

    def set_course_domain
        @course_domain = CourseDomain.friendly.find(params[:id])
        head :forbidden unless @course_domain.managed_by?(current_user)
    rescue ActiveRecord::RecordNotFound
        head :not_found
    end

    def course_domain_params
        params.require(:course_domain).permit(*CourseDomain::TEACHER_SETTABLE_ATTRIBUTES)
    end
end
