import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "showLabel", "hideLabel"]

  toggle() {
    const isHidden = this.contentTarget.style.display === "none"
    this.contentTarget.style.display = isHidden ? "" : "none"
    if (this.hasShowLabelTarget) this.showLabelTarget.style.display = isHidden ? "none" : ""
    if (this.hasHideLabelTarget) this.hideLabelTarget.style.display = isHidden ? "" : "none"
  }
}
