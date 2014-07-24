package explorviz.visualization.highlighting

import explorviz.shared.model.Application
import explorviz.shared.model.Clazz
import explorviz.shared.model.Component
import explorviz.shared.model.helper.Draw3DNodeEntity
import explorviz.shared.model.helper.EdgeState
import explorviz.visualization.engine.main.SceneDrawer

class NodeHighlighter {
	static var Draw3DNodeEntity highlightedNode = null
	static var Application app = null

	def static void highlight3DNode(Draw3DNodeEntity node) {
		val highlightedBefore = node.highlighted
		app = if (node instanceof Component)
			node.belongingApplication
		else if (node instanceof Clazz)
			node.parent.belongingApplication

		app.unhighlight()

		if (!highlightedBefore) {
			node.highlight()
			highlightedNode = node
			TraceHighlighter::reset(false)
			SceneDrawer::createObjectsFromApplication(app, true)
		} else {
			unhighlight3DNodes()
		}
	}

	def static void unhighlight3DNodes() {
		highlightedNode = null
		if (app != null) {
			app.unhighlight()

			SceneDrawer::createObjectsFromApplication(app, true)
		}
	}

	public def static void reset() {
		if (app != null)
			app.unhighlight()
		highlightedNode = null
	}

	public def static void applyHighlighting(Application applicationParam) {
		if (highlightedNode != null) {
			applicationParam.communicationsAccumulated.forEach [
				var outgoing = false
				if (it.source != null && it.source.fullQualifiedName == highlightedNode.fullQualifiedName) {
					outgoing = true
				}
				var incoming = false
				if (it.target != null && it.target.fullQualifiedName == highlightedNode.fullQualifiedName) {
					incoming = true
				}
				if (incoming && outgoing) {
					it.state = EdgeState.SHOW_DIRECTION_IN_AND_OUT
				} else if (incoming) {
					it.state = EdgeState.SHOW_DIRECTION_IN
				} else if (outgoing) {
					it.state = EdgeState.SHOW_DIRECTION_OUT
				} else {
					it.state = EdgeState.TRANSPARENT
				}
			]
		}
	}
}