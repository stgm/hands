class StaffController < ApplicationController
    include DomainScoped

    before_action :require_senior
    before_action :load_member, only: [ :update, :destroy ]

    def index
        @staff = current_course_domain.memberships.staff.includes(:user)
        @pending = current_course_domain.invitations.pending.order(:created_at)
        @student_count = current_course_domain.memberships.students.count
        @invitation = Invitation.new
    end

    def update
        @member.update(role: params[:role])
        redirect_to domain_staff_path(current_course_domain.slug), notice: "Role updated"
    end

    def destroy
        @member.destroy
        redirect_to domain_staff_path(current_course_domain.slug), notice: "Removed from staff"
    end

    private

    def load_member
        @member = current_course_domain.memberships.find(params[:id])
    end
end
