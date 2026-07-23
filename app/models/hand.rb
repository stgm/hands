class Hand < ApplicationRecord
    belongs_to :course_domain
    belongs_to :membership                                   # the student asking
    belongs_to :assist, class_name: "Membership",            # the staff helping
        foreign_key: :assist_membership_id, optional: true

    has_one :user, through: :membership

    scope :open,    -> { where(done: false) }
    scope :waiting, -> { open.where(assist_membership_id: nil) }
    scope :claimed, -> { open.where.not(assist_membership_id: nil) }
    scope :successfully_helped, -> { where(success: true) }

    # A student may only have one open hand at a time in a domain.
    validate :one_open_hand_per_member, on: :create

    # Raising a hand means the widget is open → count it as attendance.
    after_create :record_presence
    # Keep an audit trail of every state change, as course-site does.
    after_save :log_change
    # Push realtime updates to the queue and affected student widgets.
    after_commit :broadcast_updates

    def claim!(staff_membership)
        return false unless assist_membership_id.nil?

        update(assist: staff_membership, claimed_at: Time.current)
    end

    def release!
        update(assist_membership_id: nil, claimed_at: nil)
    end

    def close!(success:, evaluation: nil, note: nil)
        update(done: true, success: success, evaluation: evaluation, note: note, closed_at: Time.current)
    end

    def cancel!
        update(done: true, closed_at: Time.current)
    end

    def duration
        closed_at.present? && claimed_at.present? ? ((closed_at - claimed_at) / 60.0).round : 0
    end

    # Position in the waiting queue (1-based), or nil once claimed/closed.
    def queue_position
        return nil unless done? == false && assist_membership_id.nil?

        course_domain.hands.waiting.where("created_at < ?", created_at).count + 1
    end

    def formatted_request_time
        if self.created_at.today?
            self.created_at.to_fs(:time)
        else
            self.created_at.strftime("%a %H:%M")
        end
    end

    # Bulk-close waiting hands (e.g. an overnight sweep).
    def self.remove_all_stale
        waiting.update_all(
            done: true,
            evaluation: "Stale question removed from queue at night",
            closed_at: Time.current
        )
    end

    private

    def record_presence
        Presence.touch_open!(membership, source_label: source_label, location: location)
    end

    def broadcast_updates
        HandBroadcaster.new(course_domain).refresh(changed_membership: membership)
    end

    def log_change
        changed = previous_changes.except("updated_at", "created_at").keys
        return if changed.empty?

        course_domain.notes.create!(
            membership: membership,
            author: assist,
            log: true,
            text: "Hand ##{id}: #{changed.join(', ')}"
        )
    end

    def one_open_hand_per_member
        if membership && membership.hands.open.exists?
            errors.add(:base, "You already have an open question")
        end
    end
end
