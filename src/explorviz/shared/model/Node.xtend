package explorviz.shared.model

import explorviz.shared.model.helper.DrawNodeEntity
import java.util.ArrayList
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors

class Node extends DrawNodeEntity {
	@Accessors String ipAddress
	
	@Accessors double cpuUtilization
	@Accessors long freeRAM
	@Accessors long usedRAM
	
	@Accessors long lastSeenTimestamp
	
	@Accessors List<Application> applications = new ArrayList<Application>
	
	@Accessors var boolean visible = true

	@Accessors NodeGroup parent
	
	@Accessors var boolean LockedUntilExecutionActionFinished = false;
	
	public def String getDisplayName() {
		if (this.parent.opened) {
			if (this.ipAddress != null && !this.ipAddress.empty && !this.ipAddress.startsWith("<")) {
				this.ipAddress
			} else {
				this.name
			}
		} else {
			this.parent.name
		}
	}
	
	def addCPUUtilizationHistoryEntry(double entry){
		//TODO for Capacity Planning
		//implement method
	}
	
	def boolean hasSufficientCPUUilizationHistoryEntries(){
		//TODO for Capacity Planning
		//implement method
		return false;
	}
	
	def void removeApplication(int id){
		for(Application n: applications){
			if(n.getId() == id){
				applications.remove(n);
				return;
			}
		}
	}
	
	override void destroy() {
		applications.forEach[it.destroy()]
		super.destroy()
	}	
	
}
