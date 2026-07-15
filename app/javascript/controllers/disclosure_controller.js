import { Controller } from "@hotwired/stimulus"

// Toggles a target's visibility from a button click, swapping places with
// the trigger that opened it. Hidden by default via the `hidden` attribute
// on the target in markup.
export default class extends Controller {
  static targets = ["trigger", "content"]

  connect() {
    this.onKeydown = this.onKeydown.bind(this)
    document.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
  }

  onKeydown(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return

    // "+" opens the composer, mirroring a click on the trigger button.
    if (event.key === "+" && this.hasTriggerTarget && !this.triggerTarget.hidden && !this.isEditableTarget(event.target)) {
      event.preventDefault()
      this.toggle()
      return
    }

    // Esc dismisses the open composer, but only if there's no draft to lose.
    if (event.key === "Escape" && !this.contentTarget.hidden && this.isEmpty()) {
      event.preventDefault()
      this.toggle()
    }
  }

  isEditableTarget(target) {
    return target instanceof HTMLElement && (target.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(target.tagName))
  }

  isEmpty() {
    const editor = this.contentTarget.querySelector("trix-editor")
    return !editor || editor.innerText.trim() === ""
  }

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
