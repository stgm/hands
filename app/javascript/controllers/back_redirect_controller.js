import { Controller } from "@hotwired/stimulus"

// The queue's done/delete/helpline forms redirect back to the list the staff
// member came from. Following that redirect as a normal Turbo visit pushes a
// *second* history entry for the list — the list is already sitting one page
// back and stays live via its own Turbo Stream subscription — so leaving the
// queue needs two presses of Back instead of one. Go back in history instead
// of following the redirect.
export default class extends Controller {
  connect() {
    this.onSubmitEnd = this.onSubmitEnd.bind(this)
    this.onBeforeVisit = this.onBeforeVisit.bind(this)
    this.element.addEventListener("turbo:submit-end", this.onSubmitEnd)
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.onSubmitEnd)
    document.removeEventListener("turbo:before-visit", this.onBeforeVisit)
  }

  onSubmitEnd(event) {
    if (!event.detail.success) return

    document.addEventListener("turbo:before-visit", this.onBeforeVisit, { once: true })
  }

  onBeforeVisit(event) {
    if (window.history.length <= 1) return

    event.preventDefault()
    window.history.back()
  }
}
