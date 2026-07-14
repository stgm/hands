# Allow linked course-sites (on other domains) to call the embed widget API
# cross-origin. The signed embed token is the credential, so no cookies are used
# and any origin may present a valid token.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
        origins "*"
        resource "/embed/*",
            headers: :any,
            methods: [ :get, :post, :patch, :put, :delete, :options ],
            credentials: false
    end
end
