package explorviz.visualization.experiment

import java.util.ArrayList
import explorviz.shared.experiment.Question
import explorviz.shared.experiment.Answer
import java.util.List
import explorviz.visualization.experiment.services.QuestionServiceAsync
import com.google.gwt.core.client.GWT
import explorviz.visualization.experiment.services.QuestionService
import com.google.gwt.user.client.rpc.ServiceDefTarget
import explorviz.visualization.experiment.callbacks.QuestionsCallback
import explorviz.visualization.services.AuthorizationService
import explorviz.visualization.experiment.callbacks.VoidCallback
import explorviz.visualization.experiment.callbacks.VocabCallback
import explorviz.visualization.experiment.callbacks.ZipCallback
import com.google.gwt.user.client.rpc.AsyncCallback
import explorviz.visualization.main.ErrorDialog
import explorviz.visualization.login.LoginServiceAsync
import explorviz.visualization.login.LoginService
import explorviz.visualization.main.LogoutCallBack

class Questionnaire {
	static int questionNr = 0
	static boolean answeredPersonal = false
	static long timestampStart
	public static List<String> commentVocab = new ArrayList<String>()
	public static List<Question> questions = new ArrayList<Question>()
	public static List<Answer> answers = new ArrayList<Answer>()
	static String userID
	var static QuestionServiceAsync questionService 
	static var formDiv = "<div class='form-group' id='form-group'>"
	static var closeDiv = "</div>"
	public static String language = "" 

	def static startQuestions(){
		questionService = getQuestionService()
		if(questionNr == 0 && !answeredPersonal){
			//start new experiment
			questionService.getLanguageScript(new LanguageCallback())
			questionService.getVocabulary(new VocabCallback())
			questionService.getQuestions(new QuestionsCallback())
			userID = AuthorizationService.getCurrentUsername()
			if(userID.equals("")){
				userID = "DummyUser"
			}
		}else{
			//continue experiment
			var form = getQuestionBox(questions.get(questionNr))
			questionService.setMaxTimestamp(questions.get(questionNr).timeframeEnd, new VoidCallback())
			timestampStart = System.currentTimeMillis()
			var caption = "Question "+questionNr.toString + " of "+ questions.size()
			ExperimentJS::changeQuestionDialog(form, language, caption)
		}
		timestampStart = System.currentTimeMillis()
		ExperimentJS::showQuestionDialog()
	}

	def static getQuestionService(){
		val QuestionServiceAsync questionService = GWT::create(typeof(QuestionService))
		val endpoint = questionService as ServiceDefTarget
		endpoint.serviceEntryPoint = GWT::getModuleBaseURL() + "questionservice"
		return questionService
	}
	
	def static showPersonalDataDialog(List<String> personalVocab) {
		ExperimentJS.personalDataDialog(Questionnaire::getPersonalInformationBox(personalVocab), language)
	}
	
	def static getPersonalInformationBox(List<String> vocab){
		var StringBuilder html = new StringBuilder()
		html.append("<p>"+vocab.get(0)+"</p>")
		html.append("<form class='form' style='width:300px;' role='form' id='questionForm'>")
		//Age-input
		html.append(formDiv+"<label for='ageForm'>"+vocab.get(1)+"</label>
					    <div class='input-group' id='ageForm'>
					       <input type='number' min='18' max='70' class='form-control' placeholder='"+vocab.get(1)+"' name='age' required>
					       <span class='input-group-addon'>"+vocab.get(2)+"</span></div>
					"+closeDiv)
		//Gender-choice
		html.append(formDiv+"<label for='genderForm'>"+vocab.get(3)+"</label>
					    <select class='form-control' id='genderForm' name='gender' required>
					      <option>"+vocab.get(4)+"</option>
					      <option>"+vocab.get(5)+"</option>
					    </select>"+closeDiv)
		//Degree-choice
		html.append(formDiv+"<label for='degreeForm'>"+vocab.get(6)+"</label>
			    <select class='form-control' id='degreeForm' name='degree' required>
			      <option>"+vocab.get(7)+"</option>
			      <option>"+vocab.get(8)+"</option>
				  <option>"+vocab.get(9)+"</option>
			      <option>"+vocab.get(10)+"</option>
			    </select>"+closeDiv)
		//Experience ExplorViz
		html.append(formDiv+"<label for='exp1form'>"+vocab.get(11)+"</label>
				<span class='glyphicon glyphicon-question-sign' data-toggle='tooltip' data-placement='right' title='"+vocab.get(12)+"'></span>
			    <select class='form-control' id='exp1Form' name='exp1' required>
			      <option>"+vocab.get(17)+"</option>
			      <option>"+vocab.get(18)+"</option>
				  <option>"+vocab.get(19)+"</option>
			      <option>"+vocab.get(20)+"</option>
				  <option>"+vocab.get(21)+"</option>
			    </select>"+closeDiv)
		//Experience 
		html.append(formDiv+"<label for='exp2Form'>"+vocab.get(13)+"</label>
				<span class='glyphicon glyphicon-question-sign' data-toggle='tooltip' data-placement='right' title='"+vocab.get(14)+"'></span>
			    <select class='form-control' id='exp2Form' name='exp2' required>
			      <option>"+vocab.get(17)+"</option>
			      <option>"+vocab.get(18)+"</option>
				  <option>"+vocab.get(19)+"</option>
			      <option>"+vocab.get(20)+"</option>
				  <option>"+vocab.get(21)+"</option>
			    </select>"+closeDiv)	
				//Experience 
		html.append(formDiv+"<label for='exp3Form'>"+vocab.get(15)+"</label>
				<span class='glyphicon glyphicon-question-sign' data-toggle='tooltip' data-placement='right' title='"+vocab.get(16)+"'></span>
			    <select class='form-control' id='exp3Form' name='exp3' required>
			      <option>"+vocab.get(17)+"</option>
			      <option>"+vocab.get(18)+"</option>
				  <option>"+vocab.get(19)+"</option>
			      <option>"+vocab.get(20)+"</option>
				  <option>"+vocab.get(21)+"</option>
			    </select>"+closeDiv)
		//Colourblindness
		html.append(formDiv+"<div id='radio' class='input-group'>")
		html.append("<p>"+vocab.get(22)+"</p>")
		html.append("<input type='radio' id='yes' name='colour' value='"+vocab.get(23)+"' style='margin-left:10px;' required>
						<label for='yes' style='margin-right:15px; margin-left:5px'>"+vocab.get(23)+"</label> ")
		html.append("<input type='radio' id='no' name='colour' value='"+vocab.get(24)+"' style='margin-left:10px;' required>
						<label for='no' style='margin-right:15px; margin-left:5px'>"+vocab.get(24)+"</label> ")
		html.append("</div>"+closeDiv)		
		html.append("</form>")
		return html.toString()
	}
	
	def static savePersonalInformation(String answer){
		var StringBuilder answerString = new StringBuilder()
		var String[] answerList = answer.split("&")
		answerString.append(answerList.get(0).substring(4))
		answerString.append(",")
		answerString.append(answerList.get(1).substring(7))
		answerString.append(",")
		answerString.append(answerList.get(2).substring(7).replace("+"," "))
		answerString.append(",")
		answerString.append(answerList.get(3).substring(5).replace("+"," "))
		answerString.append(",")
		answerString.append(answerList.get(4).substring(5).replace("+"," "))
		answerString.append(",")
		answerString.append(answerList.get(5).substring(5).replace("+"," "))
		answerString.append(",")
		answerString.append(answerList.get(6).substring(8))
		answerString.append("\n")
		questionService.writeStringAnswer(answerString.toString(),userID, new VoidCallback())
		answeredPersonal = true
		
		//start questionnaire
		var caption = "Question "+(questionNr+1).toString + " of "+ questions.size()
		ExperimentJS::changeQuestionDialog(getQuestionBox(questions.get(questionNr)), language, caption)
		questionService.setMaxTimestamp(questions.get(questionNr).timeframeEnd, new VoidCallback())
	}
	
	def static getQuestionBox(Question question){
		var StringBuilder html = new StringBuilder()
		html.append("<p>"+question.text+"</p>")
		html.append("<form class='form' role='form' id='questionForm'>")	
		var String[]  ans = question.answers
		html.append(formDiv)
		if(question.type.equals("Free")){
			html.append("<label for='input'>Answer</label>")
			html.append("<div id='input' class='input-group'>")
			var i = 0
			while(i < question.freeAnswers){
	    		html.append("<input type='text' class='form-control' id='input"+i.toString()+"' placeholder='Enter Answer' name='input"+i.toString()+"' minlength='1' autocomplete='off' required>")
				i = i + 1
  			}
  			html.append("</div>")
		}else if(question.type.equals("MC")){
			html.append("<div id='radio' class='input-group'>")
			var i = 0;
			while(i<ans.length){
				html.append("<input type='radio' id='radio"+i+"' name='radio' value='"+ans.get(i)+"' style='margin-left:10px;' required>
							<label for='radio"+i+"' style='margin-right:15px; margin-left:5px'>"+ans.get(i)+"</label> ")
				i = i + 1
			}
			html.append("</div>")
		}else if(question.type.equals("MMC")){
			html.append("<div id='check' class='input-group'>")
			var i = 0;
			while(i<ans.length){
				html.append("<input type='checkbox' id='check"+i+"' name='check' value='"+ans.get(i)+"' style='margin-left:10px;'>
							<label for='check"+i+"' style='margin-right:15px; margin-left:5px'>"+ans.get(i)+"</label> ")
			    i = i + 1
			}
			html.append("</div>")
		}
		html.append(closeDiv)
		html.append("</form>")
		return html.toString()
	}
	
	def static nextQuestion(String answer){
		var newTime = System.currentTimeMillis()
		var timeTaken = newTime-timestampStart
		var Answer ans = new Answer(questions.get(questionNr).questionID, answer, timeTaken, timestampStart, newTime, userID)
		answers.add(ans)
		questionService.writeAnswer(ans, new VoidCallback())
		
		if(questionNr == questions.size()-1){
			ExperimentJS::tutorialCommentDialog(getTutorialCommentBox(), language)
			questionNr = 0
		}else{
			//if not last question
			questionNr = questionNr + 1
			var form = getQuestionBox(questions.get(questionNr))
			questionService.setMaxTimestamp(questions.get(questionNr).timeframeEnd, new VoidCallback())
			timestampStart = System.currentTimeMillis()
			var caption = "Question "+(questionNr+1).toString + " of "+ questions.size()
			ExperimentJS::changeQuestionDialog(form, language, caption)
		}
	}
	
	def static getTutorialCommentBox(){
		var StringBuilder html = new StringBuilder()
		html.append("<form class='form' role='form' id='questionForm'>")
		html.append(formDiv+"<label for='difficultyForm'>"+commentVocab.get(0)+"</label>
					<span class='glyphicon glyphicon-question-sign' data-toggle='tooltip' data-placement='right' title='"+commentVocab.get(1)+"'></span>
					<select class='form-control' id='difficultyForm' name='difficulty' required>
						<option>1</option>	
						<option>2</option>
						<option>3</option>
						<option>4</option>
						<option>5</option>
					</select>"+closeDiv)
		html.append(formDiv+"<label for='tutHelpForm'>"+commentVocab.get(2)+"</label>
			<span class='glyphicon glyphicon-question-sign' data-toggle='tooltip' data-placement='right' title='"+commentVocab.get(3)+"'></span>
			<select class='form-control' id='tutHelpForm' name='tuthelp' required>
				<option>1</option>	
				<option>2</option>
				<option>3</option>
				<option>4</option>
				<option>5</option>
			</select>"+closeDiv)
		html.append("<label for='tutCommentForm'>"+commentVocab.get(4)+"</label>
			<textarea class='form-control' id='tutCommentForm' name='tutComment' rows='3'></textarea>
		")
		html.append("</form>")
		return html.toString()
	}
	
	def static getExplorVizCommentBox(){
		var StringBuilder html = new StringBuilder()
		html.append("<form class='form' role='form' id='questionForm'>")

		//Email
		html.append(formDiv+"<label for='emailForm'>"+commentVocab.get(5)+"</label>
			 	<input type='email' class='form-control' placeholder='"+commentVocab.get(5)+"' id='emailForm' name='email'>
			 	"+closeDiv)
		html.append("</form>")
		return html.toString()
	}

	def static saveTutorialComments(String answer){
		var StringBuilder answerString = new StringBuilder()
		var String[] answerList = answer.split("&")
		answerString.append(answerList.get(0).substring(11)) //difficulty
		answerString.append(",")
		answerString.append(answerList.get(1).substring(8)) //tutorial help
		answerString.append(",")
		var comment = answerList.get(2).substring(11).replace("+"," ") //tutorial comments 
		comment = comment.replace("%0D%0A"," ")
		answerString.append(comment)
//		answerString.append(",")
//		answerString.append(answerList.get(3).substring(10)) //questionnaire help
//		answerString.append(",")
//		comment = answerList.get(4).substring(13).replace("+"," ") //questionnaire comment
//		comment = comment.replace("%0D%0A"," ")
//		answerString.append(comment)
//		answerString.append(",")
//		comment = answerList.get(5).substring(13).replace("+"," ") //other comments
//		comment = comment.replace("%0D%0A"," ")
//		answerString.append(comment)
//		answerString.append(",")
//		answerString.append(answerList.get(6).substring(6).replace("%40","@"))//email
		answerString.append("\n")
		questionService.writeStringAnswer(answerString.toString(),userID, new VoidCallback())
		ExperimentJS::explorvizCommentDialog(getExplorVizCommentBox(), language)
	}
	
	def static saveExplorVizComments(String answer){
		var StringBuilder answerString = new StringBuilder()
		var String[] answerList = answer.split("&")
		
		answerString.append(answerList.get(0).substring(6).replace("%40","@"))//email
		answerString.append("\n")
		questionService.writeStringAnswer(answerString.toString(),userID, new VoidCallback())
		ExperimentJS::finishQuestionnaireDialog("<p>"+commentVocab.get(6)+"</p>")
	}
	
	def static finishQuestionnaire(){
		ExperimentJS::closeQuestionDialog()
		
		val LoginServiceAsync loginService = GWT::create(typeof(LoginService))
		val endpoint = loginService as ServiceDefTarget
		endpoint.serviceEntryPoint = GWT::getModuleBaseURL() + "loginservice"
		loginService.logout(new LogoutCallBack)
		
	}
	
	def static downloadAnswers() {
		if(questionService==null){
			questionService = getQuestionService()
		}
		questionService.downloadAnswers(new ZipCallback())
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