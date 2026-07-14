module User::Authenticatable
    extend ActiveSupport::Concern

    class_methods do
        def find_by_email(email)
            find_by(email: email.to_s.strip.downcase)
        end

        # Find or create a global account for an authenticated identity.
        #
        # Unlike course-site there is no global registration gate: anyone who
        # can authenticate (OIDC or email code) gets an account. Access to a
        # particular course domain is governed separately by Membership. The
        # very first account created becomes the site-wide admin.
        def authenticate(user_data)
            data = user_data.symbolize_keys
            email = data[:email].to_s.strip.downcase
            return false if email.blank?

            attrs = data.slice(:name, :student_number, :login).compact_blank

            if user = find_by_email(email)
                user.update(attrs) if attrs.any?
                user
            else
                create!(attrs.merge(email: email, admin: none?))
            end
        end
    end
end
