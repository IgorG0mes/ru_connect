import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: { type: Number, default: 4000 } }

  connect() {
    this.element.classList.add("toast-visible")
    this.timer = setTimeout(() => this.dismiss(), this.durationValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  dismiss() {
    this.element.classList.add("toast-hiding")
    this.element.addEventListener("animationend", () => this.element.remove(), { once: true })
  }
}
