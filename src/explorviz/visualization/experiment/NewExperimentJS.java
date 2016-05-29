package explorviz.visualization.experiment;

public class NewExperimentJS {

	public static native void init() /*-{
		var toggle = [ slideOut, slideIn ], c = 0;

		var height = @explorviz.visualization.engine.main.WebGLStart::viewportHeight;
		$doc.getElementById("expSliderForm").style.height = height + 'px';

		$wnd.jQuery("#expSliderLabel").click(function(e) {
			e.preventDefault();
			toggle[c++ % 2]();
		});

		function slideOut() {
			$wnd.jQuery('#expSlider').animate({
				right : "+=250px"
			});
			$wnd.jQuery('#expSliderForm').animate({
				right : "+=250px"
			});
		}
		;

		function slideIn() {
			$wnd.jQuery('#expSlider').animate({
				right : "-=250px"
			})
			$wnd.jQuery('#expSliderForm').animate({
				right : "-=250px"
			})
		}
		;

		$wnd.jQuery("#expSaveBtn").click(function() {
			console.log($wnd.jQuery("#expSliderForm").html());
			$wnd.jQuery("#expSliderForm").html("yolo")
			//.append(
			//		@explorviz.visualization.experiment.NewExperiment::getNextQuestion()
			//				())
			;
			console.log($wnd.jQuery("#expSliderForm").html);
			console.log("Save Button Clicked");
		});

	}-*/;
}
