class Note < ApplicationRecord
    belongs_to :course_domain
    belongs_to :membership                                   # the student the note is about
    belongs_to :author, class_name: "Membership",            # the staff member who wrote it
        foreign_key: :author_membership_id, optional: true

    has_rich_text :text

    scope :written,     -> { where(log: false) }
    scope :log_entries, -> { where(log: true) }
    scope :chronological, -> { order(:created_at) }
end
