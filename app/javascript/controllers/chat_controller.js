import { Controller } from "@hotwired/stimulus"

// Keeps a scrollable message list scrolled to its newest (bottom) entry,
// like a chat app, on every page load.
export default class extends Controller {
  static targets = ["messages"]

  // Scrolls synchronously, before the initial paint: layout is already
  // settled at connect time, so waiting a frame (like scrollToBottom below)
  // would paint one frame at scrollTop 0 first, flashing the top of the list
  // before jumping to the bottom.
  connect() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  // Re-run after the composer opens/closes (see disclosure_controller.js):
  // it resizes the message list, which otherwise leaves the scroll position
  // wherever it happened to land. Needs the rAF here since the resize hasn't
  // finished laying out yet when the toggle event fires.
  scrollToBottom() {
    requestAnimationFrame(() => {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    })
  }
}
