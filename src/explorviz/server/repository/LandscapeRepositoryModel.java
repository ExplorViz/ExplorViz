package explorviz.server.repository;

import java.io.FileNotFoundException;
import java.util.List;
import java.util.Stack;

import explorviz.live_trace_processing.reader.IPeriodicTimeSignalReceiver;
import explorviz.live_trace_processing.reader.TimeSignalReader;
import explorviz.live_trace_processing.record.IRecord;
import explorviz.live_trace_processing.record.event.*;
import explorviz.live_trace_processing.record.trace.HostApplicationMetaDataRecord;
import explorviz.live_trace_processing.record.trace.Trace;
import explorviz.server.repository.helper.SignatureParser;
import explorviz.shared.model.*;

public class LandscapeRepositoryModel implements IPeriodicTimeSignalReceiver {
	private final Landscape landscape;

	public LandscapeRepositoryModel() {
		landscape = new Landscape();
		updateLandscapeAccess();

		new TimeSignalReader(10 * 1000, this).start();
	}

	private void updateLandscapeAccess() {
		landscape.setHash(System.nanoTime());
	}

	public final Landscape getCurrentLandscape() {
		synchronized (landscape) {
			return landscape; // TODO clone?
		}
	}

	public final Landscape getLandscape(final long timestamp) {
		try {
			return RepositoryStorage.readFromFile(timestamp);
		} catch (final FileNotFoundException e) {
			e.printStackTrace();
		}

		return landscape; // TODO do something more intelligent if fails
	}

	public void reset() {
		synchronized (landscape) {
			landscape.getApplicationCommunication().clear();
			landscape.getNodeGroups().clear();
			updateLandscapeAccess();
		}
	}

	@Override
	public void periodicTimeSignal(final long timestamp) {
		synchronized (landscape) {
			RepositoryStorage.writeToFile(landscape, timestamp);
			resetCommunication();
		}

		RepositoryStorage.cleanUpTooOldFiles(timestamp);
	}

	private void resetCommunication() {
		for (final NodeGroup nodeGroup : landscape.getNodeGroups()) {
			for (final Node node : nodeGroup.getNodes()) {
				for (final Application application : node.getApplications()) {
					for (final explorviz.shared.model.CommunicationClazz commu : application
							.getCommuncations()) {
						commu.setRequestsPerSecond(0);
					}
				}
			}
		}

		for (final Communication commu : landscape.getApplicationCommunication()) {
			commu.setRequestsPerSecond(0);
		}

		updateLandscapeAccess();
	}

	public void insertIntoModel(final IRecord inputIRecord) {
		if (inputIRecord instanceof Trace) {
			final Trace trace = (Trace) inputIRecord;

			// TODO really only valid traces?
			if (trace.isValid()) {
				// TODO build multi threaded? and with caches
				final HostApplicationMetaDataRecord hostApplicationRecord = trace.getTraceEvents()
						.get(0).getHostApplicationMetadata();

				synchronized (landscape) {
					final Node node = seekOrCreateNode(hostApplicationRecord.getHostname());
					final Application application = seekOrCreateApplication(node,
							hostApplicationRecord.getApplication());

					createCommunicationInApplication(trace.getTraceEvents(), application);

					updateLandscapeAccess();
				}
			}
		}
	}

	private void createCommunicationInApplication(final List<AbstractEventRecord> events,
			final Application application) {
		Clazz callerClazz = null;
		final Stack<Clazz> callerClazzesHistory = new Stack<Clazz>();

		for (final AbstractEventRecord event : events) {
			if (event instanceof AbstractBeforeEventRecord) {
				final AbstractBeforeEventRecord abstractBeforeEventRecord = (AbstractBeforeEventRecord) event;

				final String fullQName = getClazzFullQName(abstractBeforeEventRecord
						.getOperationSignature());
				final Clazz currentClazz = seekOrCreateClazz(fullQName, application);

				if (callerClazz != null) {
					seekOrCreateCall(callerClazz, currentClazz, application,
							abstractBeforeEventRecord.getRuntimeStatisticInformation().getCount(),
							abstractBeforeEventRecord.getRuntimeStatisticInformation().getAverage());
				}

				callerClazz = currentClazz;
				callerClazzesHistory.push(currentClazz);
			} else if ((event instanceof AbstractAfterEventRecord)
					|| (event instanceof AbstractAfterFailedEventRecord)) {
				callerClazz = callerClazzesHistory.pop();
			}
		}
	}

	private CommunicationClazz seekOrCreateCall(final Clazz caller, final Clazz callee,
			final Application application, final int count, final double average) {

		for (final CommunicationClazz commu : application.getCommuncations()) {
			if ((commu.getSource() == caller) && (commu.getTarget() == callee)) {
				commu.setRequestsPerSecond(commu.getRequestsPerSecond() + count);
				commu.setAverageResponseTime(average); // TODO add?
				return commu;
			}
		}

		final CommunicationClazz commu = new CommunicationClazz();

		commu.setSource(caller);
		commu.setTarget(callee);

		commu.setRequestsPerSecond(count);
		commu.setAverageResponseTime(average);

		application.getCommuncations().add(commu);

		return commu;
	}

	private Clazz seekOrCreateClazz(final String fullQName, final Application application) {
		final String[] splittedName = fullQName.split("\\.");
		return seekrOrCreateClazzHelper(fullQName, splittedName, application, null, 0);
	}

	private Clazz seekrOrCreateClazzHelper(final String fullQName, final String[] splittedName,
			final Application application, final Component parent, final int index) {
		final String currentPart = splittedName[index];

		if (index < (splittedName.length - 1)) {
			List<Component> list = null;

			if (parent == null) {
				list = application.getComponents();
			} else {
				list = parent.getChildren();
			}

			for (final Component component : list) {
				if (component.getName().equalsIgnoreCase(currentPart)) {
					return seekrOrCreateClazzHelper(fullQName, splittedName, application,
							component, index + 1);
				}
			}
			final Component component = new Component();
			String fullQNameComponent = "";
			for (int i = 0; i <= index; i++) {
				fullQNameComponent += splittedName[i] + ".";
			}
			fullQNameComponent = fullQNameComponent.substring(0, fullQNameComponent.length() - 1);
			component.setFullQualifiedName(fullQNameComponent);
			component.setName(currentPart);
			list.add(component);
			return seekrOrCreateClazzHelper(fullQName, splittedName, application, component,
					index + 1);
		} else {
			for (final Clazz clazz : parent.getClazzes()) {
				if (clazz.getName().equalsIgnoreCase(currentPart)) {
					return clazz;
				}
			}
			final Clazz clazz = new Clazz();
			clazz.setInstanceCount(20);
			clazz.setName(currentPart);
			clazz.setFullQualifiedName(fullQName);
			parent.getClazzes().add(clazz);
			return clazz;
		}
	}

	private String getClazzFullQName(final String operationSignatureStr) {
		final String fullQName = SignatureParser.parse(operationSignatureStr, false)
				.getFullQualifiedName();

		if (fullQName.indexOf("$") > 0) {
			return fullQName.substring(0, fullQName.indexOf("$"));
		} else {
			return fullQName;
		}
	}

	private Node seekOrCreateNode(final String hostname) {
		for (final NodeGroup nodeGroup : landscape.getNodeGroups()) {
			for (final Node node : nodeGroup.getNodes()) {
				if (node.getName().equalsIgnoreCase(hostname)) {
					return node;
				}
			}
		}

		final Node node = new Node();
		node.setIpAddress(hostname); // TODO
		node.setName(hostname);

		final NodeGroup nodeGroup = new NodeGroup();
		nodeGroup.getNodes().add(node);

		landscape.getNodeGroups().add(nodeGroup);

		return node;
	}

	private Application seekOrCreateApplication(final Node node, final String applicationName) {
		for (final Application application : node.getApplications()) {
			if (application.getName().equalsIgnoreCase(applicationName)) {
				return application;
			}
		}

		final Application application = new Application();
		application.setDatabase(false);
		application.setId((node.getName() + applicationName).hashCode());
		application.setLastUsage(System.nanoTime());
		application.setName(applicationName);

		node.getApplications().add(application);
		return application;
	}
}
