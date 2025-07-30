// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { Application } from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

eagerLoadControllersFrom("controllers", application)

window.Stimulus = Application.start()
eagerLoadControllersFrom("controllers", Stimulus)
