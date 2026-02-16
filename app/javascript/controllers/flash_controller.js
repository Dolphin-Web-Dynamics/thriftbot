import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => this.dismiss(), 5000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.style.transition = "opacity 300ms ease, transform 300ms ease"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(-0.5rem)"
    setTimeout(() => this.element.remove(), 300)
  }
}
