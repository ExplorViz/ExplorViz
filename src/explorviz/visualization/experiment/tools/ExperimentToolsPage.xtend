package explorviz.visualization.experiment.tools

import com.google.gwt.user.client.DOM
import com.google.gwt.user.client.Event
import com.google.gwt.user.client.EventListener
import com.google.gwt.user.client.Window
import explorviz.visualization.experiment.Experiment
import explorviz.visualization.experiment.Questionnaire
import explorviz.visualization.experiment.callbacks.VoidFuncCallback
import explorviz.visualization.experiment.services.JSONServiceAsync
import explorviz.visualization.main.ExplorViz
import explorviz.visualization.main.JSHelpers
import explorviz.visualization.main.PageControl
import explorviz.visualization.main.Util
import explorviz.visualization.view.IPage
import java.util.ArrayList
import static explorviz.visualization.experiment.Experiment.*
import static explorviz.visualization.experiment.Questionnaire.*
import static explorviz.visualization.experiment.tools.ExperimentSlider.*
import static explorviz.visualization.experiment.tools.ExperimentTools.*
import elemental.json.Json
import elemental.json.JsonObject
import explorviz.visualization.experiment.callbacks.ZipCallback
import java.util.Arrays
import explorviz.visualization.engine.Logging
import explorviz.visualization.experiment.callbacks.StringWithJSONCallback
import elemental.json.JsonArray
import explorviz.visualization.experiment.callbacks.StringFuncCallback
import explorviz.visualization.experiment.callbacks.JsonExperimentCallback

class ExperimentToolsPage implements IPage {

	var static JSONServiceAsync jsonService
	var static PageControl pc
	var static JsonObject jsonFilenameAndTitle
	var static String runningExperiment
	
	private var static String filenameExperiment
	private var static String questionnaireTitle

	override render(PageControl pageControl) {

		pc = pageControl
		pc.setView("")

		JSHelpers::hideElementById("legendDiv")

		ExperimentTools::toolsModeActive = true

		jsonService = Util::getJSONService()
		jsonService.getExperimentTitlesAndFilenames(new StringFuncCallback<String>([finishInit]))
	}

	def static void finishInit(String json) {

		jsonFilenameAndTitle = Json.parse(json)
		var keys = new ArrayList<String>(Arrays.asList(jsonFilenameAndTitle.keys))

		pc.setView(
			'''
			<div class = "container-fluid">
				<div class="row">					
					<div class="col-md-12">
						<ul>
							<li class="expHeader">
								<div class="">
									<div>
										Experiment&nbsp;name
									</div>
								</div>
							</li>
					�IF keys.size > 0�						
						�FOR i : 0 .. (keys.size - 1)�	
							�var JsonObject questionnairesObj = jsonFilenameAndTitle.get(keys.get(i))�
							�var experimentTitle = questionnairesObj.keys.get(0)�
							�var questionnaires = questionnairesObj.getArray(experimentTitle)�
							<li id="�keys.get(i)�" class="expEntry">
								<div class ="container-fluid">
									<div class="row">
										<div class="col-md-6 expListButtons">
											�experimentTitle�
										</div>
										<div class="col-md-6 expListButtons">
											<div class="dropdown col-md-3" style="position: relative; display: inline;">
												<a class="dropdown-toggle expBlueSpan" data-toggle="dropdown">
													<span class="glyphicon glyphicon-list"></span>
												</a>
												<ul class="dropdown-menu">
													<li><a id="expAddSpan�i�" >Add Questionnaire</a></li>
													<li class="divider"></li>												
													�IF questionnaires.length > 0�														
														�FOR j : 0 .. (questionnaires.length - 1)�
															<li class="dropdown-submenu">
																�var JsonObject questionnaireTitle = questionnaires.get(j)�
																<a>�questionnaireTitle�</a>
																<ul class="dropdown-menu">
																	<li><a id="expShowQuestDetailsSpan�i.toString + j.toString�">Show Details</a></li>
																	<li><a id="expEditQuestSpan�i.toString + j.toString�">Edit Questionnaire</a></li>
																	<li><a id="expEditQuestionsSpan�i.toString + j.toString�">Edit Questions</a></li>
																	<li><a id="expUserManQuestSpan�i.toString + j.toString�">User Management TODO</a></li>
																	<li><a id="expRemoveQuestSpan�i.toString + j.toString�">Remove Questionnaire</a></li>
																</ul>
															</li>
														�ENDFOR�
													�ENDIF�
													</ul>
											</div>
											<div class ="col-md-9">
												<a class="expPlaySpan" id="expPlaySpan�i�">
													<span �getSpecificCSSClass(keys.get(i))� title="Start/Pause Experiment"></span>
												</a>
												<a class="expEditSpan" id="expEditSpan�i�">
													<span class="glyphicon glyphicon-cog" title="Edit experiment"></span>
												</a>
												<a class="expRemoveSpan" id="expRemoveSpan�i�">
													<span class="glyphicon glyphicon-remove-circle" title="Delete Experiment"></span>
												</a>
												<a class="expBlueSpan" id="expDetailSpan�i�">
													<span class="glyphicon glyphicon-info-sign" title="More Details"></span>
												</a>
												<a class="expBlueSpan" id="expDownloadSpan�i�">
													<span class="glyphicon glyphicon-download" title="Download Experiment"></span>
												</a>
												<a class="expBlueSpan" id="expDuplicateSpan�i�">
													<span class="glyphicon glyphicon-retweet" title="Duplicate experiment"></span>
												</a>
											</div>
										</div>
									</div>
								</div>
							</li>
						�ENDFOR�
					�ENDIF�
					<button id="newExperimentBtn" type="button" style="display: block; margin-top:10px;" class="btn btn-default btn-sm">
						<span class="glyphicon glyphicon-plus"></span> Create New Experiment 
							</button>
						</ul>
					</div>
				</div>	
			</div>		
			'''.toString())

		prepareModal()
		setupButtonHandler()
	}

	def static private setupChart() {

		ExperimentChartJS::showExpChart()

	}

	def static private setupButtonHandler() {

		// create Experiment Button
		val buttonAdd = DOM::getElementById("newExperimentBtn")
		Event::sinkEvents(buttonAdd, Event::ONCLICK)
		Event::setEventListener(buttonAdd, new EventListener {

			override onBrowserEvent(Event event) {
				showCreateExperimentModal()
			}
		})

		// experiment button handlers
		val keys = new ArrayList<String>(Arrays.asList(jsonFilenameAndTitle.keys))

		for (var j = 0; j < keys.size; j++) {

			val filename = keys.get(j);
			val JsonObject experiment = jsonFilenameAndTitle.get(filename);
			val questionnaires = experiment.getArray(experiment.keys.get(0));

			val buttonRemove = DOM::getElementById("expRemoveSpan" + j)
			Event::sinkEvents(buttonRemove, Event::ONCLICK)
			Event::setEventListener(buttonRemove, new EventListener {
				override onBrowserEvent(Event event) {

					if (Window::confirm("Are you sure about deleting this file? It can not be restored."))
						jsonService.removeExperiment(filename, new VoidFuncCallback<Void>([loadExpToolsPage]))

				}
			})

			val buttonEdit = DOM::getElementById("expEditSpan" + j)
			Event::sinkEvents(buttonEdit, Event::ONCLICK)
			Event::setEventListener(buttonEdit, new EventListener {

				override onBrowserEvent(Event event) {
					jsonService.getExperiment(filename, new StringFuncCallback<String>([showExperimentModal]))
				}
			})

			val buttonPlay = DOM::getElementById("expPlaySpan" + j)
			Event::sinkEvents(buttonPlay, Event::ONCLICK)
			Event::setEventListener(buttonPlay, new EventListener {

				override onBrowserEvent(Event event) {
					if (runningExperiment != null && filename.equals(runningExperiment)) {
						stopExperiment()
					} else {
						startExperiment(filename)
					}

				}
			})

			val buttonDownload = DOM::getElementById("expDownloadSpan" + j)
			Event::sinkEvents(buttonDownload, Event::ONCLICK)
			Event::setEventListener(buttonDownload, new EventListener {

				override onBrowserEvent(Event event) {
					jsonService.downloadExperimentData(filename, new ZipCallback("experimentData.zip"))
				}
			})

			val buttonDuplicate = DOM::getElementById("expDuplicateSpan" + j)
			Event::sinkEvents(buttonDuplicate, Event::ONCLICK)
			Event::setEventListener(buttonDuplicate, new EventListener {

				override onBrowserEvent(Event event) {
					jsonService.duplicateExperiment(filename, new VoidFuncCallback<Void>([loadExpToolsPage]))
				}
			})

			val buttonDetailsModal = DOM::getElementById("expDetailSpan" + j)
			Event::sinkEvents(buttonDetailsModal, Event::ONCLICK)
			Event::setEventListener(buttonDetailsModal, new EventListener {

				override onBrowserEvent(Event event) {
					jsonService.getExperimentDetails(filename, new StringFuncCallback<String>([showDetailsModal]))
				}
			})

			val buttonAddQuest = DOM::getElementById("expAddSpan" + j)
			Event::sinkEvents(buttonAddQuest, Event::ONCLICK)
			Event::setEventListener(buttonAddQuest, new EventListener {

				override onBrowserEvent(Event event) {
					jsonService.getExperiment(filename, new StringFuncCallback<String>([showCreateQuestModal]))
				}
			})

			// questionnaires button handler
			for (var i = 0; i < questionnaires.length; i++) {
				val JsonObject questionnaire = questionnaires.get(i);

				val buttonEditQuest = DOM::getElementById("expEditQuestSpan" + j.toString + i.toString)
				Event::sinkEvents(buttonEditQuest, Event::ONCLICK)
				Event::setEventListener(buttonEditQuest,
					new EventListener {

						override onBrowserEvent(Event event) {
							jsonService.getExperiment(filename,
								new StringWithJSONCallback<String>([showQuestModal], questionnaire.toString))
						}
					})

				val buttonEditQuestions = DOM::getElementById("expEditQuestionsSpan" + j.toString + i.toString)
				Event::sinkEvents(buttonEditQuestions, Event::ONCLICK)
				Event::setEventListener(buttonEditQuestions,
					new EventListener {

						override onBrowserEvent(Event event) {
							
							var JsonObject data = Json.createObject
							data.put(filename, questionnaire.toString)
							
							jsonService.getQuestionnaire(data.toJson,
								new StringWithJSONCallback<String>([editQuestQuestions], filename))
						}
					})

				val buttonDetailsQuest = DOM::getElementById("expShowQuestDetailsSpan" + j.toString + i.toString)
				Event::sinkEvents(buttonDetailsQuest, Event::ONCLICK)
				Event::setEventListener(buttonDetailsQuest, new EventListener {

					override onBrowserEvent(Event event) {

						var JsonObject data = Json.createObject

						data.put(filename, questionnaire.toString)

						jsonService.getQuestionnaireDetails(data.toJson, new StringFuncCallback<String>([
							showQuestDetailsModal
						]))
					}
				})

				val buttonRemoveQuest = DOM::getElementById("expRemoveQuestSpan" + j.toString + i.toString)
				Event::sinkEvents(buttonRemoveQuest, Event::ONCLICK)
				Event::setEventListener(buttonRemoveQuest, new EventListener {

					override onBrowserEvent(Event event) {

						var JsonObject data = Json.createObject

						data.put(filename, questionnaire.toString)

						if (Window::confirm("Are you sure about deleting this questionnaire? It can not be restored."))
							jsonService.removeQuestionnaire(data.toJson, new VoidFuncCallback<Void>([loadExpToolsPage]))
					}
				})

				val buttonUserModal = DOM::getElementById("expUserManQuestSpan" + j.toString + i.toString)
				Event::sinkEvents(buttonUserModal, Event::ONCLICK)
				Event::setEventListener(buttonUserModal, new EventListener {
					
					override onBrowserEvent(Event event) {
						
							var JsonObject data = Json.createObject
							data.put(filename, questionnaire.toString)
							
							filenameExperiment = filename
							questionnaireTitle = questionnaire.toString
						
							jsonService.getExperimentAndUsers(data.toJson,
								new StringFuncCallback<String>([showUserManagement]))
						}
					})
			}
		}
	}

	def static void startExperiment(String experimentFilename) {

		runningExperiment = experimentFilename

		ExperimentTools::toolsModeActive = false

		Experiment::experiment = true
		Questionnaire::experimentFilename = experimentFilename

		loadExpToolsPage()
	}

	def static void stopExperiment() {

		runningExperiment = null

		ExperimentTools::toolsModeActive = true

		Experiment::experiment = false
		Questionnaire::experimentFilename = null

		loadExpToolsPage()
	}

	def static void editQuestQuestions(String jsonString) {
		var JsonObject data = Json.parse(jsonString)

		ExperimentSlider::filename = data.keys.get(0)
		ExperimentSlider::jsonQuestionnaire = data.getString(filename)
		ExperimentSlider::isWelcome = false
		
		ExplorViz::getPageCaller().showExperimentSlider()
	}

	def static loadExpToolsPage() {
		ExplorViz::getPageCaller().showExpTools()
	}

	def static getQuestionText(int id) {

		return Questionnaire.questions.get(id).text

	}

	def static showNewExpWindow() {

		ExperimentSlider::jsonQuestionnaire = null
		ExperimentSlider::isWelcome = true
		ExplorViz::getPageCaller().showExperimentSlider()

	}

	def static getSpecificCSSClass(String filename) {

		if (runningExperiment != null && filename.equals(runningExperiment)) {
			return '''class="glyphicon glyphicon-pause"'''
		} else {
			return '''class="glyphicon glyphicon-play"'''
		}

	}

	def static private prepareModal() {

		var modal = " 
				<div class='modal fade' id='modalExp' tabindex='-1' role='dialog' aria-labelledby='myModalLabel' aria-hidden='true'>
				  <div class='modal-dialog modal-dialog-center' role='document'>
				    <div class='modal-content'>
				      <div class='modal-header'>
				        <button type='button' class='close' data-dismiss='modal' aria-label='Close'>
				          <span aria-hidden='true'>&times;</span>
				        </button>
				        <h4 class='modal-title' id='myModalLabel'>Experiment details</h4>
				      </div>
				      <div id='exp-modal-body' class='modal-body'>
				        CONTENT HERE
				      </div>
				      <div id='exp-modal-footer' class='modal-footer'>
				        <button type='button' class='btn btn-secondary' data-dismiss='modal'>Close</button>
				      </div>
				    </div>
				  </div>
				</div>
		"

		ExperimentToolsPageJS::prepareModal(modal)
	}

	def static private showDetailsModal(String jsonDetails) {

		var JsonObject jsonObj = Json.parse(
			jsonDetails)

		var body = '''
			<table class='table table-striped'>
			  <tr>
			    <th>Title:</th>
			    <td>�jsonObj.getString("title")�</td>
			  </tr>
			  <tr>
			    <th>Prefix:</th>
			    <td>�jsonObj.getString("prefix")�</td>
			  </tr>
			  <tr>
			    <th>Number of Questions:</th>
			    <td>�jsonObj.getString("numQuestionnaires")�</td>
			  </tr>
			  <tr>
			  	<th>Used landscapes:</th>
			  	<td>�jsonObj.getString("landscapes")�</td>
			  </tr>
			  	<tr>
				  	<th>Filename:</th>
					<td>
						<input class="form-control" id="experimentFilename" name="filename" size="35" value="�jsonObj.getString("filename")�" readonly>
					</td>
				</tr>
			</table>
		'''
		ExperimentToolsPageJS::updateAndShowModal(body, false, jsonDetails, false)
	}

	def static private showCreateExperimentModal() {

		var body = '''
			<p>Welcome to the Experiment Tools Question Interface.</p>
			<p>Please select an experiment title:</p>
			<table class='table table-striped'>
			  <tr>
			    <th>Experiment Title:</th>
			    <td>
			    	 <input class="form-control" id="experimentTitle" name="title" size="35">
				</td>
				 </tr>
				 <tr>
				   <th>Prefix:</th>
				   <td>
				   	<input class="form-control" id="experimentPrefix" name="prefix" size="35">
				   </td>
				 </tr>
			</table>
		'''

		ExperimentToolsPageJS::updateAndShowModal(body, true, null, false)

	}

	def static private showExperimentModal(String jsonData) {

		var JsonObject jsonObj = Json.createObject
		jsonObj.put("title", "")
		jsonObj.put("prefix", "")
		jsonObj.put("numQuestionnaires", "")
		jsonObj.put("landscapes", "")

		if (jsonData != null) {

			jsonObj = Json.parse(
				jsonData)

		}

		var body = '''
			<p>Welcome to the Experiment Tools Question Interface.</p>
			<p>Please select an experiment title:</p>
			<table class='table table-striped'>
			  <tr>
			    <th>Experiment Title:</th>
			    <td>
			    	 <input class="form-control" id="experimentTitle" name="title" size="35" value="�jsonObj.getString("title")�">
				</td>
				 </tr>
				 <tr>
				   <th>Prefix:</th>
				   <td>
				   	<input class="form-control" id="experimentPrefix" name="prefix" size="35" value="�jsonObj.getString("prefix")�">
				   </td>
				 </tr>
				 </tr>
				 <tr>
				   <th>Filename:</th>
				   <td>
				   	<input class="form-control"id="experimentFilename" name="filename" size="35" value="�jsonObj.getString("filename")�" readonly>
				   </td>
				 </tr>
			</table>
		'''

		ExperimentToolsPageJS::updateAndShowModal(body, true, jsonData, false)

	}

	def static private showCreateQuestModal(String jsonData) {

		var body = '''			
			<p>Please select an questionnaire title:</p>
			<table class='table table-striped'>
				<tr>
				   	<th>Questionnaire Title:</th>
				   	<td>
				   		<input class="form-control" id="questionnareTitle" name="questionnareTitle" size="35">
					</td>
				</tr>
				 <tr>
				   <th>Prefix:</th>
				   <td>
				   		<input class="form-control" id="questionnarePrefix" name="questionnarePrefix" size="35">
				   </td>
				 </tr>
			</table>
		'''

		ExperimentToolsPageJS::updateAndShowModal(body, true, jsonData, false)

	}

	def static private showQuestModal(String jsonData) {

		var JsonObject data = Json.parse(jsonData)

		var String questionnaireTitle = data.keys.get(0)
		var JsonObject experiment = Json.parse(data.getString(questionnaireTitle))

		var questionnaires = experiment.getArray("questionnaires");

		var title = ""
		var prefix = ""
		var id = ""

		for (var i = 0; i < questionnaires.length(); i++) {

			var JsonObject questionnaire = questionnaires.get(i)

			if (questionnaire.getString("questionnareTitle").equals(questionnaireTitle)) {
				title = questionnaire.getString("questionnareTitle")
				prefix = questionnaire.getString("questionnarePrefix")
				id = questionnaire.getString(
					"questionnareID")
			}
		}

		var body = '''			
			<p>Please select an questionnaire title:</p>
			<table class='table table-striped'>
				<tr>
				   	<th>Questionnaire Title:</th>
				   	<td>
				   		<input class="form-control" id="questionnareTitle" name="questionnareTitle" size="35" value="�title�">
					</td>
				</tr>
				<tr>
					<th>Prefix:</th>
					<td>
						<input class="form-control" id="questionnarePrefix" name="questionnarePrefix" size="35" value="�prefix�">
					</td>
				</tr>
				<tr>
					<th>ID:</th>
					<td>
					  	<input class="form-control" id="questionnareID" name="questionnareID" size="35" value="�id�" readonly>
					</td>
				</tr>
			</table>
		'''

		ExperimentToolsPageJS::updateAndShowModal(body, true, experiment.toJson, false)

	}

	def static private showQuestDetailsModal(String jsonQuestionnaireData) {

		var JsonObject data = Json.parse(
			jsonQuestionnaireData)

		var body = '''			
			<p>Please select an questionnaire title:</p>
			<table class='table table-striped'>
				<tr>
				   	<th>Questionnaire Title:</th>
				   	<td>
				   		<input class="form-control" id="questionnareTitle" name="questionnareTitle" size="35" value="�data.getString("questionnareTitle")�" readonly>
					</td>
				</tr>
				<tr>
					<th>Prefix:</th>
					<td>
					  	<input class="form-control" id="questionnarePrefix" name="questionnarePrefix" size="35" value="�data.getString("questionnarePrefix")�" readonly>
					</td>
				</tr>
				<tr>
					<th>ID:</th>
					<td>
					  	<input class="form-control" id="questionnareID" name="questionnareID" size="35" value="�data.getString("questionnareID")�" readonly>
					</td>
				</tr>
				<tr>
					<th>Number of Questions:</th>
					<td>
					  	<input class="form-control" id="questionnareNumQuestions" name="questionnareNumQuestions" size="35" value="�data.getString("numQuestions")�" readonly>
					</td>
				</tr>
				<tr>
					<th>Used Landscapes:</th>
					<td>
					  	<input class="form-control" id="questionnareLandscapes" name="questionnareLandscapes" size="35" value="�data.getString("landscapes")�" readonly>
					</td>
				</tr>
				<tr>
					<th>Number of Users:</th>
					<td>
					  	<input class="form-control" id="questionnareNumUsers" name="questionnareNumUsers" size="35" value="�data.getString("numUsers")�" readonly>
					</td>
				</tr>
				<tr>
					<th>Last started:</th>
					<td>
						<input class="form-control" id="questionnareStarted" name="questionnareStarted" size="35" value="�data.getString("started")�" readonly>
					</td>
				</tr>
				<tr>
					<th>Last finished:</th>
					<td>
						<input class="form-control" id="questionnareEnded" name="questionnareEnded" size="35" value="�data.getString("ended")�" readonly>
					</td>
				</tr>
			</table>
			<div id="expChartContainer">
				<canvas id="expChart"></canvas>
			</div>
		'''
		
		ExperimentToolsPageJS::updateAndShowModal(body, false, null, false)
		
		setupChart()

	}
	
	def static private showUserManagement(String jsonData) {
		
		var JsonObject data = Json.parse(jsonData)
		
		var questTitle = data.getArray("questionnaireTitle")
		
		var JsonObject experiment = Json.parse(data.getString("experiment"))
		
		var JsonArray jsonUsers = data.getArray("users")

		var questionnaires = experiment.getArray("questionnaires");
		var questPrefix = "";
		
		var JsonObject questionnaire

		for (var i = 0; i < questionnaires.length(); i++) {

			var JsonObject questionnaireTemp = questionnaires.get(i)

			if (questionnaireTemp.getString("questionnareTitle").equals(questTitle)) {
				questPrefix = questionnaireTemp.getString("questionnarePrefix")
				questionnaire = questionnaireTemp
			}
		}

		var body = '''			
			<p>Please select the number of users you want to create:</p>
			<table class='table table-striped'>
				<tr>
				   	<th>Number of users:</th>
				   	<td>
				   		<input class="form-control" id="userCount" name="userCount" size="35">
					</td>
				</tr>
				<tr>
					<th>ID:</th>
					<td>
					  	<input class="form-control" id="questionnareID" name="questionnareID" size="35" value="�questionnaire.getString("questionnareID")�" readonly>
					</td>
				</tr>
				 <tr>
				 	<th>Number of users:</th>
					<td>
					  	<input class="form-control" id="questionnareNumUsers" name="questionnareNumUsers" size="35" value="�jsonUsers.length�" readonly>
					</td>
				 </tr>
			</table>
			<table class="table" id="expUserList" style="text-align:center;">
				<thead>
					<tr>
						<th style="text-align:center;">Name</th>
						<th style="text-align:center;">Password</th>
						<th style="text-align:center;">Done</th>
						<th style="text-align:center;">Remove</th>
					 </tr>
				</thead>
				<tbody>
					�IF jsonUsers.length > 0�
						�FOR i : 0 .. (jsonUsers.length - 1)�								
							�var user = jsonUsers.getObject(i)�
							�var name = user.getString("username")�
							�var password = user.getString("pw")�
							<tr>
							    <td>�name�</td>
							    <td>�password�</td>
							    <td>
							    	<span class="glyphicon glyphicon-ok"></span>
								</td>
							    <td>
									<a class="expRemoveSpan expRemoveLinkCSS" id="expRemoveSingleUser�i�" value="�name�">
										<span class="glyphicon glyphicon-remove"></span>
									</a>
								</td>
							</tr>
				     	�ENDFOR�
				    �ENDIF�
				</tbody>
			</table>
		'''
		
		ExperimentToolsPageJS::updateAndShowModal(body, false, experiment.toJson, true)

	}

	def static void saveToServer(String jsonExperiment) {
		jsonService.saveJSONOnServer(jsonExperiment, new VoidFuncCallback<Void>([loadExpToolsPage]))
	}
	
	def static void createUsers(String prefix, int count) {
		jsonService.createUsersForQuestionnaire(count, prefix, new StringFuncCallback<String>([updateUserModal]))
	}
	
	def static void removeUser(String user) {
		
		var filenameAndQuestTitle = Json.createObject
		filenameAndQuestTitle.put(filenameExperiment, questionnaireTitle)
		
		var data = Json.createObject
		data.put("user", user)
		data.put("filenameAndQuestTitle", filenameAndQuestTitle)
		
		jsonService.removeQuestionnaireUser(data.toJson, new StringFuncCallback<String>([updateUserModal]))
	}
	
	def static updateUserModal(String userData) {
		
		var users = Json.parse(userData).getArray("users")
		
		var data = Json.createObject
		data.put("users", users)
		data.put("questionnaireTitle", questionnaireTitle)
		
		jsonService.getExperiment(filenameExperiment, new JsonExperimentCallback<String>([showUserManagement],data))
	}

}