class Rack::Attack
    # Tests share one IP and log in many times; throttling would break them (and
    # it isn't the subject under test). The nonce replay-protection still uses the
    # real test cache — only rate limiting is off here.
    Rack::Attack.enabled = false if Rails.env.test?

    # Throttle email requests: prevent inbox flooding. 5 per IP per minute.
    throttle("auth/mail/create", limit: 5, period: 1.minute) do |req|
        req.ip if req.path == "/auth/mail/create" && req.post?
    end

    # Throttle OTP validation: the 24-bit code space needs brute-force protection.
    throttle("auth/mail/validate", limit: 5, period: 1.minute) do |req|
        req.ip if req.path == "/auth/mail/validate" && req.post?
    end

    # Throttle embed token minting on the hands side is unnecessary (course-site
    # holds the secret); the cross-origin embed endpoints are protected by the
    # signed token itself.

    self.throttled_responder = lambda do |_req|
        [ 429, { "Content-Type" => "text/plain" }, [ "Too many requests. Please try again later." ] ]
    end
end
