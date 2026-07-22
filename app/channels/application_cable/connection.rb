module ApplicationCable
    class Connection < ActionCable::Connection::Base
        identified_by :current_user, :current_membership

        def connect
            self.current_user = find_verified_user
        end

        private

        # Two ways to identify a socket:
        #   1. an embed token in the query string (cross-domain course-site widget)
        #   2. the signed session cookie (standalone use of the hands app)
        #
        # Origin is enforced here rather than by Action Cable's global
        # allowed_request_origins list, because the two paths need opposite
        # answers and the global list cannot tell them apart:
        #
        #   - The token path must accept *any* origin: a linked course-site lives
        #     on its own domain, and the encrypted single-use token is the
        #     credential (same reasoning as the "*" CORS rule for /embed/*). An
        #     allow-list here would mean every newly linked course-site needs a
        #     redeploy, and a missing entry fails as an unlogged 404 on the
        #     WebSocket handshake.
        #   - The cookie path must stay same-origin: without that check any site
        #     could open a socket riding the student's session cookie (CSWSH).
        #
        # Order matters. The token branch runs first, and a token that fails to
        # verify must not fall through to the cookies of a foreign origin.
        def find_verified_user
            if (membership = embed_membership)
                self.current_membership = membership
                return membership.user
            end

            return reject_unauthorized_connection unless same_origin?

            user_id = session_hash&.dig("user_id")
            user = User.find_by(id: user_id) if user_id
            user || reject_unauthorized_connection
        end

        def embed_membership
            token = request.params[:token]
            return nil if token.blank?

            result = Embed::TokenVerifier.call(token)
            result.ok? ? result.membership : nil
        end

        def session_hash
            cookies.encrypted[Rails.application.config.session_options[:key]]
        end

        # A blank Origin is allowed, matching Action Cable's own default: browsers
        # always send one on a WebSocket handshake, so blank means a non-browser
        # client, which carries no ambient cookies to abuse. request.base_url is
        # the externally visible origin because config.assume_ssl is set in
        # production, so it says https behind the TLS-terminating proxy.
        def same_origin?
            origin = request.origin
            return true if origin.blank? || origin == request.base_url

            logger.warn "Rejected cross-origin cookie connection from #{origin.inspect}"
            false
        end
    end
end
