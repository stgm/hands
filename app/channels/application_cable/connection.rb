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
        def find_verified_user
            if (membership = embed_membership)
                self.current_membership = membership
                return membership.user
            end

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
    end
end
