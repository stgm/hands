class PresenceReaperJob < ApplicationJob
    queue_as :default

    def perform
        Presence.reap_stale!
    end
end
