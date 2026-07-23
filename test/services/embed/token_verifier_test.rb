require "test_helper"

class Embed::TokenVerifierTest < ActiveSupport::TestCase
    setup do
        @domain = course_domains(:algorithms)   # enrollment_open: true
        @closed = course_domains(:databases)     # enrollment_open: false
    end

    def token_for(domain, secret: domain.link_secret, **overrides)
        payload = {
            "email" => "widget.user@example.com",
            "name" => "Wanda Widget",
            "student_number" => "99887766",
            "slug" => domain.slug,
            "site_label" => "coursesite-a",
            "nonce" => SecureRandom.hex(8)
        }.merge(overrides.transform_keys(&:to_s))
        # The cleartext prefix and the encrypted payload carry the same slug, so
        # a slug: override moves both (the prefix is what selects the key).
        Embed::Token.encode(payload, secret, payload["slug"])
    end

    test "a valid token resolves to an auto-enrolled student membership" do
        result = Embed::TokenVerifier.call(token_for(@domain))
        assert result.ok?
        assert result.membership.student?
        assert_equal @domain, result.membership.course_domain
        assert_equal "coursesite-a", result.membership.source_label
        assert_equal "Wanda Widget", result.membership.user.name
    end

    test "the widget path enrolls even when self-join enrollment is closed" do
        result = Embed::TokenVerifier.call(token_for(@closed))
        assert result.ok?
        assert result.membership.student?
    end

    test "a wrong secret is rejected" do
        result = Embed::TokenVerifier.call(token_for(@domain, secret: "not-the-secret"))
        assert_equal "bad token", result.error
    end

    test "an unknown slug is rejected" do
        result = Embed::TokenVerifier.call(token_for(@domain, slug: "nope"))
        assert_equal "unknown domain", result.error
    end

    test "an expired token is rejected" do
        token = token_for(@domain)
        travel_to(Time.now + Embed::Token::TTL + 1) do
            assert_equal "bad token", Embed::TokenVerifier.call(token).error
        end
    end

    # The slug rides outside the ciphertext because it selects the key, so it is
    # the one field an attacker can actually reach. It is bound in as the AEAD
    # purpose: repointing it at another domain must not produce a usable token.
    test "a token whose cleartext slug is repointed at another domain is rejected" do
        token = token_for(@domain)
        _prefix, blob = token.split(".", 2)
        repointed = "#{Base64.urlsafe_encode64(@closed.slug, padding: false)}.#{blob}"
        assert_equal "bad token", Embed::TokenVerifier.call(repointed).error
    end

    # One domain's link_secret must never create a token another domain accepts.
    test "a token created with another domain's secret is rejected" do
        result = Embed::TokenVerifier.call(token_for(@domain, secret: @closed.link_secret))
        assert_equal "bad token", result.error
    end

    test "a token without a nonce is rejected rather than being freely replayable" do
        payload = {
            "email" => "no.nonce@example.com", "name" => "No Nonce",
            "student_number" => "1", "slug" => @domain.slug, "site_label" => "coursesite-a"
        }
        token = Embed::Token.encode(payload, @domain.link_secret, @domain.slug)
        assert_equal "replayed", Embed::TokenVerifier.call(token).error
    end

    test "a replayed nonce is rejected the second time" do
        token = token_for(@domain, nonce: "fixed-nonce-123")
        assert Embed::TokenVerifier.call(token).ok?
        assert_equal "replayed", Embed::TokenVerifier.call(token).error
    end

    test "a malformed token is rejected" do
        assert_equal "malformed token", Embed::TokenVerifier.call("garbage").error
    end

    test "an existing member keeps their role and membership" do
        existing = memberships(:student_algorithms)
        token = token_for(@domain, email: existing.user.email)
        result = Embed::TokenVerifier.call(token)
        assert_equal existing, result.membership
    end
end
