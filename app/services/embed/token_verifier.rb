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

        def self.call(token)
            new(token).call
        end

        def initialize(token)
            @token = token
        end

        def call
            slug = Token.read_slug(@token) or return fail!("malformed token")
            domain = CourseDomain.find_by(slug: slug) or return fail!("unknown domain")
            # One step covers tampering, a swapped slug and expiry: the slug is
            # bound in as the AEAD purpose and the TTL rides in the metadata.
            payload = Token.verify(@token, domain.link_secret, slug) or return fail!("bad token")
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

        # Single-use nonce, held in the cache well past the token's lifetime.
        # Required, not optional: a token reaching us without one would be freely
        # replayable for its whole TTL by anyone who scraped it out of a proxy
        # access log, which is the exact exposure the encrypted format is here to
        # shut down. (Tolerating a blank nonce made sense only while pre-v2
        # callers existed; the format break retired those.)
        def fresh_nonce?(payload)
            nonce = payload["nonce"].to_s
            return false if nonce.blank?

            Rails.cache.write("embed:nonce:#{nonce}", true, unless_exist: true, expires_in: 10.minutes)
        end

        def fail!(message)
            Result.new(error: message)
        end
    end
end
