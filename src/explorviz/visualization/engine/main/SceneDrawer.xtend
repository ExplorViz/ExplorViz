package explorviz.visualization.engine.main

import elemental.html.WebGLRenderingContext
import explorviz.shared.model.Application
import explorviz.shared.model.Component
import explorviz.shared.model.Landscape
import explorviz.shared.model.NodeGroup
import explorviz.shared.model.System
import explorviz.visualization.engine.animation.ObjectMoveAnimater
import explorviz.visualization.engine.buffer.BufferManager
import explorviz.visualization.engine.math.Vector3f
import explorviz.visualization.engine.navigation.Camera
import explorviz.visualization.engine.navigation.Navigation
import explorviz.visualization.engine.primitives.BoxContainer
import explorviz.visualization.engine.primitives.LabelContainer
import explorviz.visualization.engine.primitives.PipeContainer
import explorviz.visualization.engine.primitives.PrimitiveObject
import explorviz.visualization.engine.shaders.ShaderInitializer
import explorviz.visualization.engine.shaders.ShaderObject
import explorviz.visualization.interaction.ApplicationInteraction
import explorviz.visualization.interaction.LandscapeInteraction
import explorviz.visualization.layout.LayoutService
import explorviz.visualization.renderer.ApplicationRenderer
import explorviz.visualization.renderer.LandscapeRenderer
import java.util.ArrayList
import java.util.List
import explorviz.visualization.clustering.Clustering

class SceneDrawer {
	static WebGLRenderingContext glContext
	static ShaderObject shaderObject

	public static Landscape lastLandscape
	public static Application lastViewedApplication

	static val clearMask = WebGLRenderingContext::COLOR_BUFFER_BIT.bitwiseOr(WebGLRenderingContext::DEPTH_BUFFER_BIT)
	static val polygons = new ArrayList<PrimitiveObject>(256)

	private new() {
	}

	def static init(WebGLRenderingContext glContextParam) {
		glContext = glContextParam
		shaderObject = ShaderInitializer::initShaders(glContext)

		//ErrorChecker::init(glContext)
		BufferManager::init(glContext, shaderObject)

		polygons.clear
	}

	def static void viewScene(Landscape landscape, boolean doAnimation) {
		if (!landscape.systems.empty)
			createObjectsFromApplication(landscape.systems.get(0).nodeGroups.get(0).nodes.get(0).applications.get(0),
				doAnimation)

	//		if (lastViewedApplication == null) {
	//			if (lastLandscape != null) {
	//				setOpenedAndClosedStatesLandscape(lastLandscape, landscape)
	//			}
	//			createObjectsFromLandscape(landscape, doAnimation)
	//		} else {
	//			for (system : landscape.systems) {
	//				for (nodegroup : system.nodeGroups) {
	//					for (node : nodegroup.nodes) {
	//						for (application : node.applications) {
	//							if (lastViewedApplication.id == application.id) {
	//								setStatesFromOldApplication(lastViewedApplication, application)
	//								createObjectsFromApplication(application, doAnimation)
	//								return;
	//							}
	//						}
	//					}
	//				}
	//			}
	//		}
	}

	private static def void setOpenedAndClosedStatesLandscape(Landscape oldLandscape, Landscape landscape) {
		for (system : landscape.systems) {
			setOpenedAndClosedStatesLandscapeHelper(oldLandscape, system)
		}
	}

	private static def void setOpenedAndClosedStatesLandscapeHelper(Landscape oldLandscape, System system) {
		for (oldSystem : oldLandscape.systems) {
			if (system.name == oldSystem.name) {
				for (nodegroup : system.nodeGroups) {
					setOpenedAndClosedStatesLandscapeHelperNodeGroup(oldSystem, nodegroup)
				}
				if (oldSystem.opened != system.opened) {
					system.opened = oldSystem.opened
				}
				return
			}
		}
	}

	private static def void setOpenedAndClosedStatesLandscapeHelperNodeGroup(System oldSystem, NodeGroup nodegroup) {
		for (oldNodegroup : oldSystem.nodeGroups) {
			if (nodegroup.name == oldNodegroup.name) {
				if (oldNodegroup.opened != nodegroup.opened) {
					nodegroup.opened = oldNodegroup.opened
				}
				return
			}
		}
	}

	private static def void setStatesFromOldApplication(Application oldApplication, Application application) {
		setNodeStatesFromOldApplicationHelper(oldApplication.components, application.components)
	}

	private static def void setNodeStatesFromOldApplicationHelper(List<Component> oldCompos, List<Component> newCompos) {
		for (oldCompo : oldCompos) {
			for (newCompo : newCompos) {
				if (newCompo.name == oldCompo.name) {
					newCompo.opened = oldCompo.opened
					newCompo.highlighted = oldCompo.highlighted

					for (oldClazz : oldCompo.clazzes) {
						for (newClazz : newCompo.clazzes) {
							if (oldClazz.name == newClazz.name) {
								newClazz.highlighted = oldClazz.highlighted
							}
						}
					}

					setNodeStatesFromOldApplicationHelper(oldCompo.children, newCompo.children)
				}

			}
		}
	}

	def static void createObjectsFromLandscape(Landscape landscape, boolean doAnimation) {
		polygons.clear
		lastLandscape = landscape
		lastViewedApplication = null
		if (!doAnimation) {
			Camera::resetTranslate
			Camera::resetRotate()
		}

		glContext.uniform1f(shaderObject.useLightingUniform, 0)

		//        val startTime = new Date()
		LayoutService::layoutLandscape(landscape)

		//        Logging::log("Time for whole layouting: " + (new Date().time - startTime.time).toString + " msec")
		LandscapeInteraction::clearInteraction(landscape)

		BufferManager::begin
		LandscapeRenderer::drawLandscape(landscape, polygons, !doAnimation)
		BufferManager::end

		LandscapeInteraction::createInteraction(landscape)

		if (doAnimation) {
			ObjectMoveAnimater::startAnimation()
		}

	//        octree = new Octree(polygons)
	}

	def static void createObjectsFromApplication(Application application, boolean doAnimation) {
		polygons.clear
		lastViewedApplication = application
		if (!doAnimation) {
			Camera::resetTranslate
			Camera::resetRotate()

			Camera::rotateX(40) // 33...
			Camera::rotateY(50) // 45
		}

		glContext.uniform1f(shaderObject.useLightingUniform, 1)

		application.openAllComponents // TODO added
		hackTheClosingOfCertainPackages(application.components.get(0))

		Clustering::doSyntheticClustering(application)

		//        var startTime = new Date()
		LayoutService::layoutApplication(application)

		//        Logging::log("Time for whole layouting: " + (new Date().time - startTime.time).toString + " msec")
		LandscapeInteraction::clearInteraction(application.parent.parent.parent.parent)
		ApplicationInteraction::clearInteraction(application)

		BufferManager::begin
		ApplicationRenderer::drawApplication(application, polygons, !doAnimation)
		BufferManager::end

		ApplicationInteraction::createInteraction(application)

		if (doAnimation) {
			ObjectMoveAnimater::startAnimation()
		}
	}

	def static void hackTheClosingOfCertainPackages(Component component) {
		for (child : component.children) {
			hackTheClosingOfCertainPackages(child)
		}
		if (component.fullQualifiedName == "net.sourceforge.pmd.lang.java.xpath" ||
			component.fullQualifiedName == "net.sourceforge.pmd.lang.java.typeresolution" ||
			component.fullQualifiedName == "net.sourceforge.pmd.lang.java.javadoc" ||
			component.fullQualifiedName == "net.sourceforge.pmd.lang.rule.xpath" ||
			component.fullQualifiedName == "net.sourceforge.pmd.lang.xpath" ||
			component.fullQualifiedName == "net.sourceforge.pmd.util.datasource" ||
			component.fullQualifiedName == "net.sourceforge.pmd.renderers" ||
			component.fullQualifiedName == "org.neo4j.kernel.configuration" ||
			component.fullQualifiedName == "org.neo4j.kernel.guard" ||
			component.fullQualifiedName == "org.neo4j.kernel.logging" ||
			component.fullQualifiedName == "org.neo4j.kernel.lifecycle" ||
			component.fullQualifiedName == "org.neo4j.unsafe") {
			component.opened = false
		}
	}

	def static void drawScene() {
		glContext.clear(clearMask)

		GLManipulation::loadIdentity

		GLManipulation::translate(Navigation::getCameraPoint())

		val cameraRotate = Navigation::getCameraRotate()
		GLManipulation::rotateX(cameraRotate.x)
		GLManipulation::rotateY(cameraRotate.y)

		GLManipulation::activateModelViewMatrix

		BoxContainer::drawLowLevelBoxes
		LabelContainer::draw
		PipeContainer::drawTransparentPipes
		PipeContainer::drawPipes
		BoxContainer::drawHighLevelBoxes

		for (polygon : polygons) {
			polygon.draw()
		}

		LabelContainer::drawHighLevel
	}

	def static void redraw() {
		viewScene(lastLandscape, true)
	}
}
