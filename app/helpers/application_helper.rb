module ApplicationHelper
    # Name of a staff membership as seen by the current viewer: "you" when it is
    # the viewer themselves, so queue items read naturally for the staff member.
    def staff_name(membership)
        return "somebody" if membership.nil?

        membership == current_membership ? "you" : membership.display_name
    end
end
