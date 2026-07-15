import { Controller } from "@hotwired/stimulus"

// Client-side live filter over a grid of cards. Survives Turbo Stream
// updates to the grid (e.g. presence broadcasts) via a MutationObserver,
// since those replace the grid's content without re-running Stimulus actions.
export default class extends Controller {
  static targets = ["input", "grid"]

  connect() {
    this.observer = new MutationObserver(() => this.apply())
    this.observer.observe(this.gridTarget, { childList: true, subtree: true })
    this.apply()
  }

  disconnect() {
    this.observer?.disconnect()
  }

  apply() {
    const query = this.inputTarget.value.trim().toLowerCase()
    const cards = this.gridTarget.querySelectorAll("[data-filter-name]")
    let visibleCount = 0

    cards.forEach((card) => {
      const matches = query.length === 0 || card.dataset.filterName.includes(query)
      card.hidden = !matches
      if (matches) visibleCount++
    })

    const emptyState = this.gridTarget.querySelector(".attendance-empty-filter")
    if (emptyState) emptyState.hidden = cards.length === 0 || visibleCount > 0
  }
}
