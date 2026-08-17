import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "tab"]
  static values  = { initialFace: { type: Number, default: 0 } }

  connect() {
    this.currentFace = this.initialFaceValue
    this.updateTabs()
  }

  flip(event) {
    const face = parseInt(event.currentTarget.dataset.face)
    if (face === this.currentFace) return

    this.currentFace = face
    this.cardTarget.classList.toggle("is-flipped", face > 0)
    this.updateTabs()
  }

  updateTabs() {
    this.tabTargets.forEach((tab) => {
      const active = parseInt(tab.dataset.face) === this.currentFace
      tab.classList.toggle("menu-flip-tab--active", active)
    })
  }
}
