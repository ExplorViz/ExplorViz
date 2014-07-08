package explorviz.visualization.engine.primitives

import java.util.ArrayList
import java.util.List
import explorviz.visualization.engine.math.Vector3f
import explorviz.visualization.engine.math.Vector4f

class Label extends PrimitiveObject {
	protected val List<Quad> letters = new ArrayList<Quad>()

	protected new(String text, Vector3f LEFT_BOTTOM, Vector3f RIGHT_BOTTOM, Vector3f RIGHT_TOP, Vector3f LEFT_TOP) {
		val quadSize = RIGHT_TOP.x - RIGHT_BOTTOM.x
		
		val requiredLength = quadSize * text.length
		val Z_START = LEFT_BOTTOM.z + Math.abs(RIGHT_TOP.z - LEFT_BOTTOM.z) / 2f - (requiredLength / 2f)
		
		for (var int i = 0; i < text.length; i++) {
			letters.add(createLetter(text.charAt(i), 
				new Vector3f(LEFT_BOTTOM.x, LEFT_BOTTOM.y, Z_START + quadSize * i),
				new Vector3f(RIGHT_BOTTOM.x, RIGHT_BOTTOM.y, Z_START + quadSize * (i + 1)),
				new Vector3f(RIGHT_TOP.x + quadSize, RIGHT_TOP.y, Z_START + quadSize * (i + 1)),
				new Vector3f(LEFT_TOP.x + quadSize, LEFT_TOP.y, Z_START + quadSize * i)
			))
		}
	}

	private def createLetter(char letter, Vector3f LEFT_BOTTOM, Vector3f RIGHT_BOTTOM, Vector3f RIGHT_TOP, Vector3f LEFT_TOP) {
		var fontSize = 32
		var lettersPerSide = 16
		var yOffset = -0.055f
		var textureSize = (fontSize * lettersPerSide) as float

		val i = letter as int
		val textureStartX = ((i % 16) * fontSize) / textureSize
		val textureStartY = (yOffset * fontSize + ((i / 16)) * fontSize) / textureSize
		val textureDim = fontSize / textureSize

		new Quad(LEFT_BOTTOM, RIGHT_BOTTOM, RIGHT_TOP, LEFT_TOP, textureStartX, textureStartY,
			textureDim)
	}

	override getVertices() {

		// not used
		letters.get(0).vertices
	}

	override draw() {
		letters.forEach [
			it.draw()
		]
	}

	override isHighlighted() {
		false
	}

	override highlight(Vector4f color) {
		// dont
	}

	override unhighlight() {
		// dont
	}

	override moveByVector(Vector3f vector) {
		// dont
	}

}
