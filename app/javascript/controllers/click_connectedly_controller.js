import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { targetClass: String }

  connect() {
    this.clickElm()
    this.element.remove()
  }

  clickElm() {
    const clickTargets = document.querySelectorAll(this.targetClassValue)
    clickTargets.forEach(clickTarget => {
      clickTarget.click()
    })
  }
}
