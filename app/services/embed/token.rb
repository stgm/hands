module Embed
    # The signed-token contract shared with every linked course-site.
    #
    # Wire format (compact, JWT-ish but dependency-free):
    #
    #     base64url(JSON payload) + "." + base64url(HMAC-SHA256(payload_b64, secret))
    #
    # The payload is a JSON object with string keys:
    #   email, name, student_number, slug, site_label, exp (unix seconds), nonce
    #
    # course-site mints these with a course domain's link_secret; the hands app
    # verifies with the same secret. Both sides MUST implement this identically —
    # the contract is covered by a shared test vector (see the token tests).
    module Token
        module_function

        def encode(payload, secret)
            body = base64url(JSON.generate(payload))
            "#{body}.#{signature(body, secret)}"
        end

        # Decode without verifying the signature — only to read the slug so we can
        # look up which secret to verify against. Never trust this result.
        def read_unverified(token)
            body, _sig = token.to_s.split(".", 2)
            JSON.parse(unbase64url(body))
        rescue StandardError
            nil
        end

        # Verify the signature with the given secret; returns the payload Hash or
        # nil. Constant-time comparison guards against timing attacks.
        def verify(token, secret)
            body, sig = token.to_s.split(".", 2)
            return nil if body.blank? || sig.blank?

            expected = signature(body, secret)
            return nil unless ActiveSupport::SecurityUtils.secure_compare(sig, expected)

            JSON.parse(unbase64url(body))
        rescue StandardError
            nil
        end

        def signature(body, secret)
            base64url(OpenSSL::HMAC.digest("SHA256", secret.to_s, body))
        end

        def base64url(bytes)
            Base64.urlsafe_encode64(bytes, padding: false)
        end

        def unbase64url(str)
            Base64.urlsafe_decode64(str + ("=" * ((4 - str.length % 4) % 4)))
        end
    end
end
