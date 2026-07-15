import { Controller } from "@hotwired/stimulus"

// Toggles a target's visibility from a button click, swapping places with
// the trigger that opened it. Hidden by default via the `hidden` attribute
// on the target in markup.
export default class extends Controller {
  static targets = ["trigger", "content"]

  toggle() {
    // document.startViewTransition() runs its callback asynchronously (after
    // capturing the "old" snapshot), so anything that depends on the new
    // hidden state has to happen inside this callback, not after it.
    const flip = () => {
      this.contentTarget.hidden = !this.contentTarget.hidden
      if (this.hasTriggerTarget) this.triggerTarget.hidden = !this.triggerTarget.hidden

      if (!this.contentTarget.hidden) {
        this.contentTarget.querySelector("trix-editor")?.focus()
      }

      // Bubbles up to any ancestor controller (e.g. the chat controller) that
      // needs to react to the composer opening, such as re-scrolling the
      // message list now that the composer has taken up more space.
      this.dispatch("toggle", { detail: { shown: !this.contentTarget.hidden } })
    }

    if (document.startViewTransition) {
      document.startViewTransition(flip)
    } else {
      flip()
    }
  }
}
