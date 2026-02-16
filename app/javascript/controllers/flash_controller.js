import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.dismissTimeout = setTimeout(() => this.dismiss(), 5000)
    this.removeTimeout = null
  }

  disconnect() {
    clearTimeout(this.dismissTimeout)
    clearTimeout(this.removeTimeout)
  }

  dismiss() {
    clearTimeout(this.dismissTimeout)
    this.element.style.transition = "opacity 300ms ease, transform 300ms ease"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(-0.5rem)"
    this.removeTimeout = setTimeout(() => this.element.remove(), 300)
  }
}
