import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["clickable"]
  static values = { refreshInterval: Number }

  connect() {
    if (this.hasRefreshIntervalValue) {
      this.startRefreshing()
    }
  }

  disconnect() {
    this.stopRefreshing()
  }

  clickElm() {
    for (const clickableTarget of this.clickableTargets) {
      clickableTarget.click()
    }
  }

  startRefreshing() {
    this.refreshTimer = setInterval(() => {
      this.clickElm()
    }, this.refreshIntervalValue)
  }

  stopRefreshing() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }
}
