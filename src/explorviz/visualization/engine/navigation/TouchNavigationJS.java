package explorviz.visualization.engine.navigation;

public class TouchNavigationJS {
	public static native void register() /*-{
		$wnd
				.jQuery("#webglcanvas")
				.on(
						"contextmenu",
						function(ev) {
							if (ev.originalEvent.offsetY < ev.target.clientWidth
									- @explorviz.visualization.engine.main.WebGLStart::timeshiftHeight) {
								ev.preventDefault();
								@explorviz.visualization.engine.picking.ObjectPicker::handleRightClick(II)(ev.originalEvent.offsetX, ev.originalEvent.offsetY)
							}
						});
		
		var hammertime = $wnd.jQuery().newHammerManager($doc.getElementById("webglcanvas"),{});
		$wnd.jQuery.fn.hammerTimeInstance = hammertime

		
		var tapHammer = $wnd.jQuery().newHammerTap({event: 'tap'});
		var doubleTapHammer = $wnd.jQuery().newHammerTap({event: 'doubleTap', taps: 2 });
		var panHammer = $wnd.jQuery().newHammerPan({});
		var pressHammer = $wnd.jQuery().newHammerPress({});
		var pinchHammer = $wnd.jQuery().newHammerPinch({enable: true});
		
		hammertime.add([doubleTapHammer, tapHammer, panHammer, pressHammer, pinchHammer]);
		doubleTapHammer.recognizeWith(tapHammer);
		tapHammer.requireFailure(doubleTapHammer);
		
		hammertime
				.on(
						"tap",
						function(ev) {
							if (ev.pointerType == "mouse") {
								@explorviz.visualization.engine.navigation.Navigation::mouseSingleClickHandler(II)(ev.srcEvent.offsetX, ev.srcEvent.offsetY);
							} else if (ev.pointerType == "touch") {
								@explorviz.visualization.engine.navigation.Navigation::mouseSingleClickHandler(II)(ev.pointers[0].clientX, ev.pointers[0].clientY - @explorviz.visualization.engine.main.WebGLStart::navigationHeight);
							}
						});

		hammertime
				.on(
						"doubleTap",
						function(ev) {
							if (ev.pointerType == "mouse") {
								@explorviz.visualization.engine.navigation.Navigation::mouseDoubleClickHandler(II)(ev.srcEvent.offsetX, ev.srcEvent.offsetY);
							} else if (ev.pointerType == "touch") {
								@explorviz.visualization.engine.navigation.Navigation::mouseDoubleClickHandler(II)(ev.pointers[0].clientX, ev.pointers[0].clientY - @explorviz.visualization.engine.main.WebGLStart::navigationHeight);
							}
						});

		hammertime
				.on(
						"pinchin",
						function(ev) {
							@explorviz.visualization.engine.navigation.Navigation::mouseWheelHandler(I)(1);
						});

		hammertime
				.on(
						"pinchout",
						function(ev) {
							@explorviz.visualization.engine.navigation.Navigation::mouseWheelHandler(I)(-1);
						});
		hammertime
				.on(
						"press",
						function(ev) {
							if (ev.pointerType == "mouse") {
								if (ev.srcEvent.offsetY < ev.target.parentElement.parentElement.clientWidth
										- @explorviz.visualization.engine.main.WebGLStart::timeshiftHeight) {
									@explorviz.visualization.engine.picking.ObjectPicker::handleMouseMove(II)(ev.srcEvent.offsetX, ev.srcEvent.offsetY);
								}
							} else if (ev.pointerType == "touch") {
								if (ev.pointers[0].clientY - @explorviz.visualization.engine.main.WebGLStart::navigationHeight < ev.target.parentElement.parentElement.clientWidth
										- @explorviz.visualization.engine.main.WebGLStart::timeshiftHeight) {
									@explorviz.visualization.engine.picking.ObjectPicker::handleMouseMove(II)(ev.pointers[0].clientX, ev.pointers[0].clientY - @explorviz.visualization.engine.main.WebGLStart::navigationHeight);
								}
							}
						});

		hammertime
				.on(
						"panstart",
						function(ev) {
							if (ev.pointerType == "mouse") {
								@explorviz.visualization.engine.navigation.Navigation::mouseDownHandler(II)(ev.srcEvent.offsetX, ev.srcEvent.offsetY);
							} else if (ev.pointerType == "touch") {
								@explorviz.visualization.engine.navigation.Navigation::mouseDownHandler(II)(ev.pointers[0].clientX, ev.pointers[0].clientY - @explorviz.visualization.engine.main.WebGLStart::navigationHeight);
							}
						});
		hammertime
				.on(
						"panmove",
						function(ev) {
							if (ev.pointerType == "mouse") {
								@explorviz.visualization.engine.navigation.Navigation::panningHandler(IIII)(ev.srcEvent.offsetX, ev.srcEvent.offsetY, ev.target.parentElement.parentElement.clientWidth, ev.target.parentElement.parentElement.clientHeight);
							} else if (ev.pointerType == "touch") {
								@explorviz.visualization.engine.navigation.Navigation::panningHandler(IIII)(ev.pointers[0].clientX, ev.pointers[0].clientY - @explorviz.visualization.engine.main.WebGLStart::navigationHeight, ev.target.parentElement.parentElement.clientWidth, ev.target.parentElement.parentElement.clientHeight);
							}
						});
		hammertime
				.on(
						"panend pancancel",
						function(ev) {
							if (ev.pointerType == "mouse") {
								@explorviz.visualization.engine.navigation.Navigation::mouseUpHandler(II)(ev.srcEvent.offsetX, ev.srcEvent.offsetY);
							} else if (ev.pointerType == "touch") {
								@explorviz.visualization.engine.navigation.Navigation::mouseUpHandler(II)(ev.pointers[0].clientX, ev.pointers[0].clientY - @explorviz.visualization.engine.main.WebGLStart::navigationHeight);
							}
						});
	}-*/;

	public static native void deregister() /*-{
		$wnd.jQuery().hammerTimeInstance.destroy()
	}-*/;
}