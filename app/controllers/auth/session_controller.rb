class Auth::SessionController < ApplicationController
    skip_before_action :require_profile

    def destroy
        sign_out
        redirect_to root_path
    end
end
