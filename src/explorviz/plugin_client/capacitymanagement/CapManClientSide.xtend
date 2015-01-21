package explorviz.plugin_client.capacitymanagement

import explorviz.plugin_client.attributes.IPluginKeys
import explorviz.plugin_client.interfaces.IPluginClientSide
import explorviz.plugin_client.main.Perspective
import explorviz.shared.model.Application
import explorviz.shared.model.Landscape
import explorviz.shared.model.Node
import explorviz.shared.model.helper.GenericModelElement
import explorviz.visualization.engine.contextmenu.commands.ApplicationCommand
import explorviz.visualization.engine.contextmenu.commands.NodeCommand
import explorviz.visualization.main.PluginManagerClientSide
import explorviz.visualization.main.ExplorViz
import explorviz.plugin_client.capacitymanagement.CapManStates

class CapManClientSide implements IPluginClientSide {
	public static String TERMINATE_STRING = "Terminate"
	public static String RESTART_STRING = "Restart"
	public static String START_NEW_NODE_STRING = "Start new instance of same type"
	public static String STOP_STRING = "Stop"
	public static String MIGRATE_STRING = "Migrate"
	public static String REPLICATE_STRING = "Replicate"
	
	
	public String oldPlanId = ""

	override switchedToPerspective(Perspective perspective) {
		if (perspective == Perspective::PLANNING) {
			PluginManagerClientSide::addNodePopupEntry(TERMINATE_STRING, new TerminateNodeCommand())
			PluginManagerClientSide::addNodePopupEntry(RESTART_STRING, new RestartNodeCommand())
			PluginManagerClientSide::addNodePopupSeperator
			PluginManagerClientSide::addNodePopupEntry(START_NEW_NODE_STRING, new StartNewInstanceNodeCommand())
			PluginManagerClientSide::addNodePopupEntry(REPLICATE_STRING, new ReplicateNodeCommand())
			
			PluginManagerClientSide::addApplicationPopupSeperator
			PluginManagerClientSide::addApplicationPopupEntry(STOP_STRING, new StopApplicationCommand())
			PluginManagerClientSide::addApplicationPopupEntry(RESTART_STRING, new RestartApplicationCommand())
			PluginManagerClientSide::addApplicationPopupSeperator
			PluginManagerClientSide::addApplicationPopupEntry(MIGRATE_STRING, new MigrateApplicationCommand())
			
		}
	}

	override popupMenuOpenedOn(Node node) {
		PluginManagerClientSide::setNodePopupEntryChecked(CapManClientSide::TERMINATE_STRING,
			elementShouldBeTerminated(node))
		PluginManagerClientSide::setNodePopupEntryChecked(CapManClientSide::RESTART_STRING,
			elementShouldBeRestarted(node))
	}
	//Get and Set CapManStates
	def static boolean elementShouldBeTerminated(GenericModelElement element) {
		if (!element.isGenericDataPresent(IPluginKeys::CAPMAN_STATE)) return false

		val state = element.getGenericData(IPluginKeys::CAPMAN_STATE) as CapManStates
		state == CapManStates::TERMINATE
	}

	def static void setElementShouldBeTerminated(GenericModelElement element, boolean value) {
		if (value) {
			setCapManState(element, CapManStates::TERMINATE)
		} else {
			setCapManState(element, CapManStates::NONE)
		}
	}
	def static boolean elementShouldStartNewInstance(GenericModelElement element) {
		if (!element.isGenericDataPresent(IPluginKeys::CAPMAN_STATE)) return false

		val state = element.getGenericData(IPluginKeys::CAPMAN_STATE) as CapManStates
		state == CapManStates::START_NEW
	}
	
	def static void setElementShouldStartNewInstance(GenericModelElement element, boolean value) {
		if (value) {
			setCapManState(element, CapManStates::START_NEW)
		} else {
			setCapManState(element, CapManStates::NONE)
		}
	}
	
	def static boolean elementShouldBeRestarted(GenericModelElement element) {
		if (!element.isGenericDataPresent(IPluginKeys::CAPMAN_STATE)) return false

		val state = element.getGenericData(IPluginKeys::CAPMAN_STATE) as CapManStates
		state == CapManStates::RESTART
	}

	def static void setElementShouldBeRestarted(GenericModelElement element, boolean value) {
		if (value) {
			setCapManState(element, CapManStates::RESTART)
		} else {
			setCapManState(element, CapManStates::NONE)
		}
	}
	def static boolean elementShouldBeReplicated(GenericModelElement element) {
		if (!element.isGenericDataPresent(IPluginKeys::CAPMAN_STATE)) return false

		val state = element.getGenericData(IPluginKeys::CAPMAN_STATE) as CapManStates
		state == CapManStates::REPLICATE
	}

	def static void setElementShouldBeReplicated(GenericModelElement element, boolean value) {
		if (value) {
			setCapManState(element, CapManStates::REPLICATE)
		} else {
			setCapManState(element, CapManStates::NONE)
		}
	}

	def static setCapManState(GenericModelElement element, CapManStates state) {
		element.putGenericData(IPluginKeys::CAPMAN_STATE, state)
	}

	override popupMenuOpenedOn(Application app) {
		PluginManagerClientSide::setApplicationPopupEntryChecked(CapManClientSide::STOP_STRING,
			elementShouldBeTerminated(app))
		PluginManagerClientSide::setApplicationPopupEntryChecked(CapManClientSide::RESTART_STRING,
			elementShouldBeRestarted(app))
	}

	override newLandscapeReceived(Landscape landscape) {
		val suggestionAvailable = landscape.isGenericDataPresent(IPluginKeys::CAPMAN_NEW_PLAN_ID)
		if (suggestionAvailable) {
			// only show once
			val newPlanId = landscape.getGenericStringData(IPluginKeys::CAPMAN_NEW_PLAN_ID)
			if (newPlanId.equalsIgnoreCase(oldPlanId)) {
				return;
			}
			
			oldPlanId = newPlanId
			
			CapManClientSideJS::openPlanExecutionQuestionDialog(
				landscape.getGenericStringData(IPluginKeys::CAPMAN_WARNING_TEXT),
				landscape.getGenericStringData(IPluginKeys::CAPMAN_COUNTERMEASURE_TEXT),
				landscape.getGenericStringData(IPluginKeys::CAPMAN_CONSEQUENCE_TEXT))
		}
	}

	def static void conductOkAction() {
		ExplorViz::instance.executeCapManPlanning
	}

	def static void conductManualRefinementAction() {
		ExplorViz::instance.switchToPlanningPerspective
	}

	def static void conductCancelAction() {
		// empty
	}
}

class TerminateNodeCommand extends NodeCommand {
	override execute() {
		CapManClientSide::setElementShouldBeTerminated(currentNode,
			!CapManClientSide::elementShouldBeTerminated(currentNode))
		super.execute()
	}
}

class RestartNodeCommand extends NodeCommand {
	override execute() {
		CapManClientSide::setElementShouldBeRestarted(currentNode,
			!CapManClientSide::elementShouldBeRestarted(currentNode))
		super.execute()
	}
}

class StartNewInstanceNodeCommand extends NodeCommand {
	override execute() {
		CapManClientSide::setElementShouldStartNewInstance(currentNode,
			!CapManClientSide::elementShouldStartNewInstance(currentNode))
		super.execute()
	}
}

class StopApplicationCommand extends ApplicationCommand {
	override execute() {
		CapManClientSide::setElementShouldBeTerminated(currentApp,
			!CapManClientSide::elementShouldBeTerminated(currentApp))
		super.execute()
	}
}

class RestartApplicationCommand extends ApplicationCommand {
	override execute() {
		CapManClientSide::setElementShouldBeRestarted(currentApp,
			!CapManClientSide::elementShouldBeRestarted(currentApp))
		super.execute()
	}
}

class MigrateApplicationCommand extends ApplicationCommand {
	override execute() {
		super.execute()
	}
}

class ReplicateNodeCommand extends NodeCommand {
	override execute() {
		CapManClientSide::setElementShouldBeReplicated(currentNode,
			!CapManClientSide::elementShouldBeReplicated(currentNode))
		super.execute()
	}
}