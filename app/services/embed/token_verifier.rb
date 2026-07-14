module Embed
    # Verifies an embed token end-to-end and resolves it to a Membership,
    # auto-enrolling the student in the target domain (widget path is always
    # open, regardless of enrollment_open).
    class TokenVerifier
        Result = Struct.new(:membership, :error, keyword_init: true) do
            def ok?
                error.nil?
            end
        end

        # Allow a little clock skew between the two servers.
        LEEWAY = 30

        def self.call(token)
            new(token).call
        end

        def initialize(token)
            @token = token
        end

        def call
            unverified = Token.read_unverified(@token) or return fail!("malformed token")
            domain = CourseDomain.find_by(slug: unverified["slug"]) or return fail!("unknown domain")
            payload = Token.verify(@token, domain.link_secret) or return fail!("bad signature")
            return fail!("expired") if expired?(payload)
            return fail!("replayed") unless fresh_nonce?(payload)

            user = User.authenticate(
                email: payload["email"],
                name: payload["name"],
                student_number: payload["student_number"]
            )
            return fail!("no email") unless user

            membership = domain.enroll_via_widget!(user, source_label: payload["site_label"].presence)
            remember_locale(membership, payload["locale"])
            Result.new(membership: membership)
        end

        private

        # The source course-site hands over its language setting. Store it so that
        # realtime broadcasts (which have no request context) also speak it.
        def remember_locale(membership, locale)
            return if locale.blank? || !SafeLocale.supported?(locale)
            return if membership.locale == locale.to_s

            membership.update(locale: locale.to_s)
        end

        def expired?(payload)
            exp = payload["exp"].to_i
            exp.zero? || exp < (Time.now.to_i - LEEWAY)
        end

        # Single-use nonce, held in the cache for the token's plausible lifetime.
        # A blank nonce is allowed (older callers) but course-site always sends one.
        def fresh_nonce?(payload)
            nonce = payload["nonce"].to_s
            return true if nonce.blank?

            Rails.cache.write("embed:nonce:#{nonce}", true, unless_exist: true, expires_in: 10.minutes)
        end

        def fail!(message)
            Result.new(error: message)
        end
    end
end
