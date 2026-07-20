class Auth::OpenController < ApplicationController
    # Login by OpenID Connect as configured in the environment (ported from
    # course-site). Disabled unless the OIDC_* env vars are present.

    def self.available?
        ENV["OIDC_CLIENT_ID"].present? &&
            ENV["OIDC_CLIENT_SECRET"].present? &&
            ENV["OIDC_HOST"].present?
    end

    def login
        redirect_to authorization_uri, allow_other_host: true
    end

    def callback
        redirect_to(root_path) && return if params[:error] == "access_denied"

        # verify state to prevent CSRF on the OAuth flow
        unless params[:state].present? && params[:state] == session.delete(:oidc_state)
            redirect_to root_path, alert: "Could not sign you in" and return
        end

        client.authorization_code = params[:code]

        begin
            access_token = client.access_token!
        rescue Rack::OAuth2::Client::Error
            head(500) and return
        end

        info = user_info(access_token.access_token)

        user_data = {
            login: info.subject.to_s.downcase,
            email: info.email.to_s.downcase,
            name: info.nickname.to_s.gsub(/\A\.\ /, ""),
            student_number: extract_student_number(info)
        }

        if user = User.authenticate(user_data)
            sign_in(user)
            redirect_to after_sign_in_path
        else
            redirect_to root_path, alert: "Could not sign you in"
        end
    end

    private

    def extract_student_number(info)
        info.raw_attributes["schac_personal_unique_code"].try(:first).try do |urn|
            urn.match(/urn:schac:personalUniqueCode:nl:local:uva.nl:studentid:(.*)/).try { |m| m[1] }
        end
    end

    def client
        @client ||= OpenIDConnect::Client.new(
            identifier: ENV["OIDC_CLIENT_ID"],
            secret: ENV["OIDC_CLIENT_SECRET"],
            redirect_uri: auth_open_callback_url,
            host: ENV["OIDC_HOST"],
            authorization_endpoint: "/oidc/authorize",
            token_endpoint: "/oidc/token",
            userinfo_endpoint: "/oidc/userinfo"
        )
    end

    def authorization_uri
        session[:oidc_state] = SecureRandom.hex(16)
        client.authorization_uri(scope: scope, state: session[:oidc_state])
    end

    # SURFconext rejects scopes that are not registered on the client. The other
    # proglab apps request only "openid", so match that by default; override via
    # OIDC_SCOPE (space-separated) once extra scopes are registered.
    def scope
        ENV.fetch("OIDC_SCOPE", "openid").split
    end

    def user_info(token)
        return nil unless token.present?

        OpenIDConnect::AccessToken.new(access_token: token, client: client).userinfo!
    end
end
