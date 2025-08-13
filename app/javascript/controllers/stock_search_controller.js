import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "checkbox", "selectedContainer"]

  connect() {
    this.selected = new Set()
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)

    this.timeout = setTimeout(() => {
      const query = this.inputTarget.value.trim()
      if (query.length >= 2) {
        fetch(`/multi_stock/search_stock?q=${encodeURIComponent(query)}`, {
          headers: { "Accept": "text/html" }
        })
          .then(response => response.text())
          .then(html => {
            this.resultsTarget.innerHTML = html
            this.restoreChecked()
          })
      }
    }, 500)
  }

  toggleSelection(event) {
    const checkbox = event.target
    const value = checkbox.value

    if (checkbox.checked) {
      this.selected.add(value)
      this.addHiddenField(value)
    } else {
      this.selected.delete(value)
      this.removeHiddenField(value)
    }
  }

  restoreChecked() {
    this.checkboxTargets.forEach(cb => {
      cb.checked = this.selected.has(cb.value)
      cb.addEventListener("change", (e) => this.toggleSelection(e))
    })
  }

  addHiddenField(value) {
    if (!this.selectedContainerTarget.querySelector(`[value="${value}"]`)) {
      const hidden = document.createElement("input")
      hidden.type = "hidden"
      hidden.name = "stock_symbols[]"
      hidden.value = value
      this.selectedContainerTarget.appendChild(hidden)
    }
  }

  removeHiddenField(value) {
    const field = this.selectedContainerTarget.querySelector(`[value="${value}"]`)
    if (field) field.remove()
  }
}
