class InvitationMailer < ApplicationMailer
    def invite
        @invitation = params[:invitation]
        @domain = @invitation.course_domain
        @url = accept_invitation_url(@invitation.token)
        mail to: @invitation.email, subject: "You're invited to help with #{@domain.name}"
    end
end
