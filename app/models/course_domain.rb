class CourseDomain < ApplicationRecord
    extend FriendlyId
    friendly_id :name, use: :slugged

    # Shared secret used by any linked course-site to sign embed tokens for
    # this domain. Rotatable; possession of it authorizes creating student tokens.
    has_secure_token :link_secret, length: 36

    # Attributes an admin may set through the course domain form.
    SETTABLE_ATTRIBUTES = [ :name, :enrollment_open, :location_type, :locale,
        :ask_location, :location_bumper, :link_mode ].freeze

    # The subset a teacher manages for their own course. Everything else keeps
    # its default and can only be changed by an admin.
    TEACHER_SETTABLE_ATTRIBUTES = [ :name, :location_type, :locale ].freeze

    belongs_to :created_by, class_name: "User", optional: true,
        inverse_of: :created_course_domains

    has_many :memberships, dependent: :destroy
    has_many :users, through: :memberships
    has_many :hands, dependent: :destroy
    has_many :notes, dependent: :destroy
    has_many :presences, dependent: :destroy
    has_many :invitations, dependent: :destroy

    validates :name, presence: true
    validates :slug, presence: true, uniqueness: true

    # Site admins manage every course; a teacher manages the one they created.
    def managed_by?(user)
        user.admin? || (created_by_id.present? && created_by_id == user.id)
    end

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

    # Groups are pure labelling and only come into being through a roster import,
    # so the group UI stays hidden until a course actually has them.
    def groups?
        memberships.grouped.exists?
    end

    def group_names
        memberships.grouped.distinct.pluck(:group).sort_by { |name| natural_sort_key(name) }
    end

    # Are there students without a group, i.e. is a "No group" tab meaningful?
    def ungrouped_students?
        memberships.students.where(group: nil).exists?
    end

    def membership_for(user)
        memberships.find_by(user: user)
    end

    def member?(user)
        memberships.exists?(user: user)
    end

    private

    # Sorts "Group 2" before "Group 10" by comparing digit runs as numbers.
    def natural_sort_key(name)
        name.downcase.scan(/\d+|\D+/).map { |chunk| chunk.match?(/\d/) ? [ 1, chunk.to_i, "" ] : [ 0, 0, chunk ] }
    end
end
