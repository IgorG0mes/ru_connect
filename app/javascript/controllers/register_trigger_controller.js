import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { identifier: String }

  connect() {
    document.dispatchEvent(new CustomEvent("register:open", {
      detail: { identifier: this.identifierValue }
    }))
    this.element.remove()
  }
}
