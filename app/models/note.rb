class Note < ApplicationRecord
    belongs_to :course_domain
    belongs_to :membership                                   # the student the note is about
    belongs_to :author, class_name: "Membership",            # the staff member who wrote it
        foreign_key: :author_membership_id, optional: true

    has_rich_text :text

    validate :text_must_be_present

    scope :written,     -> { where(log: false) }
    scope :log_entries, -> { where(log: true) }
    scope :chronological, -> { order(:created_at) }

    private

    # Rich text is never a blank string even when empty (Trix wraps it in
    # markup), so presence has to be checked against the plain-text content.
    def text_must_be_present
        errors.add(:text, "can't be blank") if text.blank? || text.to_plain_text.blank?
    end
end
