import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const collapsed = localStorage.getItem("sidebar-collapsed") === "true"
    if (collapsed) this.element.classList.add("sidebar--collapsed")
  }

  toggle() {
    this.element.classList.toggle("sidebar--collapsed")
    localStorage.setItem("sidebar-collapsed", this.element.classList.contains("sidebar--collapsed"))
  }
}
