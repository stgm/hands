require "test_helper"

class UserTest < ActiveSupport::TestCase
    test "email is normalized to stripped lowercase" do
        user = User.create!(email: "  Foo@Example.COM ")
        assert_equal "foo@example.com", user.email
    end

    test "email must be unique" do
        User.create!(email: "dup@example.com")
        assert_raises(ActiveRecord::RecordInvalid) { User.create!(email: "dup@example.com") }
    end

    test "email is required" do
        assert_not User.new(email: "").valid?
    end

    test "valid_profile? requires persistence and a name" do
        assert_not User.new(email: "x@example.com").valid_profile?
        assert_not User.create!(email: "noname@example.com").valid_profile?
        assert users(:student).valid_profile?
    end

    test "display_name falls back to email" do
        assert_equal "Sam Student", users(:student).display_name
        assert_equal "noname@example.com", User.create!(email: "noname@example.com").display_name
    end

    test "authenticate finds an existing user and refreshes profile fields" do
        found = User.authenticate(email: "STUDENT@example.com", name: "Sam Renamed")
        assert_equal users(:student), found
        assert_equal "Sam Renamed", found.reload.name
    end

    test "authenticate creates a new user when unknown" do
        assert_difference -> { User.count }, 1 do
            user = User.authenticate(email: "brand.new@example.com", name: "New Person")
            assert user.persisted?
            assert_equal "new person".titleize, user.name
        end
    end

    test "authenticate returns false without an email" do
        assert_equal false, User.authenticate(name: "Nobody")
    end

    test "first ever account becomes the site admin" do
        Membership.delete_all
        User.delete_all
        first = User.authenticate(email: "first@example.com", name: "First")
        assert first.admin?
        second = User.authenticate(email: "second@example.com", name: "Second")
        assert_not second.admin?
    end
end
