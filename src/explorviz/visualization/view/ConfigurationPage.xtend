package explorviz.visualization.view

import com.google.gwt.core.client.GWT
import com.google.gwt.user.client.rpc.AsyncCallback
import com.google.gwt.user.client.rpc.ServiceDefTarget
import explorviz.visualization.engine.Logging
import explorviz.visualization.engine.navigation.Navigation
import explorviz.visualization.experiment.services.TutorialService
import explorviz.visualization.experiment.services.TutorialServiceAsync
import explorviz.visualization.main.Configuration
import explorviz.visualization.main.PageControl
import java.util.ArrayList
import java.util.List

import static explorviz.visualization.view.ConfigurationPage.*

class ConfigurationPage implements IPage {
	
	static protected ArrayList<String> languages;
	
	override render(PageControl pageControl) {
	    Navigation::deregisterWebGLKeys()
	    
		pageControl.setView('''<table>
			<th>Name</th><th>Value</th>
			<tr><td>Show FPS</td><td>«createBooleanCombobox(Configuration::showFPS)»</td></tr>
			<tr><td>Tutorial Language </td><td>«createLanguageCombobox()»</td></tr>
		 </table>'''.toString())
	}
	
	def createLanguageCombobox() {
		val TutorialServiceAsync tutorialService = GWT::create(typeof(TutorialService))
		val endpoint = tutorialService as ServiceDefTarget
		endpoint.serviceEntryPoint = GWT::getModuleBaseURL() + "tutorialservice"
		tutorialService.getLanugages(new LanguagesCallback())
		Logging.log("Trying to create combobox")

		if(languages!=null){
			createCombobox(languages,"width: 100px;", 0)
		}else{
			var english = new ArrayList<String>()
			english.add("english")
			createCombobox(english, "width:100px;",0)
		}

	}

	def private createBooleanCombobox(boolean selectedValue) {
		val possibilities = new ArrayList<String>
		possibilities.add("true")
		possibilities.add("false")
		createCombobox(possibilities, "width: 100px;", if (selectedValue) 0 else 1 )
	}

	def protected createCombobox(List<String> possibilities, String style, int selectedIndex) {
		'''<select style="«style»" onchange="alert(this.value)">
		«FOR i : 0 .. possibilities.size-1»
			<option « if (i == selectedIndex) "selected" » value="«possibilities.get(i)»">«possibilities.get(i).toFirstUpper»</option>
		«ENDFOR»
		</select>'''
	}
		
}

class LanguagesCallback implements AsyncCallback<String[]> {
			
	override onFailure(Throwable caught) {
	}
	
	override onSuccess(String[] result) {
		ConfigurationPage.languages = new ArrayList<String>()
		var i = 0
		while(i < result.length){
			var r = result.get(i)
			ConfigurationPage.languages.add(r)
			i = i+1
		}
		
	}
}