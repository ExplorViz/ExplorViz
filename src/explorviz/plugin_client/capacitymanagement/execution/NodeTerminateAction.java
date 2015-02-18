package explorviz.plugin_client.capacitymanagement.execution;

import explorviz.plugin_server.capacitymanagement.cloud_control.ICloudController;
import explorviz.plugin_server.capacitymanagement.loadbalancer.LoadBalancersFacade;
import explorviz.shared.model.Application;
import explorviz.shared.model.Node;
import explorviz.shared.model.helper.GenericModelElement;

public class NodeTerminateAction extends ExecutionAction {

	private final Node node;

	public NodeTerminateAction(final Node node) {
		this.node = node;
	}

	@Override
	protected GenericModelElement getActionObject() {
		// sollte kein Problem sein, das Object an sich wird nicht gel�scht
		return node;
	}

	@Override
	protected SyncObject synchronizeOn() {
		// sollte kein Problem sein, das Object an sich wird nicht gel�scht
		return node;
	}

	@Override
	protected void beforeAction() {
		// nothing happens
	}

	@Override
	protected boolean concreteAction(final ICloudController controller) throws Exception {
		return controller.terminateNode(node);
	}

	@Override
	protected void afterAction() {
		node.getParent().removeNode(node.getIpAddress());

		for (Application app : node.getApplications()) {
			LoadBalancersFacade.removeApplication(app.getId(), node.getIpAddress(), app
					.getScalinggroup().getName());

		}
	}

	@Override
	protected void finallyDo() {
		// nothing happens
	}

	@Override
	protected String getLoggingDescription() {
		return "terminating node: " + node.getName() + " with IP: " + node.getIpAddress();
	}

	@Override
	protected ExecutionAction getCompensateAction() {
		return new NodeStartAction(node.getHostname(), node.getFlavor(), node.getImage(),
				node.getApplications(), node.getParent());
	}

}