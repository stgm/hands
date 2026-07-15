import { Controller } from "@hotwired/stimulus"

// Keeps a scrollable message list scrolled to its newest (bottom) entry,
// like a chat app, on every page load.
export default class extends Controller {
  static targets = ["messages"]

  connect() {
    this.scrollToBottom()
  }

  // Re-run after the composer opens/closes (see disclosure_controller.js):
  // it resizes the message list, which otherwise leaves the scroll position
  // wherever it happened to land.
  scrollToBottom() {
    requestAnimationFrame(() => {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    })
  }
}
