Rails.application.routes.draw do
    root "home#index"

    # --- Authentication (ported from course-site) ---
    namespace :auth do
        get  "mail/login",    to: "mail#login",    as: :mail_login
        post "mail/create",   to: "mail#create",   as: :mail_create
        get  "mail/code",     to: "mail#code",     as: :mail_code
        post "mail/validate", to: "mail#validate", as: :mail_validate

        get  "open/login",    to: "open#login",    as: :open_login
        get  "open/callback", to: "open#callback", as: :open_callback
    end
    delete "logout", to: "auth/session#destroy", as: :logout

    resource :profile, only: [ :edit, :update ]

    # --- Site administration (site-wide admins) ---
    namespace :admin do
        resources :course_domains, except: [ :show ] do
            member { post :rotate_secret }
        end
    end

    # --- Cross-origin embed API (token-authenticated; no slug in the path — the
    # course domain is carried inside the signed token) ---
    namespace :embed do
        resource :hand, only: [ :show, :create, :destroy ], controller: "hands" do
            patch :set_location
        end
    end
    # Self-contained widget loader + stylesheet served to linked course-sites.
    get "embed/widget.js", to: "embed/script#show", as: :embed_widget_script
    get "embed/widget.css", to: "embed/style#show", as: :embed_widget_style

    # Development-only harness to exercise the embed widget without course-site.
    if Rails.env.development?
        get "dev/embed_token", to: "dev_embed_harness#token"
        get "dev/embed_host", to: "dev_embed_harness#host"
    end

    # Health check for load balancers / uptime monitors.
    get "up" => "rails/health#show", as: :rails_health_check

    # --- Course-domain scoped UI (must stay LAST: the :slug segment is greedy) ---
    # Standalone access at /<slug> for students, TAs, teachers and admins.
    scope path: ":course_domain_slug", as: :domain do
        get "/", to: "domains#show", as: :root
        post "join", to: "domains#join", as: :join

        # student widget (full page + fragment)
        resource :hand, only: [ :show, :create, :destroy ], controller: "hands/raises" do
            patch :set_location
        end

        # staff queue (distinct path/helpers so they don't collide with the
        # singular student :hand resource above)
        resources :hands, only: [ :index, :show ], controller: "hands/queue",
            path: "queue", as: :queue_hands do
            member do
                put :claim
                put :done
                put :helpline
            end
        end

        resource :availability, only: [ :edit, :update ], controller: "hands/availabilities"
        resources :notes, only: [ :index, :create ], controller: "hands/notes"
        get "attendance", to: "hands/attendance#index", as: :attendance

        # staff management (teachers invite/manage staff)
        get "staff", to: "staff#index", as: :staff
        patch "staff/members/:id", to: "staff#update", as: :staff_member
        delete "staff/members/:id", to: "staff#destroy"
        resources :invitations, only: [ :create, :destroy ], controller: "staff/invitations", path: "staff/invitations", as: :staff_invitations
    end

    # Accepting a staff invitation (identifies the domain via the token; requires
    # the invitee to be logged in).
    get "invitations/:token/accept", to: "invitations#accept", as: :accept_invitation
end
