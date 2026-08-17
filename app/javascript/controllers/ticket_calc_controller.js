import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quantity", "total"]
  static values = { unitPrice: Number }

  connect() {
    this.update()
  }

  increment() {
    this.setQuantity(this.current + 1)
  }

  decrement() {
    this.setQuantity(this.current - 1)
  }

  get current() {
    return parseInt(this.quantityTarget.value, 10) || 0
  }

  setQuantity(value) {
    const min = parseInt(this.quantityTarget.min, 10) || 1
    const max = parseInt(this.quantityTarget.max, 10) || 999
    this.quantityTarget.value = Math.min(max, Math.max(min, value))
    this.update()
  }

  update() {
    const total = this.current * this.unitPriceValue
    this.totalTarget.textContent = total.toLocaleString("pt-BR", {
      style: "currency",
      currency: "BRL"
    })
  }
}
