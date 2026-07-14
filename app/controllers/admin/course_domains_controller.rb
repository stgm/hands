class Admin::CourseDomainsController < Admin::BaseController
    before_action :set_course_domain, only: [ :edit, :update, :destroy, :rotate_secret ]

    def index
        @course_domains = CourseDomain.order(:name)
    end

    def new
        @course_domain = CourseDomain.new
    end

    def create
        @course_domain = CourseDomain.new(course_domain_params)
        if @course_domain.save
            redirect_to admin_course_domains_path, notice: "Created #{@course_domain.name}"
        else
            render :new, status: :unprocessable_entity
        end
    end

    def edit
    end

    def update
        if @course_domain.update(course_domain_params)
            redirect_to admin_course_domains_path, notice: "Updated #{@course_domain.name}"
        else
            render :edit, status: :unprocessable_entity
        end
    end

    def destroy
        @course_domain.destroy
        redirect_to admin_course_domains_path, notice: "Deleted #{@course_domain.name}"
    end

    def rotate_secret
        @course_domain.rotate_link_secret!
        redirect_to edit_admin_course_domain_path(@course_domain), notice: "Link secret rotated"
    end

    private

    def set_course_domain
        @course_domain = CourseDomain.friendly.find(params[:id])
    end

    def course_domain_params
        params.require(:course_domain).permit(:name, :enrollment_open, :location_type, :locale,
            :ask_location, :location_bumper, :link_mode)
    end
end
