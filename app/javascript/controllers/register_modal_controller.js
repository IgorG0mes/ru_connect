import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["studentLink", "visitorLink"]

  connect() {
    this.boundOpen = this.openFromEvent.bind(this)
    document.addEventListener("register:open", this.boundOpen)
  }

  disconnect() {
    document.removeEventListener("register:open", this.boundOpen)
  }

  openFromEvent(event) {
    const identifier = event.detail.identifier || ""
    this.studentLinkTarget.href = `/students/new?identifier=${encodeURIComponent(identifier)}`
    this.visitorLinkTarget.href = `/visitors/new?identifier=${encodeURIComponent(identifier)}`
    this.element.style.display = "flex"
    document.body.style.overflow = "hidden"
  }

  close() {
    this.element.style.display = "none"
    document.body.style.overflow = ""
  }
}
