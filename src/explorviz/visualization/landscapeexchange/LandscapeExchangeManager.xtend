package explorviz.visualization.landscapeexchange

import com.google.gwt.core.client.GWT
import com.google.gwt.user.client.Timer
import com.google.gwt.user.client.rpc.ServiceDefTarget
import explorviz.shared.model.Landscape
import explorviz.visualization.experiment.Experiment
import explorviz.visualization.experiment.landscapeexchange.TutorialLandscapeExchangeService
import explorviz.visualization.experiment.landscapeexchange.TutorialLandscapeExchangeTimer
import com.google.gwt.user.client.ui.RootPanel
import java.util.Date
import com.google.gwt.i18n.client.DateTimeFormat
import explorviz.visualization.highlighting.TraceHighlighter
import explorviz.visualization.engine.main.WebGLStart
import explorviz.visualization.modelingexchange.ModelingExchangeService
import explorviz.visualization.modelingexchange.ModelingExchangeServiceAsync
import explorviz.visualization.experiment.callbacks.VoidCallback

class LandscapeExchangeManager {
	val static DATA_EXCHANGE_INTERVALL_MILLIS = 10000

	var static LandscapeExchangeServiceAsync landscapeExchangeService
	var static Timer timer
	public static boolean timeshiftStopped = false

	static val startAndStopTimeshiftLabelId = "startStopLabel"
	static val startAndStopTimeshiftButtonId = "startStopBtn"

	def static init() {
		if (timer != null) {
			timer.cancel()
		}

		timeshiftStopped = false
		LandscapeExchangeCallback.firstExchange = true

		landscapeExchangeService = createAsyncService()

		if (!WebGLStart::modelingMode) {
			if (Experiment::tutorial) {
				timer = new TutorialLandscapeExchangeTimer(landscapeExchangeService)
			} else {
				timer = new LandscapeExchangeTimer(landscapeExchangeService)
			}
			startAutomaticExchange()
		} else {
			landscapeExchangeService.getCurrentLandscape(new LandscapeExchangeCallback<Landscape>(true))
		}
	}
	
	def static void saveTargetModelIfInModelingMode(Landscape landscape) {
		if (WebGLStart::modelingMode) {
			val modelingExchange = landscapeExchangeService as ModelingExchangeServiceAsync
			modelingExchange.saveLandscape(landscape, new VoidCallback)
		}
	}

	def static void startAutomaticExchange() {
		TraceHighlighter::reset(true)

		//		NodeHighlighter::unhighlight3DNodes()
		LandscapeExchangeCallback::reset()
		timeshiftStopped = false

		val startAndStopTimeshift = RootPanel::get(startAndStopTimeshiftButtonId)
		startAndStopTimeshift.element.innerHTML = "<span class='glyphicon glyphicon glyphicon-pause'></span> Pause"

		val startAndStopTimeshiftLabel = RootPanel::get(startAndStopTimeshiftLabelId)
		startAndStopTimeshiftLabel.element.innerHTML = ""
		if (timer != null) {
			timer.run
			timer.scheduleRepeating(DATA_EXCHANGE_INTERVALL_MILLIS)
		}
	}

	def static void stopAutomaticExchange(String timestampInMillis) {
		timeshiftStopped = true

		val startAndStopTimeshift = RootPanel::get(startAndStopTimeshiftButtonId)
		startAndStopTimeshift.element.innerHTML = "<span class='glyphicon glyphicon glyphicon-play'></span> Continue"

		val startAndStopTimeshiftLabel = RootPanel::get(startAndStopTimeshiftLabelId)
		startAndStopTimeshiftLabel.element.innerHTML = "Paused at: " +
			DateTimeFormat.getFormat("HH:mm:ss").format(new Date(Long.parseLong(timestampInMillis)))
		if (timer != null)
			timer.cancel
	}

	def static void fetchSpecificLandscape(String timestampInMillis) {
		TraceHighlighter::reset(true)

		//		NodeHighlighter::unhighlight3DNodes()
		landscapeExchangeService.getLandscape(Long.parseLong(timestampInMillis),
			new LandscapeExchangeCallback<Landscape>(false))

		if (Experiment::tutorial && Experiment::getStep.timeshift) {
			Experiment::incStep()
		}
	}

	public static def boolean isStopped() {
		timeshiftStopped
	}

	def static private createAsyncService() {
		if (Experiment::tutorial) {
			val LandscapeExchangeServiceAsync landscapeExchangeService = GWT::create(
				typeof(TutorialLandscapeExchangeService))
			val endpoint = landscapeExchangeService as ServiceDefTarget
			val moduleRelativeURL = GWT::getModuleBaseURL() + "tutoriallandscapeexchange"
			endpoint.serviceEntryPoint = moduleRelativeURL
			return landscapeExchangeService
		} else if (WebGLStart::modelingMode) {
			val LandscapeExchangeServiceAsync landscapeExchangeService = GWT::create(
				typeof(ModelingExchangeService))
			val endpoint = landscapeExchangeService as ServiceDefTarget
			val moduleRelativeURL = GWT::getModuleBaseURL() + "modelingexchange"
			endpoint.serviceEntryPoint = moduleRelativeURL
			return landscapeExchangeService
		} else {
			val LandscapeExchangeServiceAsync landscapeExchangeService = GWT::create(typeof(LandscapeExchangeService))
			val endpoint = landscapeExchangeService as ServiceDefTarget
			val moduleRelativeURL = GWT::getModuleBaseURL() + "landscapeexchange"
			endpoint.serviceEntryPoint = moduleRelativeURL
			return landscapeExchangeService
		}
	}
}
