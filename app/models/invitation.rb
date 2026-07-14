class Invitation < ApplicationRecord
    belongs_to :course_domain
    belongs_to :invited_by, class_name: "User", optional: true

    has_secure_token :token

    # Invitations are for staff roles only.
    enum :role, { assistant: 1, teacher: 2 }, default: :assistant

    normalizes :email, with: ->(value) { value.to_s.strip.downcase }

    validates :email, presence: true

    scope :pending, -> { where(accepted_at: nil) }

    def pending?
        accepted_at.nil?
    end

    # Turn the invitation into a membership for the given user, upgrading an
    # existing membership's role if needed. Idempotent once accepted.
    def accept!(user)
        return course_domain.membership_for(user) unless pending?

        membership = course_domain.membership_for(user) ||
            course_domain.memberships.build(user: user)
        membership.role = role
        membership.invited_by ||= invited_by
        membership.save!
        update!(accepted_at: Time.current)
        membership
    end
end
