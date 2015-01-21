package explorviz.plugin_server.capacitymanagement.scaling_strategies;

import java.util.Map;

import explorviz.shared.model.Node;

public interface IScalingStrategy {
	/**
	 * Gets nodes and their utilizations values and analyzes them
	 *
	 * @param averageCPUUtilizations
	 *            Map of nodes with their CPU utilization values
	 * @return
	 */
	public Map<Node, Boolean> analyze(Map<Node, Double> averageCPUUtilizations);

}