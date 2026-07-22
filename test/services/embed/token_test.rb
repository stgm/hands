require "test_helper"

class Embed::TokenTest < ActiveSupport::TestCase
    # The payload course-site sends. Key order no longer matters (nothing signs
    # raw JSON bytes any more), but the *set* of keys is the cross-repo contract.
    CANONICAL_PAYLOAD = {
        "email" => "a@b.com",
        "name" => "A B",
        "student_number" => "123",
        "slug" => "demo",
        "site_label" => "site-x",
        "locale" => "nl",
        "nonce" => "abc123"
    }.freeze
    VECTOR_SECRET = "shared-secret-vector".freeze

    # Regression guard for the wire format shared with course-site. Encryption is
    # non-deterministic (random IV), so unlike the old HMAC vector this cannot be
    # an encode-equality assertion. Instead it is a frozen ciphertext the decrypt
    # side MUST still accept: decryption *is* deterministic, so this catches drift
    # in key derivation, cipher choice, serializer and framing just as well.
    #
    # Minted at VECTOR_MINTED_AT; the TTL is baked into the encrypted metadata, so
    # the test has to travel back there or the fixture would expire.
    VECTOR_MINTED_AT = Time.utc(2026, 1, 1, 0, 0, 0)
    VECTOR_TOKEN =
        "ZGVtbw.aXLrL0M4Bpjex_85vR1WwY2mPgPmcl7Bfo-ZtIm7ytHeyfeG2vHnsNvefE7KBV0s2mLMookBabPB1rXUrLn80jhLN_j-DsJ2I_wE_joCSJXqegfqQmvllBgyqmHQmnVN4BHFH2jmqiHmuCNIIdxEGURh3w76Gr4UuT5GdwJe1ZsR7BQWBIUgWuSzFRbNWKKWOuUrtP1yOtPiXQGhA-SO7BI__N4pB0iJbi1xZ_cA1WqQbW-2YgneCtLjUcE--zqCj4c1b2ncowzI4--B9lMQ0r4prmzh2NdjAQO-w".freeze

    test "the shared vector still decrypts to the canonical payload" do
        travel_to VECTOR_MINTED_AT do
            assert_equal CANONICAL_PAYLOAD, Embed::Token.verify(VECTOR_TOKEN, VECTOR_SECRET, "demo")
        end
    end

    test "verify rejects a wrong secret" do
        travel_to VECTOR_MINTED_AT do
            assert_nil Embed::Token.verify(VECTOR_TOKEN, "wrong", "demo")
        end
    end

    test "verify rejects a mismatched purpose slug" do
        travel_to VECTOR_MINTED_AT do
            assert_nil Embed::Token.verify(VECTOR_TOKEN, VECTOR_SECRET, "other")
        end
    end

    test "verify rejects a tampered ciphertext" do
        travel_to VECTOR_MINTED_AT do
            prefix, blob = VECTOR_TOKEN.split(".", 2)
            assert_nil Embed::Token.verify("#{prefix}.#{blob.sub(/.\z/, 'x')}", VECTOR_SECRET, "demo")
        end
    end

    test "verify rejects the vector once the TTL has passed" do
        travel_to VECTOR_MINTED_AT + Embed::Token::TTL + 1 do
            assert_nil Embed::Token.verify(VECTOR_TOKEN, VECTOR_SECRET, "demo")
        end
    end

    test "read_slug reads the routing slug without a secret" do
        assert_equal "demo", Embed::Token.read_slug(VECTOR_TOKEN)
    end

    test "read_slug returns nil for a malformed token" do
        assert_nil Embed::Token.read_slug("garbage")
        assert_nil Embed::Token.read_slug("")
    end

    # The whole point of moving from signing to encrypting: the token travels in a
    # /cable?token=... query string, which reverse proxies log in full. Nothing
    # identifying may be recoverable from it without the secret.
    test "no identifying field is recoverable from the token without the secret" do
        token = Embed::Token.encode(CANONICAL_PAYLOAD, VECTOR_SECRET, "demo")
        decoded = token.split(".").filter_map do |part|
            begin
                Base64.urlsafe_decode64(part + ("=" * ((4 - part.length % 4) % 4)))
            rescue StandardError
                nil
            end
        end.join(" ")

        [ "a@b.com", "A B", "123", "site-x", "abc123" ].each do |identifying|
            assert_not_includes decoded, identifying
            assert_not_includes token, identifying
        end
    end

    test "round trips arbitrary payloads" do
        payload = { "email" => "x@y.z", "nonce" => SecureRandom.hex(6) }
        token = Embed::Token.encode(payload, "secret", "some-slug")
        assert_equal payload, Embed::Token.verify(token, "secret", "some-slug")
    end
end
