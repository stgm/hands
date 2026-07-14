class Presence < ApplicationRecord
    # "Attendance" here means simply: the student has the hands widget open. Each
    # live widget (per source site) keeps a Presence row alive with heartbeats;
    # the reaper removes rows that stopped pinging.
    belongs_to :course_domain
    belongs_to :membership

    scope :active, -> { where("last_ping_at > ?", stale_cutoff) }
    scope :stale,  -> { where(last_ping_at: ..stale_cutoff) }

    def self.stale_after
        Settings.presence_stale_after.to_i.seconds
    end

    def self.stale_cutoff
        stale_after.ago
    end

    # Record or refresh that a member has a widget open (from a given source).
    def self.touch_open!(membership, source_label: nil, location: nil)
        presence = find_or_initialize_by(membership: membership, source_label: source_label)
        presence.course_domain = membership.course_domain
        presence.connected_at ||= Time.current
        presence.last_ping_at = Time.current
        presence.location = location if location.present?
        presence.save!
        presence
    end

    def self.close!(membership, source_label: nil)
        where(membership: membership, source_label: source_label).delete_all
    end

    # Drop presences that stopped sending heartbeats. Safe to run frequently.
    def self.reap_stale!
        stale.delete_all
    end

    def active?
        last_ping_at > self.class.stale_cutoff
    end
end
