require "test_helper"

class Embed::TokenTest < ActiveSupport::TestCase
    # Canonical payload key order for the cross-repo contract. course-site MUST
    # build the payload in this exact order so the signed body bytes match.
    CANONICAL_PAYLOAD = {
        "email" => "a@b.com",
        "name" => "A B",
        "student_number" => "123",
        "slug" => "demo",
        "site_label" => "site-x",
        "locale" => "nl",
        "exp" => 1_893_456_000,
        "nonce" => "abc123"
    }.freeze
    VECTOR_SECRET = "shared-secret-vector".freeze

    # Regression guard for the wire format shared with course-site. If this
    # changes, the two apps have drifted and embedding will break.
    VECTOR_TOKEN =
        "eyJlbWFpbCI6ImFAYi5jb20iLCJuYW1lIjoiQSBCIiwic3R1ZGVudF9udW1iZXIiOiIxMjMiLCJzbHVnIjoiZGVtbyIsInNpdGVfbGFiZWwiOiJzaXRlLXgiLCJsb2NhbGUiOiJubCIsImV4cCI6MTg5MzQ1NjAwMCwibm9uY2UiOiJhYmMxMjMifQ.IfA-2ONEfR9me0KtKQcRismoIxos_13B2-8XUTLk2U0".freeze

    test "encoding the canonical payload matches the shared vector" do
        assert_equal VECTOR_TOKEN, Embed::Token.encode(CANONICAL_PAYLOAD, VECTOR_SECRET)
    end

    test "verify accepts the shared vector and returns the payload" do
        assert_equal CANONICAL_PAYLOAD, Embed::Token.verify(VECTOR_TOKEN, VECTOR_SECRET)
    end

    test "verify rejects a wrong secret" do
        assert_nil Embed::Token.verify(VECTOR_TOKEN, "wrong")
    end

    test "verify rejects a tampered body" do
        body, sig = VECTOR_TOKEN.split(".")
        tampered = "#{body}x.#{sig}"
        assert_nil Embed::Token.verify(tampered, VECTOR_SECRET)
    end

    test "read_unverified reads the payload without a secret" do
        assert_equal "demo", Embed::Token.read_unverified(VECTOR_TOKEN)["slug"]
    end

    test "round trips arbitrary payloads" do
        payload = { "email" => "x@y.z", "exp" => Time.now.to_i, "nonce" => SecureRandom.hex(6) }
        token = Embed::Token.encode(payload, "secret")
        assert_equal payload, Embed::Token.verify(token, "secret")
    end
end
