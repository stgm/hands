class Current < ActiveSupport::CurrentAttributes
    # The globally authenticated person (nil/unpersisted when anonymous).
    attribute :user
    # The course domain resolved from the request (slug route or embed token).
    attribute :course_domain
    # The membership tying the current user to the current course domain.
    attribute :membership
end
