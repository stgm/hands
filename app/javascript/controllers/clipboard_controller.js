import { Controller } from "@hotwired/stimulus"

// Copies a bit of text (given as a value, so the visible copy of it can live
// anywhere on the page) and confirms it on the button that asked. The text
// stays on screen, so if the clipboard API refuses the user can still select
// it by hand.
export default class extends Controller {
  static targets = ["button"]
  static values = { text: String }

  copy() {
    navigator.clipboard?.writeText(this.textValue).then(
      () => this.confirm("Copied"),
      () => this.confirm("Copying failed")
    ) ?? this.confirm("Copying failed")
  }

  confirm(message) {
    if (!this.hasButtonTarget) return

    this.originalLabel ??= this.buttonTarget.textContent
    this.buttonTarget.textContent = message
    clearTimeout(this.timeout)
    this.timeout = window.setTimeout(() => {
      this.buttonTarget.textContent = this.originalLabel
    }, 2000)
  }
}
