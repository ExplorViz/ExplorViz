package explorviz.visualization.clustering;

import java.util.ArrayList;
import java.util.List;

import explorviz.shared.model.*;
import explorviz.visualization.renderer.ColorDefinitions;

/**
 *
 * @author Mirco Barzel, Florian Fittkau
 *
 */
public abstract class GenericClusterLink {

	public Component doGenericClustering(final List<ClusterData> clusterdata,
			final Application application) {

		final Component[] components = initComponents(clusterdata, application);

		final double[][] distanceMatrix = BuildMatrix.buildMatrix(clusterdata);

		int cluster1 = 0;
		int cluster2 = 0;

		for (int n = 0; n < (clusterdata.size() - 1); n++) {
			double minValue = Double.MAX_VALUE;

			// find nearest clusters to form a new cluster:
			for (int i = 0; i < clusterdata.size(); i++) {
				for (int j = 0; j < clusterdata.size(); j++) {

					if (distanceMatrix[i][j] < minValue) {
						minValue = distanceMatrix[i][j];
						cluster1 = i;
						cluster2 = j;
					}
				}
			}

			calculateNewMatrix(clusterdata, distanceMatrix, cluster1, cluster2);

			mergeCluster(clusterdata, application, distanceMatrix, cluster1, cluster2, components, n);
		}

		setColors(components[cluster1], 0);

		return components[cluster1];
	}

	private Component[] initComponents(final List<ClusterData> clusterdata,
			final Application application) {
		final Component[] c = new Component[clusterdata.size()];

		// put every class in cluster(component) first
		for (int i = 0; i < clusterdata.size(); i++) {
			final ClusterData currentData = clusterdata.get(i);
			final List<Clazz> clazzes = new ArrayList<Clazz>();
			clazzes.add(currentData.getClazz());
			c[i] = new Component();
			c[i].setName(currentData.getName());
			c[i].setParentComponent(currentData.getClazz().getParent());
			c[i].setBelongingApplication(application);
			c[i].setFullQualifiedName(currentData.getClazz().getParent().getFullQualifiedName()
					+ "." + c[i].getName());
			currentData.getClazz().setParent(c[i]);
			c[i].setSynthetic(true);
			c[i].setClazzes(clazzes);
		}
		return c;
	}

	private void calculateNewMatrix(final List<ClusterData> clusterdata,
			final double[][] distanceMatrix, final int cluster1, final int cluster2) {
		// row and column of one merged cluster serve as new place for
		// values of new cluster
		for (int j = 0; j < clusterdata.size(); j++) {
			if (cluster1 == j) {
				distanceMatrix[cluster1][j] = Double.POSITIVE_INFINITY;
			} else {
				applyMetric(distanceMatrix, cluster1, cluster2, j);
			}
		}
	}

	private void mergeCluster(final List<ClusterData> clusterdata, final Application application,
			final double[][] distanceMatrix, final int cluster1, final int cluster2,
			final Component[] c, final int n) {
		// set row and column values of the other merged cluster to Positive
		// Infinity to simulate deletion of said cluster from matrix
		for (int j = 0; j < clusterdata.size(); j++) {
			distanceMatrix[cluster2][j] = Double.POSITIVE_INFINITY;
			distanceMatrix[j][cluster2] = Double.POSITIVE_INFINITY;
		}

		// create new component out of 2
		final Component mergedCluster = new Component();
		mergedCluster.setParentComponent(c[cluster1].getParentComponent());
		mergedCluster.setBelongingApplication(application);
		mergedCluster.setName("clusterstep" + (n + 1));
		mergedCluster.setFullQualifiedName(c[cluster1].getParentComponent().getFullQualifiedName()
				+ "." + mergedCluster.getName());

		c[cluster1].setParentComponent(mergedCluster);
		c[cluster1].setFullQualifiedName(mergedCluster.getFullQualifiedName() + "."
				+ c[cluster1].getName());
		c[cluster2].setParentComponent(mergedCluster);
		c[cluster2].setFullQualifiedName(mergedCluster.getFullQualifiedName() + "."
				+ c[cluster2].getName());

		final List<Component> components = new ArrayList<Component>();
		components.add(c[cluster1]);
		components.add(c[cluster2]);
		mergedCluster.setChildren(components);

		mergedCluster.setOpened(false);

		c[cluster1] = mergedCluster;
	}

	abstract void applyMetric(final double[][] distanceMatrix, final int cluster1,
			final int cluster2, final int j);

	private void setColors(final Component component, final int i) {
		for (final Component child : component.getChildren()) {
			setColors(child, i + 1);
		}

		if ((i % 2) == 1) {
			component.setColor(ColorDefinitions.componentSyntheticColor);
		} else {
			component.setColor(ColorDefinitions.componentSyntheticSecondColor);
		}
	}
}
