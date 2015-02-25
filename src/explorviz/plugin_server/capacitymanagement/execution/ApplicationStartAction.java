package explorviz.plugin_server.capacitymanagement.execution;

import explorviz.plugin_client.capacitymanagement.execution.SyncObject;
import explorviz.plugin_server.capacitymanagement.cloud_control.ICloudController;
import explorviz.shared.model.Application;
import explorviz.shared.model.Node;
import explorviz.shared.model.helper.GenericModelElement;

public class ApplicationStartAction extends ExecutionAction {

	private final Application newApp;
	private final Node parent;
	private final String appName;

	private String pid;

	public ApplicationStartAction(Application newApp) {
		this.newApp = newApp;
		appName = newApp.getName();
		parent = newApp.getParent();

	}

	@Override
	protected GenericModelElement getActionObject() {

		return newApp;
	}

	@Override
	protected SyncObject synchronizeOn() {
		return newApp;
	}

	@Override
	protected void beforeAction() {
		lockingNodeForApplications(parent);
	}

	@Override
	protected boolean concreteAction(ICloudController controller) throws Exception {
		pid = controller.startApplication(newApp);
		return !pid.equals("null");
	}

	@Override
	protected void afterAction() {
		newApp.setPid(pid);
	}

	@Override
	protected void finallyDo() {
		unlockingNodeForApplications(parent);

	}

	@Override
	protected String getLoggingDescription() {
		return "starting application " + appName + " on node " + parent.getName();

	}

	@Override
	protected ExecutionAction getCompensateAction() {
		// just thought as compensateAction for terminating Apps and inside of
		// ReplicateNode, so compensate would never be called here
		return null;
	}

}
