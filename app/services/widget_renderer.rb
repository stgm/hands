# Renders the student widget to an HTML string for pushing over ActionCable.
# Using a plain HTML payload (rather than Turbo cross-origin streams) keeps the
# embed origin-agnostic: the same channel drives the standalone page and the
# cross-domain course-site widget.
#
# Broadcasts have no request context, so the locale is taken from the membership
# (handed over by their course-site) rather than from I18n's ambient state.
class WidgetRenderer
    def self.render(membership)
        I18n.with_locale(membership.effective_locale) do
            state = WidgetState.for(membership)
            ApplicationController.renderer.render(
                partial: "hands/raises/widget",
                locals: state.locals
            )
        end
    end
end
