package explorviz.visualization.view.menu;

import com.google.gwt.user.client.rpc.RemoteService;
import com.google.gwt.user.client.rpc.RemoteServiceRelativePath;

@RemoteServiceRelativePath("configurationmenu")
public interface ConfigurationMenuService extends RemoteService {
    public String getPage();
}