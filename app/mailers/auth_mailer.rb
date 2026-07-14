class AuthMailer < ApplicationMailer
    def login_code
        @email = params[:email]
        @code = params[:code]
        mail to: @email, subject: "Your sign-in code"
    end
end
