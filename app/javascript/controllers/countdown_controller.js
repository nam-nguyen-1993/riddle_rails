import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["remaining", "elapsed", "passForm"]
  static values = { seconds: Number }

  connect() {
    this.startedAt = Date.now()
    this.autoSubmitted = false
    this.tick()
    this.timer = setInterval(() => this.tick(), 250)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  choiceSelected(event) {
    if (navigator.vibrate) navigator.vibrate(50)
    this.lockUI(event.currentTarget)
  }

  lockUI(selectedButton) {
    // Immediately show selected state and disable everything so lag is invisible
    this.element.querySelectorAll(".choice-button").forEach((btn) => {
      if (btn === selectedButton) {
        btn.classList.add("choice-locked-selected")
      } else {
        btn.classList.add("choice-locked-dim")
      }
    })
    const passBtn = this.element.querySelector(".pass-button")
    if (passBtn) passBtn.classList.add("choice-locked-dim")
  }

  tick() {
    const elapsed = Math.min(this.secondsValue, Math.floor((Date.now() - this.startedAt) / 1000))
    const remaining = Math.max(this.secondsValue - elapsed, 0)

    this.remainingTarget.textContent = remaining
    this.elapsedTargets.forEach((target) => {
      target.value = elapsed
    })

    if (remaining === 0 && !this.autoSubmitted && this.hasPassFormTarget) {
      this.autoSubmitted = true
      this.passFormTarget.requestSubmit()
    }
  }
}
