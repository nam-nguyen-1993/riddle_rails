import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "playerField",
    "sourceInput",
    "topicSelectWrap",
    "topicSelect",
    "customTopicWrap",
    "customTopicInput",
    "customConfirmWrap",
    "customConfirmInput",
    "customConfirmButton",
    "customConfirmStatus",
    "topicIdInput",
    "questionIdsInput",
    "startButton"
  ]

  connect() {
    this.setPlayerCount(2)
    this.changeQuestionSource()
  }

  changePlayerCount(event) {
    this.setPlayerCount(Number(event.target.value))
  }

  changeQuestionSource() {
    const source = this.selectedQuestionSource
    const usingSpecificTopic = source === "specific"
    const usingCustomTopic = source === "custom"

    this.topicSelectWrapTarget.hidden = !usingSpecificTopic
    this.topicSelectTarget.disabled = !usingSpecificTopic

    this.customTopicWrapTarget.hidden = !usingCustomTopic
    this.customTopicInputTarget.disabled = !usingCustomTopic
    this.customTopicInputTarget.required = usingCustomTopic
    this.customConfirmWrapTarget.hidden = !usingCustomTopic

    if (!usingCustomTopic) this.resetCustomTopicConfirmation()

    this.updateCustomTopicControls()
  }

  customTopicChanged() {
    this.resetCustomTopicConfirmation()
    this.updateCustomTopicControls()
  }

  async confirmCustomTopic() {
    const topicName = this.customTopicInputTarget.value.trim()
    if (!topicName) return

    this.customConfirmButtonTarget.disabled = true
    this.startButtonTarget.disabled = true
    this.customConfirmStatusTarget.innerHTML =
      '<span class="gen-spinner"></span> Generating 10 questions…'
    this.customConfirmStatusTarget.className = ""

    try {
      const response = await fetch("/topics/generate", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ topic_name: topicName })
      })

      const data = await response.json()

      if (!response.ok) {
        this.customConfirmStatusTarget.textContent = data.error || "Failed to generate questions. Try again."
        this.customConfirmStatusTarget.className = "gen-error"
        this.customConfirmButtonTarget.disabled = false
        this.updateCustomTopicControls()
        return
      }

      this.customConfirmInputTarget.value = "1"
      this.topicIdInputTarget.value = data.topic_id
      this.questionIdsInputTarget.value = data.question_ids.join(",")
      this.customConfirmStatusTarget.textContent =
        `✓ ${data.count} questions ready for "${data.topic_name}"`
      this.customConfirmStatusTarget.className = "confirmed"
      this.updateCustomTopicControls()
    } catch (_err) {
      this.customConfirmStatusTarget.textContent = "Network error. Please try again."
      this.customConfirmStatusTarget.className = "gen-error"
      this.customConfirmButtonTarget.disabled = false
      this.updateCustomTopicControls()
    }
  }

  setPlayerCount(count) {
    this.playerFieldTargets.forEach((field, index) => {
      const enabled = index < count
      field.hidden = !enabled
      field.querySelector("input").disabled = !enabled
    })
  }

  get selectedQuestionSource() {
    return this.sourceInputTargets.find((input) => input.checked)?.value || "mixed"
  }

  get customTopicConfirmed() {
    return this.customConfirmInputTarget.value === "1"
  }

  resetCustomTopicConfirmation() {
    this.customConfirmInputTarget.value = "0"
    this.topicIdInputTarget.value = ""
    this.questionIdsInputTarget.value = ""
    this.customConfirmStatusTarget.textContent = "Enter a topic name above to generate questions."
    this.customConfirmStatusTarget.className = ""
  }

  updateCustomTopicControls() {
    const usingCustomTopic = this.selectedQuestionSource === "custom"
    const hasTopicName = this.customTopicInputTarget.value.trim().length > 0

    this.customConfirmButtonTarget.disabled =
      !usingCustomTopic || !hasTopicName || this.customTopicConfirmed
    this.startButtonTarget.disabled = usingCustomTopic && !this.customTopicConfirmed
  }
}
