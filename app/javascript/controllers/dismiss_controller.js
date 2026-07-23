import { Controller } from "@hotwired/stimulus"

// Hides the controller's element on click.
export default class extends Controller {
  dismiss() {
    this.element.remove()
  }
}
