import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "eyeOpen", "eyeClosed"]

  toggle() {
    const visible = this.inputTarget.type === "text"
    this.inputTarget.type = visible ? "password" : "text"
    this.eyeOpenTarget.style.display  = visible ? "" : "none"
    this.eyeClosedTarget.style.display = visible ? "none" : ""
  }
}
