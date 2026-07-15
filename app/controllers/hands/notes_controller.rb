class Hands::NotesController < ApplicationController
    include DomainScoped

    before_action :require_staff

    def index
        @notes = current_course_domain.notes.written.order(created_at: :desc)
            .includes(:membership, :author).limit(50)
            .to_a.reverse
    end

    def student
        @membership = current_course_domain.memberships.students.includes(:user).find(params[:id])
        @notes = @membership.notes.written.chronological.includes(:author)
    end

    def create
        membership = current_course_domain.memberships.find(params[:membership_id])
        note = current_course_domain.notes.new(
            membership: membership,
            author: current_membership,
            text: params[:text]
        )

        if note.save
            redirect_to domain_student_notes_path(current_course_domain.slug, membership.id)
        else
            redirect_to domain_student_notes_path(current_course_domain.slug, membership.id),
                alert: note.errors.full_messages.to_sentence
        end
    end
end
