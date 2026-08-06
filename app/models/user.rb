class User < ApplicationRecord
    include Authenticatable

    # Email domains whose members are staff rather than students. Matched
    # exactly, so student.uva.nl (a different domain) is not a teacher domain.
    TEACHER_EMAIL_DOMAINS = %w[uva.nl].freeze

    has_many :memberships, dependent: :destroy
    has_many :course_domains, through: :memberships
    has_many :created_course_domains, class_name: "CourseDomain",
        foreign_key: :created_by_id, dependent: :nullify, inverse_of: :created_by

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

    def teacher?
        TEACHER_EMAIL_DOMAINS.include?(email.to_s.split("@").last)
    end

    # A teacher may set up a single course for themselves; anything beyond that
    # is created for them by a site admin.
    def may_create_course?
        return false unless persisted?

        admin? || (teacher? && created_course_domains.none?)
    end

    def membership_in(course_domain)
        memberships.find_by(course_domain: course_domain)
    end
end
