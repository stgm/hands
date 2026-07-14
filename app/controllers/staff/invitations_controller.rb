class Staff::InvitationsController < ApplicationController
    include DomainScoped

    before_action :require_senior

    def create
        invitation = current_course_domain.invitations.pending.find_or_initialize_by(email: params[:email].to_s.strip.downcase)
        invitation.assign_attributes(role: params[:role].presence || "assistant", invited_by: current_user)
        if invitation.save
            InvitationMailer.with(invitation: invitation).invite.deliver_later
            redirect_to domain_staff_path(current_course_domain.slug), notice: "Invitation sent to #{invitation.email}"
        else
            redirect_to domain_staff_path(current_course_domain.slug), alert: invitation.errors.full_messages.to_sentence
        end
    end

    def destroy
        current_course_domain.invitations.find(params[:id]).destroy
        redirect_to domain_staff_path(current_course_domain.slug), notice: "Invitation withdrawn"
    end
end
