package explorviz.plugin_server.capacitymanagement.execution;

import java.util.List;

import explorviz.plugin_client.capacitymanagement.execution.SyncObject;
import explorviz.plugin_server.capacitymanagement.CapManRealityMapper;
import explorviz.plugin_server.capacitymanagement.cloud_control.ICloudController;
import explorviz.plugin_server.capacitymanagement.loadbalancer.ScalingGroup;
import explorviz.plugin_server.capacitymanagement.loadbalancer.ScalingGroupRepository;
import explorviz.shared.model.Application;
import explorviz.shared.model.Node;
import explorviz.shared.model.helper.GenericModelElement;

public class NodeTerminateAction extends ExecutionAction {

	private final Node node;
	private final String ipAddress;
	private List<Application> apps;

	public NodeTerminateAction(final Node node) {
		this.node = node;
		ipAddress = node.getIpAddress();
		apps = CapManRealityMapper.getApplicationsFromNode(ipAddress);
	}

	@Override
	protected GenericModelElement getActionObject() {
		// sollte kein Problem sein, das Object an sich wird nicht gelöscht
		return node;
	}

	@Override
	protected SyncObject synchronizeOn() {
		// sollte kein Problem sein, das Object an sich wird nicht gelöscht
		return node;
	}

	@Override
	protected void beforeAction() {
		// nothing happens
	}

	@Override
	protected boolean concreteAction(final ICloudController controller,
			ScalingGroupRepository repository) throws Exception {
		for (Application app : apps) {
			String scalinggroupName = app.getScalinggroupName();
			ScalingGroup scalinggroup = repository.getScalingGroupByName(scalinggroupName);
			controller.terminateApplication(app, scalinggroup);
			scalinggroup.removeApplication(app);
		}
		boolean success = controller.terminateNode(node);
		return success;
	}

	@Override
	protected void afterAction() {
		node.getParent().removeNode(ipAddress);
		CapManRealityMapper.removeNode(ipAddress);
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
		return new NodeStartAction(node.getHostname(), node.getFlavor(), node.getImage(), apps,
				node.getParent());
	}

	@Override
	protected void compensate(ICloudController controller, ScalingGroupRepository repository)
			throws Exception {
		// TODO jkr jek: neuer Knoten mit anderer IP als compensate sinnvoll?
		// wichtig wäre wahrscheinlich vor allem Aufräumen in Mapper und
		// scalinggroups?
		String newIp = "null";
		if (!controller.instanceExisting(node.getHostname())) {
			CapManRealityMapper.removeNode(ipAddress);
			newIp = controller.startNode(node.getParent(), node);
			if (newIp != "null") {
				node.setIpAddress(newIp);
				CapManRealityMapper.addNode(newIp);
				for (Application app : apps) {
					String scalinggroupName = app.getScalinggroupName();
					ScalingGroup scalinggroup = repository.getScalingGroupByName(scalinggroupName);
					String pid = controller.startApplication(app, scalinggroup);
					if (!pid.equals("null")) {
						scalinggroup.addApplication(app);
						CapManRealityMapper.addApplicationtoNode(newIp, app);
					}
				}
			}
		}
	}

}
