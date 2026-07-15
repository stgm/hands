import { Controller } from "@hotwired/stimulus"

// Backspace (no modifiers) navigates to the previous page, like a browser
// back button. Attached to <body> so it works app-wide, not just on pages
// with a menu.
export default class extends Controller {
  connect() {
    this.onKeydown = this.onKeydown.bind(this)
    document.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
  }

  onKeydown(event) {
    if (event.metaKey || event.ctrlKey || event.altKey || event.shiftKey) return
    if (event.key !== "Backspace") return
    if (this.isEditableTarget(event.target)) return

    event.preventDefault()
    window.history.back()
  }

  // Header icon click. Falls through to its root_path href — rather than
  // preventing default and calling history.back() — for modifier-clicks
  // (open in new tab/window) and for a fresh tab with no history to go back
  // to (e.g. the app opened from a home-screen bookmark).
  back(event) {
    if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
    if (window.history.length <= 1) return

    event.preventDefault()
    window.history.back()
  }

  isEditableTarget(target) {
    return target instanceof HTMLElement && (target.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(target.tagName))
  }
}
