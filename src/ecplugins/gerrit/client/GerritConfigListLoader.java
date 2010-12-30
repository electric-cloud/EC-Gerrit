
// GerritConfigListLoader.java --
//
// GerritConfigListLoader.java is part of ElectricCommander.
//
// Copyright (c) 2005-2010 Electric Cloud, Inc.
// All rights reserved.
//

package ecplugins.gerrit.client;

import java.util.HashMap;
import java.util.Map;

import com.google.gwt.http.client.Request;
import com.google.gwt.http.client.RequestCallback;
import com.google.gwt.http.client.RequestException;
import com.google.gwt.http.client.Response;

import com.electriccloud.commander.gwt.client.ChainedCallback;
import com.electriccloud.commander.gwt.client.ComponentBase;
import com.electriccloud.commander.gwt.client.domain.Property;
import com.electriccloud.commander.gwt.client.requests.CgiRequestProxy;
import com.electriccloud.commander.gwt.client.requests.GetPropertyRequest;
import com.electriccloud.commander.gwt.client.responses.CommanderError;
import com.electriccloud.commander.gwt.client.responses.PropertyCallback;
import com.electriccloud.commander.gwt.client.util.StringUtil;

import ecinternal.client.HasErrorPanel;
import ecinternal.client.Loader;

import static com.electriccloud.commander.gwt.client.ComponentBaseFactory.getPluginName;

public class GerritConfigListLoader
    extends Loader
{

    //~ Instance fields --------------------------------------------------------

    private final GerritConfigList m_configList;
    private final CgiRequestProxy  m_cgiRequestProxy;
    private String                 m_editorName;

    //~ Constructors -----------------------------------------------------------

    public GerritConfigListLoader(
            GerritConfigList configList,
            ComponentBase    queryObject,
            ChainedCallback  callback)
    {
        this(configList, null, queryObject, callback);
    }

    public GerritConfigListLoader(
            GerritConfigList configList,
            String           implementedMethod,
            ComponentBase    queryObject,
            ChainedCallback  callback)
    {
        super(queryObject, callback);
        m_configList      = configList;
        m_cgiRequestProxy = new CgiRequestProxy(getPluginName(), "gerrit.cgi");
    }

    //~ Methods ----------------------------------------------------------------

    @Override public void load()
    {
        Map<String, String> cgiParams = new HashMap<String, String>();

        cgiParams.put("cmd", "getCfgList");
        loadConfigs(cgiParams);
    }

    private void loadConfigs(Map<String, String> cgiParams)
    {

        try {
            String request = m_cgiRequestProxy.issueGetRequest(cgiParams,
                    new RequestCallback() {
                        @Override public void onError(
                                Request   request,
                                Throwable exception)
                        {
                            ((HasErrorPanel) m_queryObject).addErrorMessage(
                                "Error loading Gerrit configuration list: ",
                                exception);
                        }

                        @Override public void onResponseReceived(
                                Request  request,
                                Response response)
                        {
                            String responseString = response.getText();

                            // if HTML returned we never made it to the CGI
                            Boolean isHtml = (responseString.indexOf(
                                        "DOCTYPE HTML") != -1);
                            String  error;

                            if (!isHtml) {
                                error = m_configList.parseResponse(
                                        responseString);
                            }
                            else {
                                error = responseString;
                            }

                            if (m_queryObject.getLog()
                                             .isDebugEnabled()) {
                                m_queryObject.getLog()
                                             .debug(
                                                 "Recieved CGI response: "
                                                 + responseString
                                                 + " isHTML:" + isHtml
                                                 + " error:" + error);
                            }

                            if (error != null) {
                                ((HasErrorPanel) m_queryObject).addErrorMessage(
                                    error);
                            }
                            else {

                                if (StringUtil.isEmpty(m_editorName)
                                        || m_configList.isEmpty()) {

                                    // We're done!
                                    if (m_callback != null) {
                                        m_callback.onComplete();
                                    }
                                }
                                else {
                                    loadEditors();
                                }
                            }
                        }
                    });

            if (m_queryObject.getLog()
                             .isDebugEnabled()) {
                m_queryObject.getLog()
                             .debug("Issued CGI request: " + request);
            }
        }
        catch (RequestException e) {

            if (m_queryObject instanceof HasErrorPanel) {
                ((HasErrorPanel) m_queryObject).addErrorMessage(
                    "Error loading SCM configuration list: ", e);
            }
            else {
                m_queryObject.getLog()
                             .error(e);
            }
        }
    }

    
    private void loadEditors()
    {
        GetPropertyRequest request = m_queryObject.getRequestFactory()
                                                  .createGetPropertyRequest();
        
        request.setPropertyName("/plugins/EC-Gerrit/project/ui_forms/" 
                + m_editorName);                
        request.setExpand(false);
        request.setCallback(new EditorLoaderCallback("gerritcfg"));
        m_queryObject.doRequest(new ChainedCallback() {
                @Override public void onComplete()
                {
                
                    // We're done!
                    if (m_callback != null) {
                        m_callback.onComplete();
                    }
                }
            }, request);        
    }
    
    public void setEditorName(String editorName)
    {
        m_editorName = editorName;
    }

    //~ Inner Classes ----------------------------------------------------------

    public class EditorLoaderCallback
        implements PropertyCallback
    {

        //~ Instance fields ----------------------------------------------------

        private final String m_configPlugin;

        //~ Constructors -------------------------------------------------------

        public EditorLoaderCallback(String configPlugin)
        {
            m_configPlugin = configPlugin;
        }

        //~ Methods ------------------------------------------------------------

        @Override public void handleError(CommanderError error)
        {
            
            if (m_queryObject instanceof HasErrorPanel) {
                ((HasErrorPanel) m_queryObject).addErrorMessage(error);
            }
            else {
                m_queryObject.getLog()
                             .error(error);
            }
        }

        @Override public void handleResponse(Property response)
        {

            if (m_queryObject.getLog()
                             .isDebugEnabled()) {
                m_queryObject.getLog()
                             .debug("Commander getProperty request returned: "
                                 + response);
            }

            if (response != null) {
                String value = response.getValue();

                if (!StringUtil.isEmpty(value)) {
                    m_configList.setEditorDefinition(m_configPlugin, value);

                    return;
                }
            }

            // There was no property value found in the response
            String errorMsg = "Editor '" + m_editorName
                + "' not found for Gerrit plugin '" + m_configPlugin + "'";

            if (m_queryObject instanceof HasErrorPanel) {
                ((HasErrorPanel) m_queryObject).addErrorMessage(errorMsg);
            }
            else {
                m_queryObject.getLog()
                             .error(errorMsg);
            }
        }
    }
}
