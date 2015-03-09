package explorviz.visualization.engine.contextmenu.commands.modeling

import com.google.gwt.user.client.Command
import explorviz.visualization.engine.contextmenu.PopupService
import explorviz.shared.model.System
import explorviz.visualization.engine.main.SceneDrawer
import explorviz.visualization.landscapeexchange.LandscapeExchangeManager

class ModelingConfigureSystemCommand implements Command {
	var System currentSystem

	def setCurrentSystem(System system) {
		currentSystem = system
	}

	override execute() {
		PopupService::hidePopupMenus()
		
		// TODO popup
		
		val landscape = currentSystem.parent
		LandscapeExchangeManager.saveTargetModelIfInModelingMode(landscape)
		
		SceneDrawer::createObjectsFromLandscape(landscape, true)
	}
}
