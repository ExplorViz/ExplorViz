package explorviz.plugin_server.capacitymanagement.cloud_control.openstack;

import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import explorviz.plugin_client.capacitymanagement.configuration.CapManConfiguration;
import explorviz.plugin_server.capacitymanagement.cloud_control.ICloudController;
import explorviz.plugin_server.capacitymanagement.cloud_control.common.*;
import explorviz.shared.model.*;

/**
 * Controls access to an OpenStackCloud. realizes Node-funcionality with
 * Nova-Client. Access to Applications via ssh.
 *
 * @author jek, jkr:
 *
 */

// TODO get-Methoden umbenennen
public class OpenStackCloudController implements ICloudController {

	private static final Logger LOG = LoggerFactory.getLogger(OpenStackCloudController.class);

	private final String keyPairName;

	private final String sshUsername;
	private final String sshPrivateKey;

	private final String systemMonitoringFolder;
	private final String startSystemMonitoringScript;

	/**
	 * Constructor.
	 *
	 * @param settings
	 *            CapManConfigurationFile
	 */
	public OpenStackCloudController(final CapManConfiguration settings) {

		keyPairName = settings.getCloudKey();

		sshPrivateKey = settings.getSSHPrivateKey();
		sshUsername = settings.getSSHUsername();

		systemMonitoringFolder = settings.getSystemMonitoringFolder();
		startSystemMonitoringScript = settings.getStartSystemMonitoringScript();
	}

	// TODO: jkr return only IPadress
	@Override
	public Node startNode(final NodeGroup nodegroup, Node nodeToStart) {
		try {
			String instanceId = bootNewNodeInstanceFromImage(nodeToStart.getHostname(), nodegroup,
					nodeToStart.getImage(), nodeToStart.getFlavor());
			String privateIP = getPrivateIPFromInstance(instanceId);
			nodeToStart.setId(instanceId);
			nodeToStart.setIpAddress(privateIP);
			copyAllApplicationsToInstance(privateIP, nodeToStart);
			startAllApplicationsOnInstance(privateIP, nodeToStart);
		} catch (final Exception e) {
			LOG.error(e.getMessage(), e);
			// compensate
			shutDownNodeByHostname(nodeToStart.getHostname());
			return null;
		}

		return nodeToStart;
	}

	@Override
	// TODO jkr: werden Application automatisch gestartet? Erfolg pr�fen!
	public boolean restartNode(final Node node) throws Exception {
		final String hostname = getHostnameFromNode(node);
		LOG.info("CloudController: restarting node " + hostname);
		final String command = "restart " + hostname;
		try {
			TerminalCommunication.executeNovaCommand(command);
		} catch (final Exception e) {
			LOG.info("Error during restarting node " + hostname);
			return false;
		}
		return true;
	}

	public String getIdFromNode(final Node node) throws Exception {
		String id = node.getId();
		if (id == null) {
			final String command = " list";
			final List<String> output = TerminalCommunication.executeNovaCommand(command);
			final String ipAddress = node.getIpAddress();
			for (final String row : output) {
				if (row.contains(ipAddress)) {
					final int end = row.indexOf(" | ", 1);
					id = row.substring(1, end).trim();
				}
			}
			node.setId(id);
		}

		return id;
	}

	public String getImageFromNode(final Node node) throws Exception {
		String image = node.getImage();
		if (image == null) {
			final String id = getIdFromNode(node);
			final String command = " show  " + id;
			final List<String> output = TerminalCommunication.executeNovaCommand(command);
			final StringToMapParser parser = new OpenStackOutputParser();
			parser.parseAndAddStringList(output);
			final String imageString = parser.getMap().get("image");
			// check whether also Id of image is present
			if (imageString.contains("(")) {
				final int end = imageString.indexOf(" (");
				image = imageString.substring(0, end);
			} else {
				image = imageString;
			}
			node.setImage(image);
		}
		return image;
	}

	// TODO: jek: change visibility
	public String getHostnameFromNode(final Node node) throws Exception {
		String hostname = node.getHostname();
		if (hostname == null) {
			final String command = "list";
			final List<String> output = TerminalCommunication.executeNovaCommand(command);
			final String ipAddress = node.getIpAddress();
			for (final String row : output) {
				if (row.contains(ipAddress)) {
					if (row.contains(node.getName())) {
						hostname = node.getName();
					} else {
						final int start = row.indexOf(" | ", 1) + 2; // zweite
						// Spalte
						final int end = row.substring(start).indexOf(" |") + start;
						hostname = row.substring(start, end).trim();
					}
				}
			}
			node.setHostname(hostname);
		}
		return hostname;
	}

	// TODO change visibility
	public String getStatusOfInstance(final String ipAddress) throws Exception {
		String status = "unknown";
		String[] columns;
		final String command = "list";
		final List<String> output = TerminalCommunication.executeNovaCommand(command);
		for (final String row : output) {
			if (row.contains(ipAddress)) {
				columns = row.split(" | ");
				status = columns[5];
				for (String column : columns) {
					java.lang.System.out.println(column);
				}
				return status;
			}
		}
		return status;
	}

	@Override
	public boolean terminateApplication(final Application application) {
		String privateIP = application.getParent().getIpAddress();
		ScalingGroup scalingGroup = application.getScalinggroup();
		String pid = application.getPid();
		String name = application.getName();
		try {

			LOG.info("terminating Application " + pid);

			SSHCommunication.runScriptViaSSH(privateIP, sshUsername, sshPrivateKey, "kill " + pid);
			waitFor(scalingGroup.getWaitTimeForApplicationStartInMillis(), "application terminate");
		} catch (final Exception e) {
			LOG.error("Error during terminating application" + name + e.getMessage());
			return false;
		}
		return !checkApplicationIsRunning(privateIP, pid, name);

	}

	@Override
	public boolean migrateApplication(final Application application, final Node node) {
		// TODO Auto-generated method stub
		return false;
	}

	@Override
	public boolean restartApplication(final Application application) {
		Node parent = application.getParent();
		final String privateIP = parent.getIpAddress();
		final String name = application.getName();
		String pid = application.getPid();

		if (terminateApplication(application)) {

			try {
				startApplicationOnInstance(privateIP, application.getScalinggroup(), name);
			} catch (final Exception e) {
				LOG.info("Error during restarting application" + name + e.getMessage());
				return false;
			}
		} else {
			return false;
		}
		return checkApplicationIsRunning(privateIP, pid, name);

	}

	// TODO: jkr return only IPadress
	@Override
	public Node replicateNode(final NodeGroup nodegroup, final Node originalNode) {
		final String hostname = nodegroup.generateNewUniqueHostname();

		try {
			final String image = createImageFromInstance(getHostnameFromNode(originalNode));
			final String flavor = getFlavorFromNode(originalNode);
			final String instanceId = bootNewNodeInstanceFromImage(hostname, nodegroup, image,
					flavor);

			waitForInstanceStart(120, hostname, 1000);

			final String privateIP = getPrivateIPFromInstance(instanceId);

			// copyAllApplicationsToInstance(privateIP, originalNode);
			// startAllApplicationsOnInstance(privateIP, originalNode);

			copySystemMonitoringToInstance(privateIP);
			startSystemMonitoringOnInstance(privateIP);

			LOG.info("Successfully started node " + hostname + " on " + privateIP);

			final Node newNode = new Node();
			newNode.setIpAddress(privateIP);
			newNode.setHostname(hostname);
			newNode.setImage(image);
			newNode.setFlavor(flavor);
			newNode.setId(getIdFromNode(newNode));
			return newNode;
		} catch (final Exception e) {
			LOG.error(e.getMessage(), e);
			// compensate
			shutDownNodeByHostname(hostname);
			return null;
		}

	}

	public String getFlavorFromNode(Node node) throws Exception {
		String flavor = node.getFlavor();
		if (flavor == null) {
			final String id = getIdFromNode(node);
			final String command = " show  " + id;
			final List<String> output = TerminalCommunication.executeNovaCommand(command);
			final StringToMapParser parser = new OpenStackOutputParser();
			parser.parseAndAddStringList(output);
			final String flavorString = parser.getMap().get("flavor");
			// check whether also Id of image is present
			if (flavorString.contains("(")) {
				final int end = flavorString.indexOf(" (");
				flavor = flavorString.substring(0, end);
			} else {
				flavor = flavorString;
			}
			node.setImage(flavor);
		}
		return flavor;
	}

	/**
	 * Start new instance within NodeGroup with newly generated hostname.
	 *
	 * @param hostname
	 *            New generated (startNode) unique hostname.
	 * @param nodeGroup
	 *            NodeGroup in which the instance should be started.
	 * @return Id of new Instance.
	 * @throws Exception
	 *             E.g. booterror.
	 */
	private String bootNewNodeInstanceFromImage(final String hostname, final NodeGroup nodegroup,
			final String image, final String flavor) throws Exception {
		LOG.info("Starting new instance in node group " + nodegroup.getName() + "...");
		final String bootCommand = "boot " + hostname + " --image " + image + " --flavor " + flavor
				+ " --key_name " + keyPairName;

		final List<String> output = TerminalCommunication.executeNovaCommand(bootCommand);

		final StringToMapParser parser = new OpenStackOutputParser();
		parser.parseAndAddStringList(output);

		final String instanceId = parser.getMap().get("id");

		if ((instanceId == null) || instanceId.isEmpty()
				|| "Error".equalsIgnoreCase(parser.getMap().get("status"))) {
			throw new Exception("Error at instance boot!");
		}

		return instanceId;
	}

	private String getFlavorFromHostname(String hostname) {
		// TODO jek implement
		return null;
	}

	/**
	 * @param retryCount
	 *            Number of retries before throwing exception.
	 * @param instanceId
	 *            Id of Nodeinstance to be started.
	 * @param sleepTimeInMilliseconds
	 *            Do nothing.
	 * @throws Exception
	 *             If Nodeinstance could not be started.
	 */
	private void waitForInstanceStart(int retryCount, final String hostname,
			final int sleepTimeInMilliseconds) throws Exception {
		LOG.info("Waiting for instance to start...");

		boolean started = false;
		while (retryCount > 0) {
			try {
				final List<String> statusOutput = TerminalCommunication
						.executeNovaCommand("console-log --length 10 " + hostname);

				for (final String outputline : statusOutput) {
					final String line = outputline.toLowerCase();
					if (line.contains("finished at ")) {
						LOG.info(line);
						started = true;
						break;
					}
				}
			} catch (final Exception e) {
				final String errorString = e.getMessage().toLowerCase();
				if (errorString.contains("error: instance") && errorString.contains("is not ready")) {
					started = false;
					LOG.info(e.getMessage(), e);
				}
			}

			if (started) {
				break;
			}
			try {
				Thread.sleep(sleepTimeInMilliseconds);
			} catch (final InterruptedException e) {
			}

			retryCount--;
		}

		if (!started) {
			throw new Exception("Instance could not be started");
		}
	}

	/**
	 * @param instanceId
	 *            Instanceid to get ip from.
	 * @return Ip of Nodeinstance.
	 * @throws Exception
	 *             If private IP address not available.
	 */
	private String getPrivateIPFromInstance(final String instanceId) throws Exception {
		LOG.info("Getting private IP for instance " + instanceId);
		final List<String> output = TerminalCommunication.executeNovaCommand("show " + instanceId);
		final StringToMapParser parser = new OpenStackOutputParser();
		parser.parseAndAddStringList(output);

		final String privateIP = parser.getMap().get("vmnet network");

		if ((privateIP == null) || privateIP.equals("")) {
			throw new Exception("Private IP address not available.");
		}

		return privateIP;
	}

	// TODO:jkr: Absichern und change visibility
	public String createImageFromInstance(final String hostname) throws Exception {
		final String imageName = hostname + "Image";
		LOG.info("Getting Image from " + hostname);
		TerminalCommunication.executeNovaCommand("image-create " + hostname + " " + imageName);
		return imageName;
	}

	/**
	 * Copy application to instance of Node.
	 *
	 * @param privateIP
	 *            Ip of Node for application to be copied.
	 * @param nodeGroup
	 *            Arraylist containing Node.
	 * @throws Exception
	 *             Copying failed.
	 */
	private void copyApplicationToInstance(final String privateIP, final Application app)
			throws Exception {
		LOG.info("Copying application '" + app.getScalinggroup().getApplicationFolder()
				+ "' to node " + privateIP);

		final String copyApplicationCommand = "scp -o stricthostkeychecking=no -i " + sshPrivateKey
				+ " -r " + app.getScalinggroup().getApplicationFolder() + " " + sshUsername + "@"
				+ privateIP + ":/home/" + sshUsername + "/";

		TerminalCommunication.executeNovaCommand(copyApplicationCommand);
	}

	private void copyAllApplicationsToInstance(final String privateIP, final Node originalNode)
			throws Exception {

		for (final Application app : originalNode.getApplications()) {
			copyApplicationToInstance(privateIP, app);

		}
	}

	/**
	 * Start application on instance of Node.
	 *
	 * @param privateIP
	 *            Ip of Node for application to be started.
	 * @param nodegroup
	 *            Arraylist containing Node.
	 * @throws Exception
	 *             Starting the application failed.
	 */
	@Override
	// TODO: change name and change inputparameter to script instead of
	// scalinggroup
	public String startApplicationOnInstance(final String privateIP,
			final ScalingGroup scalingGroup, final String name) throws Exception {
		String startscript = scalingGroup.getStartApplicationScript();
		LOG.info("Starting application script - " + startscript + " - on node " + privateIP);
		List<String> output = new ArrayList<String>();
		output = SSHCommunication.runScriptViaSSH(privateIP, sshUsername, sshPrivateKey,
				startscript);
		waitFor(scalingGroup.getWaitTimeForApplicationStartInMillis(), "application start");
		if (!output.isEmpty() && (output.get(0) != null)) {

			if (checkApplicationIsRunning(privateIP, output.get(0), name)) {
				return output.get(0);
			}
		}
		return "null";

	}

	private void startAllApplicationsOnInstance(final String privateIP, final Node node)
			throws Exception {
		for (final Application app : node.getApplications()) {
			startApplicationOnInstance(privateIP, app.getScalinggroup(), app.getName());

		}
	}

	private void waitFor(final int millis, final String description) {
		LOG.info("Waiting " + millis + " milliseconds for " + description + "...");
		try {
			Thread.sleep(millis);
		} catch (final InterruptedException e) {
		}
	}

	/**
	 * @param privateIP
	 *            Ip of Node for Application.
	 * @throws Exception
	 *             Copying System Monitoring failed.
	 */
	private void copySystemMonitoringToInstance(final String privateIP) throws Exception {
		LOG.info("Copying system monitoring '" + systemMonitoringFolder + "' to node " + privateIP);

		final String copySystemMonitoringCommand = "scp -o stricthostkeychecking=no -i "
				+ sshPrivateKey + " -r " + systemMonitoringFolder + " " + sshUsername + "@"
				+ privateIP + ":/home/" + sshUsername + "/";

		TerminalCommunication.executeNovaCommand(copySystemMonitoringCommand);
	}

	private void startSystemMonitoringOnInstance(final String privateIP) throws Exception {
		LOG.info("Starting system monitoring script - " + startSystemMonitoringScript
				+ " - on node " + privateIP);

		SSHCommunication.runScriptViaSSH(privateIP, sshUsername, sshPrivateKey,
				startSystemMonitoringScript);
	}

	private void shutDownNodeByHostname(final String hostName) {

	}

	@Override
	public boolean terminateNode(final Node node) throws Exception {
		LOG.info("Deleting node: " + getHostnameFromNode(node));

		TerminalCommunication.executeNovaCommand("delete " + getHostnameFromNode(node));

		LOG.info("Shut down node: " + getHostnameFromNode(node));
		// �berdenken
		return !instanceExisting(getHostnameFromNode(node));

	}

	/**
	 * It is presumed that exceptions would only be thrown for communication
	 * errors. Therefore, catching them does not influence the rest of the
	 * controller (as all other commands would not work neither)
	 */
	// �berdenken
	private boolean instanceExisting(final String name) {
		final String command = "list";
		List<String> output = new ArrayList<String>();
		try {
			output = TerminalCommunication.executeNovaCommand(command);
		} catch (final Exception e) {
			LOG.error("Error while listing instances " + e.getMessage());
		}
		for (final String outputline : output) {
			if (outputline.contains(name)) {
				return true;
			}
		}
		return false;
	}

	private boolean checkApplicationIsRunning(final String privateIP, final String pid,
			final String name) {
		List<String> pids = new ArrayList<String>();
		try {
			pids = SSHCommunication.runScriptViaSSH(privateIP, sshUsername, sshPrivateKey, "pidof "
					+ name);
		} catch (Exception e) {
			LOG.error("Error while running ssh-command " + e.getMessage());
		}

		for (String v : pids) {
			if (v.equals(pid)) {
				return true;
			}
		}
		return false;
	}

	/**
	 * count number of entries returned from 'nova list' command
	 */
	@Override
	public int retrieveRunningNodeCount() {
		String command = "list ";
		List<String> output = new ArrayList<String>();
		try {
			output = TerminalCommunication.executeNovaCommand(command);
		} catch (Exception e) {
			LOG.error("Error while getting Node Count.");

		}

		return output.size();

	}
}