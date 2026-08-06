import { Controller } from "@hotwired/stimulus"

// Group tabs over the staff queue. The queue itself is broadcast identically to
// every screen, so filtering happens here in the browser; the choice is saved on
// the staff member's membership because a TA teaches the same group all term.
//
// A tab's group is its data-group attribute: absent on "All", empty on "No group"
// (a real group name is never blank). Like filter_controller, a MutationObserver
// re-applies after a Turbo Stream replaces the list.
export default class extends Controller {
  static targets = ["tab", "list"]
  static values = { url: String, selected: String, all: Boolean }

  connect() {
    this.selection = this.allValue ? null : this.selectedValue
    this.observer = new MutationObserver(() => this.apply())
    this.observer.observe(this.listTarget, { childList: true, subtree: true })
    this.apply()
  }

  disconnect() {
    this.observer?.disconnect()
  }

  select(event) {
    const tab = event.currentTarget
    this.selection = "group" in tab.dataset ? tab.dataset.group : null

    this.tabTargets.forEach((other) => other.classList.toggle("queue-tab--active", other === tab))
    this.apply()
    this.persist()
  }

  // The "nothing in this group" empty state is CSS-driven off [hidden] (see
  // _cards.scss), so this only toggles the items themselves.
  apply() {
    this.listTarget.querySelectorAll("li[data-group]").forEach((item) => {
      item.hidden = this.selection !== null && item.dataset.group !== this.selection
    })
  }

  persist() {
    if (!this.hasUrlValue) return

    const body = new FormData()
    if (this.selection !== null) body.append("group", this.selection)

    fetch(this.urlValue, {
      method: "PATCH",
      body: body,
      headers: { "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content }
    })
  }
}
