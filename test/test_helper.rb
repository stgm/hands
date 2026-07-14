ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
    class TestCase
        # Run tests in parallel with specified workers
        parallelize(workers: :number_of_processors)

        # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
        fixtures :all
    end
end

class ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    # Drive the real email one-time-code flow to sign a user in. Reads the code
    # straight from the delivered mail so no stubbing is needed.
    def sign_in_as(user)
        perform_enqueued_jobs do
            post auth_mail_create_path, params: { email: user.email }
        end
        post auth_mail_validate_path, params: { code: latest_login_code }
        follow_redirect!
    end

    def latest_login_code
        mail = ActionMailer::Base.deliveries.last
        mail.body.to_s[/code is: (\w{6})/, 1]
    end
end
