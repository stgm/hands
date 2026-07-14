class InvitationsController < ApplicationController
    before_action :authenticate
    before_action :set_invitation

    # Accept a staff invitation. Requires being logged in as the invitee (or any
    # logged-in user — we simply attach the invited role to that account).
    def accept
        if @invitation.nil?
            redirect_to root_path, alert: "That invitation is not valid"
            return
        end

        membership = @invitation.accept!(current_user)
        redirect_to domain_root_path(membership.course_domain.slug),
            notice: "You are now #{membership.role} of #{membership.course_domain.name}"
    end

    private

    def authenticate
        return if logged_in? && current_user.valid_profile?

        session[:return_to] = request.fullpath
        redirect_to logged_in? ? edit_profile_path : auth_mail_login_path
    end

    def set_invitation
        @invitation = Invitation.find_by(token: params[:token])
    end
end
