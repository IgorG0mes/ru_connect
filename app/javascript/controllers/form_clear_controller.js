import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  clear() {
    this.inputTargets.forEach(input => { input.value = "" })
    this.inputTargets[0]?.focus()
  }
}
