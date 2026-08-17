import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "feedback"]

  validate() {
    const raw = this.inputTarget.value.replace(/\D/g, "")
    if (raw.length === 0) { this.feedbackTarget.textContent = ""; return }
    if (raw.length < 11) {
      this.show("CPF deve ter 11 dígitos", "red"); return
    }
    this.show(this.isValidCpf(raw) ? "" : "CPF inválido", "red")
  }

  show(msg, color) {
    this.feedbackTarget.textContent = msg
    this.feedbackTarget.style.color = color
  }

  isValidCpf(cpf) {
    if (/^(\d)\1+$/.test(cpf)) return false
    let sum = 0
    for (let i = 0; i < 9; i++) sum += parseInt(cpf[i]) * (10 - i)
    let r = (sum * 10) % 11
    if (r >= 10) r = 0
    if (r !== parseInt(cpf[9])) return false
    sum = 0
    for (let i = 0; i < 10; i++) sum += parseInt(cpf[i]) * (11 - i)
    r = (sum * 10) % 11
    if (r >= 10) r = 0
    return r === parseInt(cpf[10])
  }
}
