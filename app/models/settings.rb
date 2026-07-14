class Settings < RailsSettings::Base
    cache_prefix { "v1" }

    # Prefer email one-time-code login even when OIDC is configured.
    field :login_by_email, type: :boolean, default: true

    # How long a "widget open" presence may go without a heartbeat before the
    # reaper considers the student gone (seconds).
    field :presence_stale_after, type: :integer, default: 120
end
