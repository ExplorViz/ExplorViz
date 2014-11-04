package explorviz.plugin.capacitymanagement

import explorviz.plugin.attributes.CapManStates
import explorviz.plugin.attributes.IPluginKeys
import explorviz.plugin.interfaces.IPluginClientSide
import explorviz.plugin.main.Perspective
import explorviz.shared.model.Application
import explorviz.shared.model.Landscape
import explorviz.shared.model.Node
import explorviz.visualization.engine.contextmenu.commands.ApplicationCommand
import explorviz.visualization.engine.contextmenu.commands.NodeCommand
import explorviz.visualization.main.PluginManagerClientSide
import explorviz.shared.model.helper.GenericModelElement

class CapManClientSide implements IPluginClientSide {
	public static String TERMINATE_STRING = "Terminate"
	public static String RESTART_STRING = "Restart"
	public static String START_NEW_NODE_STRING = "Start new instance of same type"
	public static String STOP_STRING = "Stop"
	public static String MIGRATE_STRING = "Migrate"
	public static String REPLICATE_STRING = "Replicate"

	override switchedToPerspective(Perspective perspective) {
		if (perspective == Perspective::PLANNING) {
			openPlanExecutionQuestionDialog()
			PluginManagerClientSide::addNodePopupEntry(TERMINATE_STRING, new TerminateNodeCommand())
			PluginManagerClientSide::addNodePopupEntry(RESTART_STRING, new RestartNodeCommand())
			PluginManagerClientSide::addNodePopupSeperator
			PluginManagerClientSide::addNodePopupEntry(START_NEW_NODE_STRING, new StartNewInstanceNodeCommand())

			PluginManagerClientSide::addApplicationPopupSeperator
			PluginManagerClientSide::addApplicationPopupEntry(STOP_STRING, new StopApplicationCommand())
			PluginManagerClientSide::addApplicationPopupEntry(RESTART_STRING, new RestartApplicationCommand())
			PluginManagerClientSide::addApplicationPopupSeperator
			PluginManagerClientSide::addApplicationPopupEntry(MIGRATE_STRING, new MigrateApplicationCommand())
			PluginManagerClientSide::addApplicationPopupEntry(REPLICATE_STRING, new ReplicateApplicationCommand())
		}
	}

	override popupMenuOpenedOn(Node node) {
		PluginManagerClientSide::setNodePopupEntryChecked(CapManClientSide::TERMINATE_STRING,
			elementShouldBeTerminated(node))
		PluginManagerClientSide::setNodePopupEntryChecked(CapManClientSide::RESTART_STRING, elementShouldBeRestarted(node))
	}

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

	def static setCapManState(GenericModelElement element, CapManStates state) {
		element.putGenericData(IPluginKeys::CAPMAN_STATE, state)
	}

	override popupMenuOpenedOn(Application app) {
		PluginManagerClientSide::setApplicationPopupEntryChecked(CapManClientSide::STOP_STRING,
			elementShouldBeTerminated(app))
		PluginManagerClientSide::setApplicationPopupEntryChecked(CapManClientSide::RESTART_STRING,
			elementShouldBeRestarted(app))
	}

	def static void openPlanExecutionQuestionDialog() {
		CapManClientSideJS::openPlanExecutionQuestionDialog(
			"The software landscape violates its requirements for response times.",
			"It is suggested to start a new node of type 'm1.small' with the application 'Neo4J' on it.",
			"After the change, the response time is improved and the operating costs increase by 5 Euro per hour.")
	}

	override newLandscapeReceived(Landscape landscape) {
		// TODO ?
	}

}

class TerminateNodeCommand extends NodeCommand {
	override execute() {
		CapManClientSide::setElementShouldBeTerminated(currentNode, !CapManClientSide::elementShouldBeTerminated(currentNode))
		super.execute()
	}
}

class RestartNodeCommand extends NodeCommand {
	override execute() {
		CapManClientSide::setElementShouldBeRestarted(currentNode, !CapManClientSide::elementShouldBeRestarted(currentNode))
		super.execute()
	}
}

class StartNewInstanceNodeCommand extends NodeCommand {
	override execute() {
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

class ReplicateApplicationCommand extends ApplicationCommand {
	override execute() {
		super.execute()
	}
}
