package explorviz.plugin_server.capacitymanagement.execution;

import java.util.ArrayList;
import java.util.List;

import explorviz.plugin_client.attributes.IPluginKeys;
import explorviz.plugin_client.capacitymanagement.CapManExecutionStates;
import explorviz.plugin_client.capacitymanagement.execution.SyncObject;
import explorviz.plugin_server.capacitymanagement.CapManRealityMapper;
import explorviz.plugin_server.capacitymanagement.cloud_control.ICloudController;
import explorviz.plugin_server.capacitymanagement.loadbalancer.ScalingGroup;
import explorviz.plugin_server.capacitymanagement.loadbalancer.ScalingGroupRepository;
import explorviz.shared.model.Application;
import explorviz.shared.model.Node;
import explorviz.shared.model.helper.GenericModelElement;

/**
 *
 * Action which restarts a node and its applications.
 *
 */
public class NodeRestartAction extends ExecutionAction {

	private final Node node;
	private final String ipAddress;
	List<Application> apps;
	List<Integer> runningApps = new ArrayList<Integer>();

	public NodeRestartAction(final Node node) {
		this.node = node;
		ipAddress = node.getIpAddress();
		apps = CapManRealityMapper.getApplicationsFromNode(ipAddress);
	}

	@Override
	protected GenericModelElement getActionObject() {
		return node;
	}

	@Override
	protected SyncObject synchronizeOn() {
		return node;
	}

	@Override
	protected void beforeAction() {

	}

	@Override
	protected boolean concreteAction(final ICloudController controller,
			ScalingGroupRepository repository) throws Exception {

		node.putGenericData(IPluginKeys.CAPMAN_EXECUTION_STATE, CapManExecutionStates.RESTARTING);
		for (Application app : apps) {
			if (controller.checkApplicationIsRunning(ipAddress, app.getPid(), app.getName())) {
				String scalinggroupName = app.getScalinggroupName();
				ScalingGroup scalinggroup = repository.getScalingGroupByName(scalinggroupName);
				scalinggroup.removeApplication(app);
				runningApps.add(apps.indexOf(app));
				controller.terminateApplication(app, scalinggroup); // success
				// is
				// not important
				// here
			}
		}
		boolean success = controller.restartNode(node);

		if (success) {
			String pid;
			for (int i : runningApps) {
				Application app = apps.get(i);
				String scalinggroupName = app.getScalinggroupName();
				ScalingGroup scalinggroup = repository.getScalingGroupByName(scalinggroupName);
				pid = controller.startApplication(app, scalinggroup);
				if (pid == null) {
					return false;
				} else {
					app.setPid(pid);
					CapManRealityMapper.setApplication(ipAddress, app);
					scalinggroup.addApplication(app);
				}

			}
		}
		return success;
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
		return "restarting node " + node.getName() + " with IP: " + node.getIpAddress();
	}

	@Override
	protected ExecutionAction getCompensateAction() {
		return null;
	}

	@Override
	protected void compensate(ICloudController controller, ScalingGroupRepository repository) {
		// TODO: jek/jkr: sicherstellen, dass node und applications wieder
		// laufen
		if (!controller.instanceExistingByIpAddress(ipAddress)) {
			CapManRealityMapper.removeNode(ipAddress);
		} else {
			for (Application app : CapManRealityMapper.getApplicationsFromNode(ipAddress)) {
				if (!controller.checkApplicationIsRunning(ipAddress, app.getPid(), app.getName())) {
					String scalinggroupName = app.getScalinggroupName();
					ScalingGroup scalinggroup = repository.getScalingGroupByName(scalinggroupName);
					scalinggroup.removeApplication(app);
					CapManRealityMapper.removeApplicationFromNode(ipAddress, app.getName());
				}
			}
		}

	}

}
