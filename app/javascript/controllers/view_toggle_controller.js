import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grid", "list"]

  connect() {
    const viewMode = localStorage.getItem("ipoViewMode") || "grid"
    this.toggleView(viewMode)
  }

  showGrid() {
    this.toggleView("grid")
    localStorage.setItem("ipoViewMode", "grid")
  }

  showList() {
    this.toggleView("list")
    localStorage.setItem("ipoViewMode", "list")
  }

  toggleView(mode) {
    if (mode === "grid") {
      this.gridTarget.classList.remove("hidden")
      this.listTarget.classList.add("hidden")
    } else {
      this.listTarget.classList.remove("hidden")
      this.gridTarget.classList.add("hidden")
    }

  }
}
