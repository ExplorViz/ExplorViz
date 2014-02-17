package explorviz.visualization.model

import java.util.ArrayList
import java.util.List
import explorviz.visualization.engine.math.Vector4f
import explorviz.visualization.engine.primitives.Quad
import explorviz.visualization.engine.textures.TextureManager
import explorviz.visualization.engine.math.Vector3f
import explorviz.visualization.model.helper.DrawNodeEntity
import explorviz.visualization.engine.primitives.Rectangle
import explorviz.visualization.renderer.ColorDefinitions

class NodeGroupClientSide extends DrawNodeEntity {
	@Property val List<NodeClientSide> nodes = new ArrayList<NodeClientSide>
	@Property LandscapeClientSide parent
	
	static val Vector4f plusColor = ColorDefinitions::nodeGroupPlusColor
	static val Vector4f backgroundColor = ColorDefinitions::nodeGroupBackgroundColor
	
	var Quad quad
	var boolean opened
	
	def boolean isOpened() {
	    opened
	}
	
	def void setOpened(boolean openedParam) {
	    if (openedParam) {
	       setAllChildrenVisibility(true)
	    } else {
	       setAllChildrenVisibility(false)
	       if (nodes.size() > 0) {
	          val firstNode = nodes.get(0)
    	      firstNode.visible = true
	       }
	    }
	    
	    this.opened = openedParam
	}

    private def setAllChildrenVisibility(boolean visiblity) {
        nodes.forEach [
    	   it.visible = visiblity
    	]
    }
    
    def Quad createNodeGroupQuad(float z, Vector3f centerPoint) {
        quad = createQuad(z, centerPoint, backgroundColor)
		quad
    }
    
    def Quad createNodeGroupOpenSymbol() {
        val extensionX = 0.1f
        val extensionY = 0.1f
        
        val TOP_RIGHT = quad.cornerPoints.get(2)
        
        var float centerX = TOP_RIGHT.x - extensionX * 1.5f
        var float centerY = TOP_RIGHT.y - extensionY * 1.5f
        
        var symbol = "\u2013"
        if (!opened) symbol = "+"
        
        val texture = TextureManager::createTextureFromText(symbol, 128, 128, Math.round(plusColor.x * 255), Math.round(plusColor.y * 255), Math.round(plusColor.z * 255), 'bold 256px Arial', backgroundColor)
        
        new Quad(new Vector3f(centerX, centerY, TOP_RIGHT.z + 0.01f),
                 new Vector3f(extensionX, extensionY, 0.0f), 
                 texture, null, true
        )
    }
	
	override void destroy() {
		nodes.forEach [it.destroy()]
	    super.destroy()
	}
	
	def Rectangle createNodeGroupQuadRectangle(float z, Vector3f vector3f) {
		//new Rectangle(quad.cornerPoints.get(0),quad.cornerPoints.get(1),quad.cornerPoints.get(2),quad.cornerPoints.get(3), new Vector4f(0.85f, 0.85f, 0.85f, 1f), true, z)
	}
}