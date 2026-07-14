class Membership < ApplicationRecord
    belongs_to :user
    belongs_to :course_domain
    belongs_to :invited_by, class_name: "User", optional: true

    has_many :hands, dependent: :destroy
    has_many :claimed_hands, class_name: "Hand", foreign_key: :assist_membership_id, dependent: :nullify
    has_many :notes, dependent: :destroy                     # notes about this student
    has_many :authored_notes, class_name: "Note", foreign_key: :author_membership_id, dependent: :nullify
    has_many :presences, dependent: :destroy

    # Per-domain role. Parallels course-site's assistant/head split; "teacher"
    # is the senior staff role that can invite and manage other staff.
    enum :role, { student: 0, assistant: 1, teacher: 2 }, default: :student

    validates :user_id, uniqueness: { scope: :course_domain_id }

    scope :staff, -> { where(role: [ :assistant, :teacher ]) }
    scope :students, -> { where(role: :student) }
    scope :available, -> { where("available_until > ?", Time.current) }

    def staff?
        assistant? || teacher?
    end

    # Teachers are the senior staff (can manage staff/settings).
    def senior?
        teacher?
    end

    def available?
        available_until.present? && available_until > Time.current
    end

    def display_name
        user.display_name
    end

    # The language to render this student's widget in: whatever their source
    # course-site handed over, else the domain's own language.
    def effective_locale
        SafeLocale.resolve(locale, course_domain.locale)
    end
end
