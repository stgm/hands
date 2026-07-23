module Embed
    # The encrypted-token contract shared with every linked course-site.
    #
    # Wire format:
    #
    #     base64url(slug) + "." + MessageEncryptor blob (url_safe base64)
    #
    # The slug travels in the clear because it is what *selects* the key: the
    # verifier has to know which CourseDomain's link_secret to decrypt with
    # before it can decrypt anything. It is bound into the AEAD as the message
    # purpose, so swapping it invalidates the token.
    #
    # Everything else is encrypted. The payload is a JSON object with string keys:
    #   email, name, student_number, slug, site_label, locale, nonce
    #
    # Encrypting rather than merely signing matters because the token travels in a
    # WebSocket query string (/cable?token=...). Rails filters :token from its own
    # logs, but the reverse proxy in front of this app logs full request URIs, and
    # a signed-only payload would put every student's email, name and student
    # number in those logs in plainly decodable base64.
    #
    # course-site creates these with a course domain's link_secret; the hands app
    # decrypts with the same secret. Both sides MUST implement this identically —
    # the contract is covered by a frozen ciphertext fixture (see the token tests).
    module Token
        # 120s of usable lifetime plus 30s of clock skew between the two servers.
        # MessageEncryptor's expiry has no leeway of its own, so a verifier whose
        # clock runs ahead would otherwise reject a freshly created token.
        TTL = 150

        # HKDF, not ActiveSupport::KeyGenerator: link_secret is already a 36-char
        # has_secure_token, so PBKDF2's stretching buys nothing and would cost
        # ~50ms on every create and every verify.
        HKDF_SALT = "hands-embed".freeze
        HKDF_INFO = "aes-256-gcm-v2".freeze

        module_function

        def encode(payload, secret, slug)
            "#{base64url(slug.to_s)}.#{encryptor(secret).encrypt_and_sign(payload, purpose: slug.to_s, expires_in: TTL)}"
        end

        # Read the slug without decrypting — only to look up which secret to verify
        # against. Never trust this on its own; verify binds it as the purpose.
        def read_slug(token)
            prefix, blob = token.to_s.split(".", 2)
            return nil if prefix.blank? || blob.blank?

            unbase64url(prefix)
        rescue StandardError
            nil
        end

        # Decrypt and authenticate with the given secret; returns the payload Hash
        # or nil. Covers tampering, expiry and a swapped slug in one step.
        def verify(token, secret, slug)
            _prefix, blob = token.to_s.split(".", 2)
            return nil if blob.blank?

            encryptor(secret).decrypt_and_verify(blob, purpose: slug.to_s)
        rescue StandardError
            nil
        end

        # serializer: JSON is pinned deliberately. MessageEncryptor's default
        # serializer follows each app's config.load_defaults (this app is on 8.1,
        # course-site on 8.0), so leaving it implicit would make the wire format
        # depend on two Rails versions agreeing. JSON also keeps Marshal out of
        # the decrypt path entirely.
        def encryptor(secret)
            ActiveSupport::MessageEncryptor.new(
                derive_key(secret), cipher: "aes-256-gcm", serializer: JSON, url_safe: true
            )
        end

        # Memoized: the same handful of secrets are used over and over.
        def derive_key(secret)
            @keys ||= {}
            @keys[secret.to_s] ||=
                OpenSSL::KDF.hkdf(secret.to_s, salt: HKDF_SALT, info: HKDF_INFO, length: 32, hash: "SHA256")
        end

        def base64url(bytes)
            Base64.urlsafe_encode64(bytes, padding: false)
        end

        def unbase64url(str)
            Base64.urlsafe_decode64(str + ("=" * ((4 - str.length % 4) % 4)))
        end
    end
end
