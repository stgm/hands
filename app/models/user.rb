class User < ApplicationRecord
    include Authenticatable

    has_many :memberships, dependent: :destroy
    has_many :course_domains, through: :memberships

    normalizes :email, with: ->(value) { value.to_s.strip.downcase }

    validates :email, presence: true, uniqueness: true

    # A person may hold a profile even before joining any domain; a "valid"
    # profile just means we know their name (needed to show them in a queue).
    def valid_profile?
        persisted? && name.present?
    end

    def display_name
        name.presence || email
    end

    def membership_in(course_domain)
        memberships.find_by(course_domain: course_domain)
    end
end
