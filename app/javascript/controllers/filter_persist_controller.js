import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["issueType", "year"]

  connect() {
    const issueType = localStorage.getItem("ipoIssueType")
    const year = localStorage.getItem("ipoYear")

    if (issueType && this.hasIssueTypeTarget) this.issueTypeTarget.value = issueType
    if (year && this.hasYearTarget) this.yearTarget.value = year
  }

  submitForm() {
    if (this.hasIssueTypeTarget) {
      localStorage.setItem("ipoIssueType", this.issueTypeTarget.value)
    }
    if (this.hasYearTarget) {
      localStorage.setItem("ipoYear", this.yearTarget.value)
    }
    this.element.requestSubmit()
  }
}
