import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  connect() {
    if (!this.hasPanelTarget) return

    if (this.isMobile()) {
      this.setupOverlay()
    } else {
      const collapsed = localStorage.getItem("sidebar-collapsed") === "true"
      if (collapsed) this.panelTarget.classList.add("sidebar--collapsed")
    }
  }

  toggle() {
    if (!this.hasPanelTarget) return

    if (this.isMobile()) {
      this.panelTarget.classList.toggle("sidebar--mobile-open")
      this.overlay?.classList.toggle("is-visible")
    } else {
      this.panelTarget.classList.toggle("sidebar--collapsed")
      localStorage.setItem("sidebar-collapsed", this.panelTarget.classList.contains("sidebar--collapsed"))
    }
  }

  close() {
    if (!this.hasPanelTarget) return
    this.panelTarget.classList.remove("sidebar--mobile-open")
    this.overlay?.classList.remove("is-visible")
  }

  isMobile() {
    return window.innerWidth <= 768
  }

  setupOverlay() {
    this.overlay = this.element.querySelector(".sidebar-overlay")
    if (this.overlay) {
      this.overlay.addEventListener("click", () => this.close())
    }

    this.boundClose = () => this.close()
    document.addEventListener("turbo:before-visit", this.boundClose)
  }

  disconnect() {
    if (this.boundClose) {
      document.removeEventListener("turbo:before-visit", this.boundClose)
    }
  }
}
