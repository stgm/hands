# Decides which state the student widget should show for a membership, and
# packages the locals both the controller and the realtime broadcaster render
# the widget partials with. Keeping this in one place guarantees a page load and
# a live update produce identical markup.
class WidgetState
    attr_reader :domain, :membership, :state, :hand, :position, :assist

    def self.for(membership)
        new(membership).tap(&:compute)
    end

    def initialize(membership)
        @membership = membership
        @domain = membership.course_domain
    end

    def compute
        @hand = @membership.hands.open.first

        if @hand
            if @hand.assist_membership_id.nil?
                @state = :waiting
                @position = @hand.queue_position
            else
                @state = :helping
                @assist = @hand.assist
            end
        elsif needs_location_checkin?
            @state = :location
        elsif queue_busy?
            @state = :line
        else
            @state = :form
        end
        self
    end

    def locals
        {
            state: state, hand: hand, position: position, assist: assist,
            domain: domain, membership: membership, greeting: greeting
        }
    end

    # Time-of-day greeting for the check-in view (ported from course-site's ranges).
    def greeting
        case Time.current.hour
        when 0..11  then I18n.t("hands.good_morning")
        when 12..16 then I18n.t("hands.good_afternoon")
        when 17..19 then I18n.t("hands.good_evening")
        else             I18n.t("hands.good_night")
        end
    end

    private

    # Before asking, force a check-in when the domain wants it and we don't yet
    # know where the student is (physical-location domains only).
    def needs_location_checkin?
        @domain.location_bumper? && !@domain.link_mode? && @membership.last_location.blank?
    end

    def queue_busy?
        @domain.hands.open.count > 6 &&
            @membership.hands.where(success: true).where("closed_at > ?", 20.minutes.ago).exists?
    end
end
