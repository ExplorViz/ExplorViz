package explorviz.visualization.experiment.pageservices;

import com.google.gwt.user.client.rpc.RemoteService;
import com.google.gwt.user.client.rpc.RemoteServiceRelativePath;

/**
 * @author Santje Finke
 * 
 */
@RemoteServiceRelativePath("tutorialmenu")
public interface TutorialMenuService extends RemoteService {
	public String getPage();
}
