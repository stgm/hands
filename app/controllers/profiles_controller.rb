class ProfilesController < ApplicationController
    skip_before_action :require_profile
    before_action :authenticate

    def edit
        @user = current_user
    end

    def update
        @user = current_user
        if @user.update(profile_params)
            redirect_to after_sign_in_path, notice: "Profile saved"
        else
            render :edit, status: :unprocessable_entity
        end
    end

    private

    def profile_params
        params.require(:user).permit(:name, :student_number)
    end
end
