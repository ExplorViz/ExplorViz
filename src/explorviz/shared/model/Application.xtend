package explorviz.shared.model

import explorviz.shared.model.helper.CommunicationAppAccumulator
import explorviz.shared.model.helper.DrawNodeEntity
import explorviz.shared.model.helper.ELanguage
import java.util.ArrayList
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors
import explorviz.plugin_client.capacitymanagement.execution.SyncObject

class Application extends DrawNodeEntity implements SyncObject{
	@Accessors var int id

	@Accessors var boolean database

	@Accessors var ELanguage programmingLanguage

	@Accessors long lastUsage

	@Accessors Node parent
	@Accessors ScalingGroup scalinggroup

	@Accessors var List<Component> components = new ArrayList<Component>

	@Accessors var List<CommunicationClazz> communications = new ArrayList<CommunicationClazz>

	@Accessors val transient List<CommunicationAppAccumulator> communicationsAccumulated = new ArrayList<CommunicationAppAccumulator>

	@Accessors var List<Communication> incomingCommunications = new ArrayList<Communication>
	@Accessors var List<Communication> outgoingCommunications = new ArrayList<Communication>
	
	/** new attributes since control-center */
	@Accessors var boolean lockedUntilExecutionActionFinished = false;
	
	@Accessors var String startScript;
	@Accessors var int waitTimeForStarting;
	
	
		
	override void destroy() {
		components.forEach[it.destroy()]
		communicationsAccumulated.forEach[it.destroy()]
		super.destroy()
	}

	def void clearAllPrimitiveObjects() {
		components.forEach[it.clearAllPrimitiveObjects()]

	//		communicationsAccumulated.forEach[it.clearAllPrimitiveObjects()] done in extra method
	}

	def void unhighlight() {
		components.forEach[it.unhighlight]
	}

	def void openAllComponents() {
		components.forEach[it.openAllComponents()]
	}
	
	/** new methods since control-center */
	
	override isLockedUntilExecutionActionFinished() {
		return lockedUntilExecutionActionFinished;
	}
	
	override setLockedUntilExecutionActionFinished(boolean locked) {
		lockedUntilExecutionActionFinished = locked;
	}


}
