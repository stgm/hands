class CourseDomain < ApplicationRecord
    extend FriendlyId
    friendly_id :name, use: :slugged

    # Shared secret used by any linked course-site to sign embed tokens for
    # this domain. Rotatable; possession of it authorizes creating student tokens.
    has_secure_token :link_secret, length: 36

    has_many :memberships, dependent: :destroy
    has_many :users, through: :memberships
    has_many :hands, dependent: :destroy
    has_many :notes, dependent: :destroy
    has_many :presences, dependent: :destroy
    has_many :invitations, dependent: :destroy

    validates :name, presence: true
    validates :slug, presence: true, uniqueness: true

    def rotate_link_secret!
        regenerate_link_secret
    end

    # Arriving through a linked course-site widget always enrolls the user as a
    # student, regardless of enrollment_open (the widget path is always open).
    def enroll_via_widget!(user, source_label:)
        membership_for(user) || memberships.create!(user: user, role: :student, source_label: source_label)
    end

    # Self-join from the standalone domain URL is gated by enrollment_open.
    # Returns the (existing or new) membership, or nil when enrollment is closed.
    def self_join!(user, source_label: nil)
        return membership_for(user) if member?(user)
        return nil unless enrollment_open?

        memberships.create!(user: user, role: :student, source_label: source_label)
    end

    def membership_for(user)
        memberships.find_by(user: user)
    end

    def member?(user)
        memberships.exists?(user: user)
    end
end
