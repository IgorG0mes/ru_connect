import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["reader", "button", "modal"]
  static values = { url: String, signedIn: Boolean, loginUrl: String }

  connect() {
    this.scanner = null
    this.boundReset = this.reset.bind(this)
    document.addEventListener("turbo:submit-end", this.boundReset)
  }

  disconnect() {
    document.removeEventListener("turbo:submit-end", this.boundReset)
    this.scanner?.clear().catch(() => {})
  }

  start() {
    if (!this.signedInValue) {
      const form = document.createElement("form")
      form.method = "POST"
      form.action = this.urlValue
      form.setAttribute("data-turbo", "false")
      const csrf = document.querySelector('meta[name="csrf-token"]')?.content
      if (csrf) {
        const csrfInput = document.createElement("input")
        csrfInput.type = "hidden"
        csrfInput.name = "authenticity_token"
        csrfInput.value = csrf
        form.appendChild(csrfInput)
      }
      document.body.appendChild(form)
      form.submit()
      return
    }

    this.modalTarget.style.display = "flex"
    document.body.style.overflow = "hidden"

    this.scanner = new Html5QrcodeScanner(
      this.readerTarget.id,
      { fps: 10, qrbox: { width: 300, height: 300 } },
      false
    )
    this.scanner.render(
      (text) => this.onSuccess(text),
      () => {}
    )
  }

  onSuccess(text) {
    this.scanner.pause(true)

    const form = document.createElement("form")
    form.method = "POST"
    form.action = this.urlValue

    const input = document.createElement("input")
    input.type = "hidden"
    input.name = "identifier"
    input.value = text
    form.appendChild(input)

    const csrf = document.querySelector('meta[name="csrf-token"]').content
    const csrfInput = document.createElement("input")
    csrfInput.type = "hidden"
    csrfInput.name = "authenticity_token"
    csrfInput.value = csrf
    form.appendChild(csrfInput)

    document.body.appendChild(form)
    form.requestSubmit()
  }

  reset() {
    this.scanner?.clear().catch(() => {})
    this.scanner = null
    this.readerTarget.innerHTML = ""
    this.modalTarget.style.display = "none"
    document.body.style.overflow = ""
  }
}
