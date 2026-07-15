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
    # Only broadcasts to the "who's here" view on meaningful changes (arrival or
    # a location change), not on every heartbeat ping.
    def self.touch_open!(membership, source_label: nil, location: nil)
        presence = find_or_initialize_by(membership: membership, source_label: source_label)
        newly_arrived = presence.new_record?
        location_changed = location.present? && location != presence.location
        presence.course_domain = membership.course_domain
        presence.connected_at ||= Time.current
        presence.last_ping_at = Time.current
        presence.location = location if location.present?
        presence.save!
        PresenceBroadcaster.new(presence.course_domain).refresh if newly_arrived || location_changed
        presence
    end

    def self.close!(membership, source_label: nil)
        domain = membership.course_domain
        deleted = where(membership: membership, source_label: source_label).delete_all
        PresenceBroadcaster.new(domain).refresh if deleted.positive?
    end

    # Drop presences that stopped sending heartbeats. Safe to run frequently.
    def self.reap_stale!
        domain_ids = stale.distinct.pluck(:course_domain_id)
        stale.delete_all
        domain_ids.each { |id| PresenceBroadcaster.new(CourseDomain.find(id)).refresh }
    end

    def active?
        last_ping_at > self.class.stale_cutoff
    end
end
