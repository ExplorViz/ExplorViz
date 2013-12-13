package explorviz.visualization.model.helper

import explorviz.visualization.engine.picking.EventObserver
import de.cau.cs.kieler.core.kgraph.KNode
import de.cau.cs.kieler.core.kgraph.KPort
import explorviz.visualization.engine.math.Vector4f
import elemental.html.WebGLTexture
import explorviz.visualization.engine.math.Vector3f
import explorviz.visualization.engine.primitives.Quad
import explorviz.visualization.engine.primitives.Rectangle
import java.util.HashMap
import explorviz.visualization.model.ApplicationClientSide
import java.util.Map

class DrawNodeEntity extends EventObserver {
	@Property KNode kielerNodeReference
	
	@Property Map<ApplicationClientSide, KPort> sourcePorts = new HashMap<ApplicationClientSide, KPort>()
	@Property Map<ApplicationClientSide, KPort> targetPorts = new HashMap<ApplicationClientSide, KPort>()
	
	@Property float width
	@Property float height
	
	@Property float positionX
	@Property float positionY
	
	override destroy() {
	    super.destroy()
	}
	
	def createQuad(float z, Vector3f centerPoint, Vector4f color) {
		createQuad(z,centerPoint,null,color)
	}
	
	def createQuad(float z, Vector3f centerPoint, WebGLTexture texture) {
		createQuad(z,centerPoint,texture,null)
	}
	
	def private createQuad(float z, Vector3f centerPoint, WebGLTexture texture, Vector4f color) {
        val extensionX = width / 2f
        val extensionY = height / 2f
        
        val centerX = positionX + extensionX - centerPoint.x
        val centerY = positionY - extensionY - centerPoint.y

        new Quad(new Vector3f(centerX, centerY, z),
                 new Vector3f(extensionX, extensionY, 0.0f), 
                 texture, color)
    }
    
    def createLineAroundQuad(Quad quad, float z, boolean stippeled, Vector4f color) {
        new Rectangle(quad.cornerPoints.get(0),quad.cornerPoints.get(1),quad.cornerPoints.get(2),quad.cornerPoints.get(3), color, stippeled, z)
    }
}