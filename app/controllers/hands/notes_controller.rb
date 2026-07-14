class Hands::NotesController < ApplicationController
    include DomainScoped

    before_action :require_staff

    def index
        @members = current_course_domain.memberships.students.joins(:user).includes(:user).order("users.name")
        @notes = current_course_domain.notes.written.chronological.includes(:membership, :author)
    end

    def create
        membership = current_course_domain.memberships.find(params[:membership_id])
        current_course_domain.notes.create!(
            membership: membership,
            author: current_membership,
            text: params[:text]
        )
        redirect_to domain_notes_path(current_course_domain.slug), notice: "Note saved"
    end
end
