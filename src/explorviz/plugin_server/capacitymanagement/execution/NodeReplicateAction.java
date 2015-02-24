package explorviz.plugin_server.capacitymanagement.execution;

import explorviz.plugin_client.capacitymanagement.execution.SyncObject;
import explorviz.plugin_server.capacitymanagement.cloud_control.ICloudController;
import explorviz.plugin_server.capacitymanagement.loadbalancer.ScalingGroup;
import explorviz.plugin_server.capacitymanagement.loadbalancer.ScalingGroupRepository;
import explorviz.shared.model.*;
import explorviz.shared.model.helper.GenericModelElement;

public class NodeReplicateAction extends ExecutionAction {

	private final Node originalNode;
	private Node newNode;
	private final NodeGroup parent;

	public NodeReplicateAction(final Node originalNode) {
		this.originalNode = originalNode;
		parent = originalNode.getParent();
	}

	@Override
	protected GenericModelElement getActionObject() {

		return originalNode;
	}

	@Override
	protected SyncObject synchronizeOn() {

		return originalNode;
	}

	@Override
	protected void beforeAction() {
		// nothing happens
	}

	@Override
	protected boolean concreteAction(final ICloudController controller,
			ScalingGroupRepository repository) throws Exception {

		newNode = controller.replicateNode(parent, originalNode);

		if (newNode == null) {
			state = ExecutionActionState.ABORTED;
			return false;
		} else {
			parent.addNode(newNode);
			newNode.setCpuUtilization(0);
			newNode.setParent(parent);

			for (Application app : originalNode.getApplications()) {
				String scalinggroupName = app.getScalinggroupName();
				ScalingGroup scalinggroup = repository.getScalingGroupByName(scalinggroupName);

				String pid = controller.startApplication(app, scalinggroup);
				if (!pid.equals("null")) {
					Application new_app = new Application();
					new_app.setName(app.getName());
					new_app.setCommunications(app.getCommunications());
					new_app.setComponents(app.getComponents());
					new_app.setIncomingCommunications(app.getIncomingCommunications());
					new_app.setOutgoingCommunications(app.getOutgoingCommunications());
					new_app.setLastUsage(0);
					new_app.setParent(newNode);
					new_app.setScalinggroupName(scalinggroupName);
					scalinggroup.addApplication(new_app);
				} else {
					return false;
				}

			}
			return true;
		}
	}

	@Override
	protected void afterAction() {

	}

	@Override
	protected void finallyDo() {
		// nothing happens
	}

	@Override
	protected String getLoggingDescription() {

		return "replicating node: " + originalNode.getName() + "with IP: "
				+ originalNode.getIpAddress();
	}

	@Override
	protected ExecutionAction getCompensateAction() {
		return new NodeTerminateAction(newNode);
	}

	@Override
	protected boolean checkBeforeAction(ICloudController controller) {
		return (ExecutionOrganizer.maxRunningNodesLimit < controller.retrieveRunningNodeCount());

	}

}
