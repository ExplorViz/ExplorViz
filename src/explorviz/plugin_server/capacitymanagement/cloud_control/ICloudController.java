package explorviz.plugin_server.capacitymanagement.cloud_control;

import explorviz.shared.model.*;

public interface ICloudController {

	/**
	 * @param scalingGroup
	 *            Arraylist of Nodes in Landscape.
	 * @return null or started node (within NodeGroup)
	 * @throws Exception
	 *             If thrown shutdown Node and write error into Log.
	 */
	Node startNode(NodeGroup nodegroup) throws Exception;

	Node cloneNode(NodeGroup nodegroup, Node originalNode) throws Exception;

	/**
	 * @param node
	 *            Nodeobject from Landscape.
	 */

	boolean shutdownNode(Node node) throws Exception;

	boolean restartNode(Node node) throws Exception;

	boolean restartApplication(Application application) throws Exception;

	boolean terminateApplication(Application application) throws Exception;

	boolean migrateApplication(Application application, Node node) throws Exception;

}