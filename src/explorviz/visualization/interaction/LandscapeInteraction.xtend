package explorviz.visualization.interaction

import com.google.gwt.i18n.client.DateTimeFormat
import com.google.gwt.i18n.client.DefaultDateTimeFormatInfo
import com.google.gwt.safehtml.shared.SafeHtmlUtils
import com.google.gwt.user.client.Window
import explorviz.shared.model.Application
import explorviz.shared.model.Landscape
import explorviz.shared.model.Node
import explorviz.shared.model.NodeGroup
import explorviz.shared.model.System
import explorviz.shared.model.helper.CommunicationTileAccumulator
import explorviz.visualization.engine.contextmenu.PopupService
import explorviz.visualization.engine.main.ClassnameSplitter
import explorviz.visualization.engine.main.SceneDrawer
import explorviz.visualization.engine.picking.ObjectPicker
import explorviz.visualization.engine.picking.handler.MouseClickHandler
import explorviz.visualization.engine.picking.handler.MouseDoubleClickHandler
import explorviz.visualization.engine.picking.handler.MouseHoverHandler
import explorviz.visualization.engine.picking.handler.MouseRightClickHandler
import explorviz.visualization.engine.popover.PopoverService
import explorviz.visualization.experiment.Experiment
import explorviz.visualization.main.AlertDialogJS
import java.util.Date
import java.util.HashMap
import com.google.gwt.event.shared.HandlerRegistration
import explorviz.visualization.main.JSHelpers
import com.google.gwt.user.client.ui.RootPanel
import com.google.gwt.user.client.Event
import com.google.gwt.event.dom.client.ClickEvent
import explorviz.visualization.landscapeinformation.EventViewer
import explorviz.visualization.landscapeinformation.ErrorViewer
import explorviz.visualization.experiment.tools.ExperimentTools

class LandscapeInteraction {
	static val MouseHoverHandler systemMouseHover = createSystemMouseHoverHandler()
	static val MouseDoubleClickHandler systemMouseDblClick = createSystemMouseDoubleClickHandler()

	static val MouseHoverHandler nodeGroupMouseHover = createNodeGroupMouseHoverHandler()
	static val MouseDoubleClickHandler nodeGroupMouseDblClick = createNodeGroupMouseDoubleClickHandler()

	static val MouseClickHandler nodeMouseClick = createNodeMouseClickHandler()
	static val MouseDoubleClickHandler nodeMouseDblClick = createNodeMouseDoubleClickHandler()
	static val MouseRightClickHandler nodeRightMouseClick = createNodeMouseRightClickHandler()
	static val MouseHoverHandler nodeMouseHoverClick = createNodeMouseHoverHandler()

	static val MouseClickHandler applicationMouseClick = createApplicationMouseClickHandler()
	static val MouseRightClickHandler applicationMouseRightClick = createApplicationMouseRightClickHandler()
	static val MouseDoubleClickHandler applicationMouseDblClick = createApplicationMouseDoubleClickHandler()
	static val MouseHoverHandler applicationMouseHoverClick = createApplicationMouseHoverHandler()

	static val MouseClickHandler communicationMouseClickHandler = createCommunicationMouseClickHandler()
	static val MouseHoverHandler communicationMouseHoverHandler = createCommunicationMouseHoverHandler()

	static HandlerRegistration eventViewHandler
	static HandlerRegistration exceptionViewHandler
	static HandlerRegistration exportAsRunnableHandler

	static val eventViewButtonId = "eventViewerBtn"
	static val exceptionViewButtonId = "exceptionViewerBtn"
//	static val exportAsRunnableButtonId = "exportAsRunnableBtn"	

	static val legendDivId = "legendDiv"

	def static void clearInteraction(Landscape landscape) {
		ObjectPicker::clear()

		for (system : landscape.systems) {
			system.clearAllHandlers()
			for (nodeGroup : system.nodeGroups) {
				nodeGroup.clearAllHandlers()
				for (node : nodeGroup.nodes) {
					node.clearAllHandlers()
					for (application : node.applications)
						application.clearAllHandlers()
				}
			}
		}
		for (commu : landscape.communicationsAccumulated) {
			for (tile : commu.tiles)
				tile.clearAllHandlers()
		}
	}

	def static void createInteraction(Landscape landscape) {
		for (system : landscape.systems)
			createSystemInteraction(system)

		for (commu : landscape.communicationsAccumulated) {
			for (tile : commu.tiles)
				createCommunicationInteraction(tile)
		}

		if (!Experiment::tutorial && !ExperimentTools::toolsModeActive) {
			showAndPrepareEventViewButton(landscape)
			showAndPrepareExceptionViewButton(landscape)
			showAndPrepareExportAsRunnableButton(landscape)

			JSHelpers::showElementById(legendDivId)
		}

	}

	def static void showAndPrepareEventViewButton(Landscape landscape) {
		if (eventViewHandler != null) {
			eventViewHandler.removeHandler
		}

		JSHelpers::showElementById(eventViewButtonId)

		val button = RootPanel::get(eventViewButtonId)

		button.sinkEvents(Event::ONCLICK)
		eventViewHandler = button.addHandler(
			[
			EventViewer::openDialog
		], ClickEvent::getType())
	}

	def static void showAndPrepareExceptionViewButton(Landscape landscape) {
		if (exceptionViewHandler != null) {
			exceptionViewHandler.removeHandler
		}

		JSHelpers::showElementById(exceptionViewButtonId)

		val button = RootPanel::get(exceptionViewButtonId)

		button.sinkEvents(Event::ONCLICK)
		exceptionViewHandler = button.addHandler(
			[
			ErrorViewer::openDialog
		], ClickEvent::getType())
	}

	def static void showAndPrepareExportAsRunnableButton(Landscape landscape) {
		if (exportAsRunnableHandler != null) {
			exportAsRunnableHandler.removeHandler
		}

//		JSHelpers::showElementById(exportAsRunnableButtonId)
//		val button = RootPanel::get(exportAsRunnableButtonId)
//		button.sinkEvents(Event::ONCLICK)
//		exportAsRunnableHandler = button.addHandler(
//			[
//				JSHelpers::downloadAsFile("myLandscape.rb",
//					RunnableLandscapeExporter::exportAsRunnableLandscapeRubyExport(landscape))
//			], ClickEvent::getType())
	}


	def static private createSystemInteraction(System system) {
		system.setMouseHoverHandler(systemMouseHover)
		if (!Experiment::tutorial) {
			system.setMouseDoubleClickHandler(systemMouseDblClick)

			for (nodeGroup : system.nodeGroups)
				createNodeGroupInteraction(nodeGroup)
		} else { // Tutorialmodus active, only set the correct handler, otherwise go further into the system
			val step = Experiment::getStep()
			if (!step.isConnection && step.source.equals(system.name) && step.doubleClick) {
				system.setMouseDoubleClickHandler(systemMouseDblClick)
			} else {
				for (nodeGroup : system.nodeGroups)
					createNodeGroupInteraction(nodeGroup)
			}
		}

	}

	def static private MouseHoverHandler createSystemMouseHoverHandler() {
		[
			val system = (it.object as System)
			val name = system.name
			var nodesCount = 0
			var applicationCount = 0
			for (nodeGroup : system.nodeGroups) {
				nodesCount = nodesCount + nodeGroup.nodes.size()
				for (node : nodeGroup.nodes) {
					applicationCount = applicationCount + node.applications.size()
				}
			}
			PopoverService::showPopover(SafeHtmlUtils::htmlEscape(name), it.originalClickX, it.originalClickY,
				'<table style="width:100%"><tr><td>Nodes:</td><td style="text-align:right;padding-left:10px;">' +
					nodesCount +
					'</td></tr><tr><td>Applications:</td><td style="text-align:right;padding-left:10px;">' +
					applicationCount + '</td></tr></table>')
		]
	}

	def static private MouseDoubleClickHandler createSystemMouseDoubleClickHandler() {
		[
			val system = (it.object as System)
			Usertracking::trackSystemDoubleClick(system)
			system.opened = !system.opened
			Experiment::incTutorial(system.name, false, false, true, false)
			SceneDrawer::createObjectsFromLandscape(system.parent, true)
		]
	}

	def static private createNodeGroupInteraction(NodeGroup nodeGroup) {
		nodeGroup.setMouseHoverHandler(nodeGroupMouseHover)
		if (!Experiment::tutorial) {
			nodeGroup.setMouseDoubleClickHandler(nodeGroupMouseDblClick)

			for (node : nodeGroup.nodes)
				createNodeInteraction(node)
		} else { // Tutorialmodus active, only set correct handler, otherwise go further into the nodegroup
			val step = Experiment::getStep()
			if (!step.isConnection && step.source.equals(nodeGroup.name) && step.doubleClick) {
				nodeGroup.setMouseDoubleClickHandler(nodeGroupMouseDblClick)
			} else {
				for (node : nodeGroup.nodes)
					createNodeInteraction(node)
			}
		}
	}

	def static private MouseHoverHandler createNodeGroupMouseHoverHandler() {
		[
			val nodeGroup = (it.object as NodeGroup)
			Experiment::incTutorial(nodeGroup.name, false, false, true, false)
			val name = nodeGroup.name
			Experiment::incTutorial(name, false, false, false, true)
			var avgNodeCPUUtil = 0d
			var applicationCount = 0
			for (node : nodeGroup.nodes) {
				avgNodeCPUUtil = avgNodeCPUUtil + node.cpuUtilization
				applicationCount = applicationCount + node.applications.size()
			}
			PopoverService::showPopover("[" + SafeHtmlUtils::htmlEscape(name) + "]", it.originalClickX,
				it.originalClickY,
				'<table style="width:100%"><tr><td>Nodes:</td><td style="text-align:right;padding-left:10px;">' +
					nodeGroup.nodes.size() +
					'</td></tr><tr><td>Applications:</td><td style="text-align:right;padding-left:10px;">' +
					applicationCount +
					'</td></tr><tr><td>Avg. CPU Utilization:</td><td style="text-align:right;padding-left:10px;">' +
					Math.round(avgNodeCPUUtil * 100f) / nodeGroup.nodes.size() + '%</td></tr></table>')
		]
	}

	def static private MouseDoubleClickHandler createNodeGroupMouseDoubleClickHandler() {
		[
			val nodeGroup = (it.object as NodeGroup)
			Usertracking::trackNodeGroupDoubleClick(nodeGroup)
			nodeGroup.opened = !nodeGroup.opened
			Experiment::incTutorial(nodeGroup.name, false, false, true, false)
			SceneDrawer::createObjectsFromLandscape(nodeGroup.parent.parent, true)
		]
	}

	def static private createNodeInteraction(Node node) {
		if (node.parent.opened || node.parent.nodes.size() == 1) {
			node.setMouseHoverHandler(nodeMouseHoverClick)
		}

		if (!Experiment::tutorial) {
			node.setMouseClickHandler(nodeMouseClick)
			node.setMouseRightClickHandler(nodeRightMouseClick)
			node.setMouseDoubleClickHandler(nodeMouseDblClick)
			for (application : node.applications)
				createApplicationInteraction(application)
		} else { // Tutorialmodus active, only set correct handler, otherwise go further into the node
			val step = Experiment::getStep()
			if (!step.isConnection && step.source.equals(node.name)) {
				if (step.leftClick) {
					node.setMouseClickHandler(nodeMouseClick)
				} else if (step.rightClick) {
					node.setMouseRightClickHandler(nodeRightMouseClick)
				} else if (step.doubleClick) {
					node.setMouseDoubleClickHandler(nodeMouseDblClick)
				} else if (step.hover) {
					node.setMouseHoverHandler(nodeMouseHoverClick)
				}
			} else {
				for (application : node.applications)
					createApplicationInteraction(application)
			}
		}
	}

	def static private MouseClickHandler createNodeMouseClickHandler() {
		[
			// Usertracking::trackNodeClick(it.object as Node)
			// incStep(node.name, true, false, false, false)
		]
	}

	def static private MouseDoubleClickHandler createNodeMouseDoubleClickHandler() {
		[
			// val node = (it.object as Node)
			// incTutorial(node.name, false, false, true, false)
		]
	}

	def static private MouseRightClickHandler createNodeMouseRightClickHandler() {
		[
			val node = it.object as Node
			Usertracking::trackNodeRightClick(node);
			Experiment::incTutorial(node.name, false, true, false, false)
			PopupService::showNodePopupMenu(it.originalClickX, it.originalClickY, node)
		]
	}

	def static private MouseHoverHandler createNodeMouseHoverHandler() {
		[
			val node = it.object as Node
			val name = node.displayName
			Experiment::incTutorial(node.name, false, false, false, true)
			val otherId = if (node.displayName == node.name && node.ipAddress != null)
					'<tr><td>IP Address:</td><td style="text-align:right;padding-left:10px;">' +
						SafeHtmlUtils::htmlEscape(node.ipAddress) + '</td></tr>'
				else if (node.name != null)
					'<tr><td>Hostname:</td><td style="text-align:right;padding-left:10px;">' +
						SafeHtmlUtils::htmlEscape(node.name) + '</td></tr>'
				else
					''
			PopoverService::showPopover(SafeHtmlUtils::htmlEscape(name), it.originalClickX, it.originalClickY,
				'<table style="width:100%">' + otherId +
					'<tr><td>CPU Utilization:</td><td style="text-align:right;padding-left:10px;">' +
					Math.round(node.cpuUtilization * 100f) +
					'%</td></tr><tr><td>Total RAM:</td><td style="text-align:right;padding-left:10px;">' +
					getTotalRAMInGB(node) +
					' GB</td></tr><tr><td>Free RAM:</td><td style="text-align:right;padding-left:10px;">' +
					getFreeRAMInPercent(node) + '%</td></tr></table>')
		]
	}

	private def static getTotalRAMInGB(Node node) {
		Math.round((node.usedRAM + node.freeRAM) / (1024f * 1024f * 1024f))
	}

	private def static getFreeRAMInPercent(Node node) {
		val totalRAM = node.usedRAM + node.freeRAM
		if (totalRAM > 0L) {
			Math.round(((node.freeRAM as double) / (totalRAM as double)) * 100f)
		} else {
			2
		}
	}

	def static private createApplicationInteraction(Application application) {
		if (!Experiment::tutorial) {
			application.setMouseClickHandler(applicationMouseClick)
			application.setMouseRightClickHandler(applicationMouseRightClick)
			application.setMouseDoubleClickHandler(applicationMouseDblClick)
			application.setMouseHoverHandler(applicationMouseHoverClick)
		} else if (!Experiment::getStep().connection && Experiment::getStep().source.equals(application.name)) {
			val step = Experiment::getStep()
			if (step.leftClick) {
				application.setMouseClickHandler(applicationMouseClick)
			} else if (step.rightClick) {
				application.setMouseRightClickHandler(applicationMouseRightClick)
			} else if (step.doubleClick) {
				application.setMouseDoubleClickHandler(applicationMouseDblClick)
			} else if (step.hover) {
				application.setMouseHoverHandler(applicationMouseHoverClick)
			}
		}
	}

	def static MouseClickHandler createApplicationMouseClickHandler() {
		[
			// incTutorial(app.name, true, false, false, false)
		]
	}

	def static MouseRightClickHandler createApplicationMouseRightClickHandler() {
		[
			val app = it.object as Application
			Usertracking::trackApplicationRightClick(app);
			Experiment::incTutorial(app.name, false, true, false, false)
			PopupService::showApplicationPopupMenu(it.originalClickX, it.originalClickY, app)
		]
	}

	def static MouseDoubleClickHandler createApplicationMouseDoubleClickHandler() {
		[
			val app = it.object as Application
			Usertracking::trackApplicationDoubleClick(app);
			Experiment::incTutorial(app.name, false, false, true, false)
			if (!app.components.empty && !app.components.get(0).children.empty) {
				JSHelpers::hideElementById(eventViewButtonId)
				JSHelpers::hideElementById(exceptionViewButtonId)
//				JSHelpers::hideElementById(exportAsRunnableButtonId)
				JSHelpers::hideElementById(legendDivId)
				SceneDrawer::createObjectsFromApplication(app, false)
			} else {
				AlertDialogJS::showAlertDialog("No Details Available",
					"Sorry, no details for " + app.name + " are available.")
			}
		]
	}

	def static private MouseHoverHandler createApplicationMouseHoverHandler() {
		[
			val application = it.object as Application
			val name = application.name
			Experiment::incTutorial(name, false, false, false, true)
			val lastUsageDate = convertToPrettyTime(application.lastUsage)
			val language = application.programmingLanguage.toString().toLowerCase.toFirstUpper
			PopoverService::showPopover(SafeHtmlUtils::htmlEscape(name), it.originalClickX, it.originalClickY,
				'<table style="width:100%"><tr><td>Last Usage:</td><td style="text-align:right;padding-left:10px;">' +
					lastUsageDate + '</td></tr><tr><td>Language:</td><td style="text-align:right;padding-left:10px;">' +
					language + '</td></tr></table>')
		]
	}

	def static private String convertToPrettyTime(long timeInMillis) {
		val pattern = "yyyy-MM-dd HH:mm"
		val info = new DefaultDateTimeFormatInfo()
		val dtf = new DateTimeFormat(pattern, info) {
		};
		dtf.format(new Date(timeInMillis))
	}

	def static private createCommunicationInteraction(CommunicationTileAccumulator communication) {

		if (!Experiment::tutorial ||
			(Experiment::getStep().connection && !communication.communications.empty &&
				communication.communications.get(0).source.name.equals(Experiment::getStep().source) &&
				communication.communications.get(0).target.name.equals(Experiment::getStep().dest) &&
				Experiment::getStep().leftClick)) {
			communication.setMouseClickHandler(communicationMouseClickHandler)
		}
		communication.setMouseHoverHandler(communicationMouseHoverHandler)
	}

	def static private MouseClickHandler createCommunicationMouseClickHandler() {
		[
			val communication = (it.object as CommunicationTileAccumulator)
			// Experiment::incTutorial(communication.source.name, communication.target.name, true, false)
			Window::alert("Clicked communication with requests per second: " + communication.requestsCache)
		]
	}

	def static private MouseHoverHandler createCommunicationMouseHoverHandler() {
		[
			val accum = (it.object as CommunicationTileAccumulator)
			if (accum.communications.empty) return;
			var sourceNameTheSame = true
			var targetNameTheSame = true
			var previousSourceName = accum.communications.get(0).source.name
			var previousTargetName = accum.communications.get(0).target.name
			val technology = accum.communications.get(0).technology
			val int averageDuration = Math.round(
				accum.communications.get(0).averageResponseTimeInNanoSec / (1000 * 1000))
			for (commu : accum.communications) {
				if (previousSourceName != commu.source.name) {
					sourceNameTheSame = false
				}

				if (previousTargetName != commu.target.name) {
					targetNameTheSame = false
				}

				previousSourceName = commu.source.name
				previousTargetName = commu.target.name
			}
			var title = "Accumulated Communication"
			val arrow = "&nbsp;<span class='glyphicon glyphicon-transfer'></span>&nbsp;"
			var body = ""
			if (sourceNameTheSame && !targetNameTheSame) {
				title = splitName(previousSourceName) + arrow + "..."

				var alreadyOutputedCommu = new HashMap<String, Boolean>

				for (commu : accum.communications) {
					if (alreadyOutputedCommu.get(commu.target.name) == null) {
						var requests = 0
						for (reqCommu : accum.communications) {
							if (reqCommu.target.name == commu.target.name) {
								requests = requests + reqCommu.requests
							}
						}

						body = body + '<tr><td>...</td><td>' + arrow + '</td><td>' + commu.target.name +
							':</td><td style="text-align:right;padding-left:10px;">' + requests + '</td></tr>'
						alreadyOutputedCommu.put(commu.target.name, true)
					}
				}
				body = body +
					'<tr><td>Technology:</td><td></td><td></td><td style="text-align:right;padding-left:10px;">' +
					technology + '</td></tr>'
				body = body +
					'<tr><td>Avg. Duration:</td><td></td><td></td><td style="text-align:right;padding-left:10px;">' +
					averageDuration + ' ms</td></tr>'
			} else if (!sourceNameTheSame && targetNameTheSame) {
				title = "..." + arrow + splitName(previousTargetName)

				var alreadyOutputedCommu = new HashMap<String, Boolean>

				for (commu : accum.communications) {
					if (alreadyOutputedCommu.get(commu.source.name) == null) {
						var requests = 0
						for (reqCommu : accum.communications) {
							if (reqCommu.source.name == commu.source.name) {
								requests = requests + reqCommu.requests
							}
						}

						body = body + '<tr><td>' + commu.source.name + '</td><td>' + arrow + '</td><td>' +
							'...:</td><td style="text-align:right;padding-left:10px;">' + requests + '</td></tr>'
						alreadyOutputedCommu.put(commu.source.name, true)
					}
				}
				body = body +
					'<tr><td>Technology:</td><td></td><td></td><td style="text-align:right;padding-left:10px;">' +
					technology + '</td></tr>'
				body = body +
					'<tr><td>Avg. Duration:</td><td></td><td></td><td style="text-align:right;padding-left:10px;">' +
					averageDuration + ' ms</td></tr>'
			} else if (sourceNameTheSame && targetNameTheSame) {
				title = splitName(previousSourceName) + "<br>" + arrow + "<br>" + splitName(previousTargetName)
				var requests = 0
				for (commu : accum.communications) {
					requests = requests + commu.requests
				}
				body = '<tr><td>Requests: </td><td style="text-align:right;padding-left:10px;">' + requests +
					'</td></tr><tr><td>Technology: </td><td style="text-align:right;padding-left:10px;">' + technology +
					'</td></tr><tr><td>Avg. Duration: </td><td style="text-align:right;padding-left:10px;">' +
					averageDuration + ' ms</td></tr>'
			}
			PopoverService::showPopover(title, it.originalClickX, it.originalClickY,
				'<table style="width:100%">' + body + '</table>')
		]
	}

	def static private String splitName(String name) {
		val nameSplit = ClassnameSplitter.splitClassname(name, 14, 2)
		if (nameSplit.size == 2) {
			SafeHtmlUtils::htmlEscape(nameSplit.get(0)) + "<br>" + SafeHtmlUtils::htmlEscape(nameSplit.get(1))
		} else {
			SafeHtmlUtils::htmlEscape(name)
		}
	}

}
