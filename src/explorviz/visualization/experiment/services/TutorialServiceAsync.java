package explorviz.visualization.experiment.services;

import com.google.gwt.user.client.rpc.AsyncCallback;

import explorviz.shared.experiment.Step;

public interface TutorialServiceAsync {

	void getText(int number, AsyncCallback<String> callback);

	void getLanguage(AsyncCallback<String> callback);

	void getLanugages(AsyncCallback<String[]> callback);

	void getSteps(AsyncCallback<Step[]> callback);

}