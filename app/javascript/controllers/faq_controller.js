import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "content", "icon"]

  toggle(event) {
    const trigger = event.currentTarget
    const index = this.triggerTargets.indexOf(trigger)
    const content = this.contentTargets[index]
    const icon = this.iconTargets[index]

    const isOpen = !content.classList.contains("hidden")

    // Close all
    this.contentTargets.forEach(c => c.classList.add("hidden"))
    this.iconTargets.forEach(i => i.style.transform = "")

    // Toggle clicked
    if (!isOpen) {
      content.classList.remove("hidden")
      icon.style.transform = "rotate(180deg)"
    }
  }
}
