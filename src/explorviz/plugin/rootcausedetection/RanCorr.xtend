package explorviz.plugin.rootcausedetection

import explorviz.plugin.interfaces.IRootCauseDetector
import explorviz.server.main.PluginManagerServerSide
import explorviz.shared.model.Landscape
import explorviz.plugin.attributes.IPluginKeys
import explorviz.plugin.attributes.TreeMapLongDoubleIValue

class RanCorr implements IRootCauseDetector {

	new() {
		PluginManagerServerSide::registerAsRootCauseDetector(this)
	}

	override doRootCauseDetection(Landscape landscape) {
		for (system : landscape.systems) {
			for (nodeGroup : system.nodeGroups) {
				for (node : nodeGroup.nodes) {
					for (application : node.applications) {

						if (application.isGenericDataPresent(IPluginKeys::TIMESTAMP_TO_ANOMALY_SCORE)) {
							var anomalyScores = application.getGenericData(IPluginKeys::TIMESTAMP_TO_ANOMALY_SCORE) as TreeMapLongDoubleIValue

							// TODO do some magic with anomalyScores to receive root cause rating
							application.putGenericStringData(IPluginKeys::ROOTCAUSE_RGB_INDICATOR, "255,0,0")
						}
					}
				}
			}
		}
	}
}
