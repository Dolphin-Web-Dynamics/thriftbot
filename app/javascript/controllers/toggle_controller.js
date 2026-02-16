import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { target: String }

  toggle() {
    const content = this.targetValue
      ? document.getElementById(this.targetValue)
      : this.element.closest("[data-toggle-scope]")?.querySelector("[data-toggle-content]")
    if (!content) return

    const expanded = content.classList.toggle("hidden") === false
    this.element.setAttribute("aria-expanded", expanded)
  }
}
