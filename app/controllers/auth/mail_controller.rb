class Auth::MailController < ApplicationController
    # Login by email using a one-time code (ported from course-site).

    layout "auth"

    def self.available?
        !Auth::OpenController.available? || Settings.login_by_email
    end

    def login
        # email address form
    end

    def create
        entry = params[:email].to_s.downcase.strip
        begin
            parsed = Mail::Address.new(entry)
        rescue Mail::Field::ParseError
            redirect_to auth_mail_login_path, alert: "Email seems invalid" and return
        end
        if parsed.address != entry || parsed.domain.nil? || parsed.domain.split(".").length <= 1
            redirect_to auth_mail_login_path, alert: "Email seems invalid" and return
        end

        session[:login_email] = entry
        # 6-hex-digit code, stored only as a SHA256 hash with an issue time
        code = SecureRandom.hex(3)
        session[:login_secret] = Digest::SHA256.hexdigest(code)
        session[:login_secret_at] = Time.now.to_i
        AuthMailer.with(email: entry, code: code).login_code.deliver_later
        redirect_to auth_mail_code_path
    end

    def code
        # secret code form
    end

    def validate
        if params[:code].to_s.size == 6
            if login_code_expired?
                clear_login_session
                redirect_to auth_mail_login_path, alert: "Code expired, please request a new one" and return
            end

            if session[:login_secret] == Digest::SHA256.hexdigest(params[:code])
                email = session[:login_email]
                clear_login_session
                if user = User.authenticate(email: email)
                    sign_in(user)
                    redirect_to after_sign_in_path
                else
                    redirect_to root_path, alert: "Could not sign you in"
                end
            else
                # invalidate the code on any wrong attempt
                clear_login_session
                redirect_to auth_mail_login_path, alert: "Invalid code, please request a new one"
            end
        else
            clear_login_session
            redirect_to root_path
        end
    end

    private

    def login_code_expired?
        session[:login_secret_at].blank? || (Time.now.to_i - session[:login_secret_at].to_i) > 15.minutes
    end

    def clear_login_session
        session.delete(:login_secret)
        session.delete(:login_secret_at)
        session.delete(:login_email)
    end
end
