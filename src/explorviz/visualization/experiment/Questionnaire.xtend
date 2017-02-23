package explorviz.visualization.experiment

import java.util.ArrayList
import explorviz.shared.experiment.Question
import explorviz.shared.experiment.Answer
import java.util.List
import explorviz.visualization.experiment.services.QuestionServiceAsync
import explorviz.visualization.services.AuthorizationService
import explorviz.visualization.experiment.callbacks.VoidCallback
import explorviz.visualization.experiment.callbacks.DialogCallback
import explorviz.visualization.experiment.callbacks.ZipCallback
import com.google.gwt.user.client.rpc.AsyncCallback
import explorviz.visualization.main.ErrorDialog
import explorviz.visualization.main.LogoutCallBack
import explorviz.visualization.experiment.callbacks.SkipCallback
import explorviz.visualization.main.ExplorViz
import explorviz.visualization.engine.main.SceneDrawer
import explorviz.visualization.experiment.callbacks.EmptyLandscapeCallback
import explorviz.visualization.main.Util
import explorviz.visualization.experiment.services.JSONServiceAsync
import explorviz.visualization.experiment.callbacks.GenericFuncCallback
import explorviz.shared.model.Landscape
import explorviz.visualization.main.JSHelpers
import explorviz.visualization.engine.Logging
import explorviz.shared.experiment.Prequestion
import explorviz.shared.experiment.Postquestion
import com.google.gwt.user.client.ui.FormPanel
import com.google.gwt.core.client.GWT
import com.google.gwt.user.client.DOM
import com.google.gwt.user.client.ui.RootPanel
import com.google.gwt.user.client.ui.FormPanel.SubmitCompleteEvent
import com.google.gwt.user.client.Window
import com.google.gwt.user.client.ui.FileUpload
import com.google.gwt.user.client.ui.VerticalPanel
import com.google.gwt.event.dom.client.ClickHandler
import com.google.gwt.user.client.ui.Button
import com.google.gwt.event.dom.client.ClickEvent
import com.google.gwt.user.client.ui.FormPanel.SubmitEvent
import com.google.gwt.user.client.ui.Label
import com.google.gwt.user.client.ui.DialogBox
import com.google.gwt.user.client.ui.SimplePanel
import com.google.gwt.user.client.ui.HTML

/**
 * @author Santje Finke
 * 
 */
class Questionnaire {
	static int questionNr = 0
	static boolean answeredPersonal = false
	static long timestampStart
	static ArrayList<Prequestion> preDialog;
	static ArrayList<Postquestion> postDialog;
	public static List<Question> questions = new ArrayList<Question>()
	public static List<Answer> answers = new ArrayList<Answer>()
	static String userID
	var static QuestionServiceAsync questionService
	public static String language = ""
	public static boolean allowSkip = false
	public static QuestionTimer qTimer

	var static JSONServiceAsync jsonService
	public static String experimentFilename = null
	private static String experimentName = null
	
	public static boolean preAndPostquestions = false
	public static boolean eyeTracking = false
	public static boolean screenRecording = false
	private static FormPanel uploadFormPanel;
	private static FileUpload uploadItem;

	def static void startQuestions() {
		
		if(experimentFilename == null)
			return;
		
		jsonService = Util::getJSONService()
		questionService = Util::getQuestionService()
		
		if (questionNr == 0 && !answeredPersonal) {
			// start new experiment
			questionService.getLanguage(new GenericFuncCallback<String>(
				[
					String result | 
					Questionnaire.language = result
				]
			))

			userID = AuthorizationService.getCurrentUsername()
			qTimer = new QuestionTimer(8)
			
			//get preAndPostquestions, eyeTracking and RecordScreen from JSON
			initQuestionnaireSpecialSettings()
		}
		else {
			// continue experiment
			var form = getQuestionBox(questions.get(questionNr))
			Util::landscapeService.getLandscape(questions.get(questionNr).timestamp, questions.get(questionNr).activity, new GenericFuncCallback<Landscape>([updateClientLandscape]))
			timestampStart = System.currentTimeMillis()
			var caption = experimentName + ": " + "Question " + questionNr.toString + " of " + questions.size()
			ExperimentJS::changeQuestionDialog(form, language, caption, allowSkip)
			
			timestampStart = System.currentTimeMillis()			
			ExperimentJS::showQuestionDialog()
		}
	}
	
	// @author: Maria (ich soll schreiben und so TODO
	def static finishStart(Question[] questions) {		
		var List<Question> list = new ArrayList<Question>();
		for(Question q : questions){
			list.add(q)
		}
		Questionnaire::questions = list
		
		questionService.allowSkip(new SkipCallback())

		if (userID.equals("")) {
			userID = "DummyUser"
		}
		
		timestampStart = System.currentTimeMillis()
		var content = Util::dialogMessages.expProbandModalStart()
		ExperimentJS::showExperimentStartModal(experimentName, content)
	}
	
	def static continueAfterModal() {
		ExperimentJS::showQuestionDialog()
		jsonService.getQuestionnairePrequestionsForUser(experimentFilename, userID, new GenericFuncCallback<ArrayList<Prequestion>>([showPrequestionDialog]))
	}

	
	def static getFullForm(boolean prequestions) {
		if(prequestions) {
			 return getPrequestionForm()
		} else {
			 return getPostquestionForm()
		}
	}
	
	def static getPrequestionForm() {
		
		var StringBuilder html = new StringBuilder()
		html.append("<form class='form' role='form' id='questionForm'>")
		
		var Prequestion currentQuestion;
		//append for every question
		for (var j = 0; j < preDialog.size(); j++) {
			currentQuestion = preDialog.get(j)
			if(currentQuestion.getText() != "") {
				//append a div and a label for every question
				html.append("<div class='form-group' id='form-group'>")
				html.append("<label for='"+(j+1)+"'>"+currentQuestion.getText()+"</label>")
			
				//append special answer input
				html.append(currentQuestion.getTypeDependentHTMLInput())
			
				html.append("</div>")
			}
		}
		
		html.append("</form>")
		return html.toString()
		
	}
	
	def static getPostquestionForm() {
		var StringBuilder html = new StringBuilder()
		html.append("<form class='form' role='form' id='questionForm'>")
		
		var Postquestion currentQuestion;
		//append for every question
		for (var j = 0; j < postDialog.size(); j++) {
			currentQuestion = postDialog.get(j)
			if(currentQuestion.getText() != "") {
				//append a div and a label for every question
				html.append("<div class='form-group' id='form-group'>")
				html.append("<label for='"+(j+1)+"'>"+currentQuestion.getText()+"</label>")
			
				//append special answer input
				html.append(currentQuestion.getTypeDependentHTMLInput())
			
				html.append("</div>")
			}
		}
		
		html.append("</form>")
		return html.toString()
	}

	def static saveStatisticalAnswers(String answer) {
		var StringBuilder answerString = new StringBuilder()
		var String[] answerList = answer.split("&")
		var String s;
		for (var int i = 0; i < answerList.length; i++) {
			s = answerList.get(i)
			s = cleanInput(s.substring(s.indexOf("=") + 1))
			answerString.append(s)
			if (i + 1 == answerList.length) {
				answerString.append("\n")
			} else {
				answerString.append(",")
			}
		}
		questionService.writeStringAnswer(answerString.toString(), userID, new VoidCallback())
	}

	def static showPrequestionDialog(ArrayList<Prequestion> loadedPrequestions) {
		if(loadedPrequestions.size() == 0 || !preAndPostquestions) {
			introQuestionnaire()
		} else {
			preDialog = loadedPrequestions
			var forms = getFullForm(true)
			ExperimentJS.showPrequestionDialog(forms, language)
		}
	}

 	def static savePrequestionForm(String answer) {
		saveStatisticalAnswers(answer)
		introQuestionnaire()
	}

	/**
	 * Starts the main part of the questionnaire: displays first question, starts the timer
	 */
	def static introQuestionnaire() {
		//start eyeTracking and/or screen recording
		jsonService.getQuestionnairePrefix(userID, new GenericFuncCallback<String>([
			String questionnairePrefix |
			ExperimentJS::startEyeTrackingScreenRecording(eyeTracking, screenRecording, userID, questionnairePrefix)
			//start a predialog for user
			ExperimentJS::showMainQuestionsStartModal();
		]))
	}
	
	def static startMainQuestionsDialog() {
		// start questionnaire
		Util::landscapeService.getLandscape(questions.get(questionNr).timestamp, questions.get(questionNr).activity, new GenericFuncCallback<Landscape>([updateClientLandscape]))
		qTimer.setTime(System.currentTimeMillis())
		qTimer.setMaxTime(questions.get(questionNr).worktime)
		qTimer.scheduleRepeating(1000)
		var caption = experimentName + ": " + "Question " + (questionNr + 1).toString + " of " + questions.size()
		ExperimentJS::changeQuestionDialog(getQuestionBox(questions.get(questionNr)), language, caption, allowSkip)
	}

	/**
	 * Builds the html form for the given question
	 * @param question The question that shall be displayed
	 */
	def static getQuestionBox(Question question) {
		var StringBuilder html = new StringBuilder()
		html.append("<p>" + question.text + "</p>")
		html.append("<form class='form' role='form' id='questionForm'>")
		var String[] ans = question.answers
		html.append("<div class='form-group' id='form-group'>")
		if (question.type.equals("Free")) {
			html.append("<label for='input'>Answer</label>")
			html.append("<div id='input' class='input-group'>")
			if (question.freeAnswers > 1) {
				for (var i = 0; i < question.freeAnswers; i++) {
					html.append(
						"<input type='text' class='form-control' id='input" + i.toString() +
							"' placeholder='Enter Answer' name='input" + i.toString() +
							"' minlength='1' autocomplete='off' required>")
				}
			} else { // only one question gets a textbox
				html.append(
						"<textarea class='form-control questionTextarea' id='input1' name='input1' rows='2' required></textarea>"
				)
			}
				html.append("</div>")
		} else if (question.type.equals("MC")) {
			html.append("<div id='radio' class='input-group'>")
			var i = 0;
			while (i < ans.length) {
				html.append("<input type='radio' id='radio" + i + "' name='radio' value='" + ans.get(i) + "' style='margin-left:10px;' required>
					<label for='radio" + i + "' style='margin-right:15px; margin-left:5px'>" + ans.get(i) +
					"</label> ")
				i = i + 1
			}
			html.append("</div>")
		} else if (question.type.equals("MMC")) {
			html.append("<div id='check' class='input-group'>")
			var i = 0;
			while (i < ans.length) {
				html.append("<input type='checkbox' id='check" + i + "' name='check' value='" + ans.get(i) + "' style='margin-left:10px;'>
					<label for='check" + i + "' style='margin-right:15px; margin-left:5px'>" + ans.get(i) +
					"</label> ")
				i = i + 1
			}
			html.append("</div>")
		}
		html.append("</div>")
		html.append("</form>")
		return html.toString()
	}

			/**
			 * Saves the answer that was given for the previous question and loads 
			 * the new question or ends the questionnaire if it was the last question.
			 * @param answer The answer to the previous question
			 */
			def static nextQuestion(String answer) {
				var newTime = System.currentTimeMillis()
				var timeTaken = newTime - timestampStart
				var Answer ans = new Answer(questions.get(questionNr).questionID, cleanInput(answer), timeTaken,
					timestampStart, newTime, userID)
				answers.add(ans)
				questionService.writeAnswer(ans, new VoidCallback())
				if (questionNr == questions.size() - 1) {	//if last question
					SceneDrawer::lastViewedApplication = null
					questionService.getEmptyLandscape(new EmptyLandscapeCallback())
					//stop eye tracking / screen recording
					ExperimentJS::stopEyeTrackingScreenRecording()
					if(preAndPostquestions){
						jsonService.getQuestionnairePostquestionsForUser(experimentFilename, userID, new GenericFuncCallback<ArrayList<Postquestion>>([showPostquestionDialog]))
						
					} else {
						finishQuestionnaire()
					}	
					qTimer.cancel()
					ExperimentJS::hideTimer()
					questionNr = 0
				} else {
					// if not last question
					ExperimentJS::hideTimer()
					questionNr = questionNr + 1
					var form = getQuestionBox(questions.get(questionNr))
					Util::landscapeService.getLandscape(questions.get(questionNr).timestamp, questions.get(questionNr).activity, new GenericFuncCallback<Landscape>([updateClientLandscape]))
					timestampStart = System.currentTimeMillis()
					qTimer.setTime(timestampStart)
					qTimer.setMaxTime(questions.get(questionNr).worktime)
					var caption = experimentName + ": " + "Question " + (questionNr + 1).toString + " of " + questions.size()
					ExperimentJS::changeQuestionDialog(form, language, caption, allowSkip)
				}
			}
			
			def static showPostquestionDialog(ArrayList<Postquestion> loadedPostquestions) {
				if(loadedPostquestions.size() == 0 || loadedPostquestions.get(0).getText() == "") {
					finishQuestionnaire()
				} else {
					postDialog = loadedPostquestions
					ExperimentJS::showPostquestionDialog(getFullForm(false), language)
				}
			}
			
			def static updateClientLandscape(Landscape l) {
				
				var maybeApplication = questions.get(questionNr).maybeApplication
				
				if(maybeApplication.equals("")) {
						SceneDrawer::createObjectsFromLandscape(l, false)
					}
					else {
						for (system : l.systems) {
							for (nodegroup : system.nodeGroups) {
								for (node : nodegroup.nodes) {
									for (application : node.applications) {
										if (application.name.equals(maybeApplication)) {											
											SceneDrawer::createObjectsFromApplication(application, false)
											
											JSHelpers::hideElementById("openAllComponentsBtn")
											JSHelpers::hideElementById("export3DModelBtn")
											JSHelpers::hideElementById("performanceAnalysisBtn")
											JSHelpers::hideElementById("virtualRealityModeBtn")
											JSHelpers::hideElementById("databaseQueriesBtn")
											
											return;
										}
									}
								}
							}
						}
					}
			}

			/**
			 * Save answers of Postquestions and 
			 */
			def static savePostquestionForm(String answer) {
				saveStatisticalAnswers(answer)
				finishQuestionnaire()
			}

			/**
			 * Ends the experiment and logs out the user.
			 */
			def static finishQuestionnaire() {
				//in case of screen recording, let the user first upload the local files
				
				if(screenRecording) {
					startJSForUploadFilesToServer()
					//ExperimentJS::startFileUploadDialogToServer() //sweetAlert with not enough functionality
					ExperimentJS::closeQuestionDialog()
				} else {
					ExperimentJS::closeQuestionDialog()	
					Util::getLoginService.setFinishedExperimentState(true, new GenericFuncCallback<Void>([finishLogout]))	
				}				
			}
			
			def static void finishLogout() {
				Util::getLoginService.logout(new LogoutCallBack)
			}

			/**
			 * Downloads the answers as a .zip
			 */
			def static downloadAnswers() {
				if (questionService == null) {
					questionService = Util::getQuestionService()
				}
				questionService.downloadAnswers(new ZipCallback())
			}

			def static cleanInput(String s) {
				var cleanS = s.replace("+", " ").replace("%40", "@").replace("%0D%0A", " ") // +,@,enter
				cleanS = cleanS.replace("%2C", "U+002C").replace("%3B", "U+003B").replace("%3A", "U+003A") // ,, ;, :,
				cleanS = cleanS.replace("%C3%A4", "U+00E4").replace("%C3%BC", "U+00FC").replace("%C3%B6", "U+00F6").
					replace("%C3%9F", "U+00DF") // �, �, �, �
				cleanS = cleanS.replace("%C3%84", "U+00C4").replace("%C3%9C", "U+00DC").replace("%C3%96", "U+00D6") // �, �, � 
				cleanS = cleanS.replace("%26", "U+0026").replace("%3F", "U+003F").replace("%22", "U+0022") // &, ? , " 
				cleanS = cleanS.replace("%7B", "U+007B").replace("%7D", "U+007D").replace("%2F", "U+002F") // {,},/
				cleanS = cleanS.replace("%5B", "U+005B").replace("%5D", "U+005D").replace("%5C", "U+005C") // [, ], \
				cleanS = cleanS.replace("%23", "U+0023") // #
				return cleanS
			}
			
			def static boolean getPreAndPostquestions() {
				return preAndPostquestions
			}
			
			def static initPreAndPostquestions(boolean newPreAndPostquestions) {
				preAndPostquestions = newPreAndPostquestions 
				jsonService.getQuestionnaireEyeTracking(experimentFilename, userID, "", new GenericFuncCallback<Boolean>([initEyeTracking]))
			}
			
			def static initEyeTracking(boolean newEyeTracking) {
				eyeTracking = newEyeTracking
				jsonService.getQuestionnaireRecordScreen(experimentFilename, userID, "", new GenericFuncCallback<Boolean>([initScreenRecording]))
			}
			
			def static initScreenRecording(boolean newScreenRecording) {
				screenRecording = newScreenRecording
				finishInitOfQuestionnaire()
			}
			
			def static initQuestionnaireSpecialSettings() {	//workaround for asynchron race-conditions
				jsonService.getQuestionnairePreAndPostquestions(experimentFilename, userID, "", new GenericFuncCallback<Boolean>([initPreAndPostquestions]))		
			}
			
			def static finishInitOfQuestionnaire() {
				jsonService.getExperimentTitle(experimentFilename, new GenericFuncCallback<String>(
							[
								String name | 
								experimentName = name
								jsonService.getQuestionnaireQuestionsForUser(experimentFilename, userID, new GenericFuncCallback<Question[]>([finishStart]))
							]
						))
			}
				
				
	def static startJSForUploadFilesToServer() {
				
		var DialogBox dialog = new DialogBox(false, true);
		//dialog.setStyleName("modal-dialog-center");
    	// Create a FormPanel and point it at a service.
    	uploadFormPanel = new FormPanel();
    	uploadFormPanel.setAction(GWT.getModuleBaseURL()+"uploadfileservice");

    	// Because we're going to add a FileUpload widget, we'll need to set the
    	// form to use the POST method, and multipart MIME encoding.
    	uploadFormPanel.setEncoding(FormPanel.ENCODING_MULTIPART);
    	uploadFormPanel.setMethod(FormPanel.METHOD_POST);

    	// Create a panel to hold all of the form widgets.
    	var VerticalPanel panel = new VerticalPanel();
    	

		//add text and title to dialog
		dialog.setHTML("<h3>Please Select Your Screen Recording</h3>");
		var labelContent = "<h4>Your final task arrived. Please select the file <b><i>" 
			+ "..." + userID + ".mp4</i></b> <br> in your <i>/Downloads</i> folder and submit.</h4>";
		var HTML label = new HTML(labelContent);
		panel.add(label);
		
    	// Create a FileUpload widget.
    	uploadItem = new FileUpload();
    	uploadItem.setName("uploadFormElement");
    	panel.add(uploadItem);

    	// Add a 'submit' button
    	var submitButton = new Button("Submit", new ClickHandler() {
      		override onClick(ClickEvent event) {
        		uploadFormPanel.submit();
      		}
    	});
    	submitButton.setStyleName("btn btn-info");
    	
    	panel.add(submitButton);
    	

    	// Add an event handler to the form.
    	uploadFormPanel.addSubmitHandler(new FormPanel.SubmitHandler() {
      		override onSubmit(SubmitEvent event) {
        		// validate input of FileUpload widget
        		if (uploadItem.getFilename.length() == 0) {
          			Window.alert("The fileupload must not be empty");
          			event.cancel();
        		}
        		
      		}
    	});
    	uploadFormPanel.addSubmitCompleteHandler(new FormPanel.SubmitCompleteHandler() {
      		override onSubmitComplete(SubmitCompleteEvent event) {        		
        		//show user response from server
        		ExperimentJS::showSwalResponse(event.getResults());
      		}
    	});
    	
    	//get some kind of RootPanel or Dialog back from somewhere and add uploadFormPanel
    	uploadFormPanel.setWidget(panel);
    	dialog.setWidget(uploadFormPanel);
    	
    	var rootpanel = RootPanel.get();
    	rootpanel.add(dialog);

    	dialog.center();
    	dialog.show();
	}
	
	def static closeAndFinishExperiment() {
		ExperimentJS::closeQuestionDialog()	
		Util::getLoginService.setFinishedExperimentState(true, new GenericFuncCallback<Void>([finishLogout]))
	}
	
	def static startUploadEyeTrackingData(String eyeTrackingData) {
		//RPC to server for upload of data
		jsonService.uploadEyeTrackingData(experimentName, userID, eyeTrackingData, new GenericFuncCallback<Boolean>([
			boolean response |
			
		]));
	}
			
}

		class LanguageCallback implements AsyncCallback<String> {

			override onFailure(Throwable caught) {
				ErrorDialog::showError(caught)
			}

			override onSuccess(String result) {
				Questionnaire.language = result
			}

		}
		
		
		
		
		