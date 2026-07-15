import { Controller } from "@hotwired/stimulus"

// Number keys 1-9 (no modifiers) activate the nth menu item, mirroring a
// click. Scoped to the small, fixed-length nav menus (home, domain root) —
// not the queue/attendance menus, which are dynamic lists and already use
// digit keys for the attendance filter's type-to-search.
export default class extends Controller {
  connect() {
    // Clear any flash left over from a Turbo-restored snapshot (e.g. after
    // navigating back).
    this.items().forEach((item) => item.classList.remove("menu-item--flash"))

    this.onKeydown = this.onKeydown.bind(this)
    document.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
  }

  onKeydown(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return
    if (!/^[1-9]$/.test(event.key)) return
    if (this.isEditableTarget(event.target)) return

    const item = this.items()[Number(event.key) - 1]
    if (!item) return

    event.preventDefault()
    this.activate(item)
  }

  // Flash the item on-off-on-off like a macOS menu highlight before
  // following through, so the shortcut doesn't fire invisibly fast. Timeout
  // matches the CSS animation's duration (see .menu-item--flash).
  activate(item) {
    item.classList.add("menu-item--flash")
    window.setTimeout(() => {
      // A data-turbo-confirm on the item (e.g. "Sign out?") pops a blocking
      // dialog synchronously inside click() — so if the user cancels it,
      // we're back here with no navigation about to happen, and need to
      // clear the flash ourselves instead of leaving it stuck highlighted.
      item.click()
      item.classList.remove("menu-item--flash")
    }, 200)
  }

  items() {
    return this.element.querySelectorAll(":scope > li > a[href], :scope > li > button, :scope > li > form button")
  }

  isEditableTarget(target) {
    return target instanceof HTMLElement && (target.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(target.tagName))
  }
}
