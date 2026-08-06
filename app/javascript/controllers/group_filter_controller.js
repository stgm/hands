import { Controller } from "@hotwired/stimulus"

// Group tabs over the staff queue. The queue itself is broadcast identically to
// every screen, so filtering happens here in the browser; the choice is saved on
// the staff member's membership because a TA teaches the same group all term.
//
// A tab's group is its data-group attribute: absent on "All", empty on "No group"
// (a real group name is never blank). Like filter_controller, a MutationObserver
// re-applies after a Turbo Stream replaces the list.
//
// The active tab is the only record of the choice in the page. Reading it back
// here (rather than from a separate attribute the click never updates) is what
// makes a Turbo restoration visit — which replays a cached snapshot without
// asking the server — come back still filtered.
export default class extends Controller {
  static targets = ["tab", "list"]
  static values = { url: String }

  connect() {
    this.selection = this.selectionFromTabs()
    this.observer = new MutationObserver(() => this.apply())
    this.observer.observe(this.listTarget, { childList: true, subtree: true })
    this.apply()
  }

  selectionFromTabs() {
    const active = this.tabTargets.find((tab) => tab.classList.contains("queue-tab--active"))
    return active && "group" in active.dataset ? active.dataset.group : null
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
