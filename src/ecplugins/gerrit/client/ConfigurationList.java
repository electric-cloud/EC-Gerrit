// ConfigurationList.java --
//
// ConfigurationList.java is part of ElectricCommander.
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
import com.google.gwt.user.client.Window.Location;
import com.google.gwt.user.client.ui.Anchor;
import com.google.gwt.user.client.ui.Label;
import com.google.gwt.user.client.ui.Widget;
import com.google.gwt.xml.client.Node;

import com.electriccloud.commander.gwt.client.ChainedCallback;
import com.electriccloud.commander.gwt.client.ListBase;
import com.electriccloud.commander.gwt.client.legacyrequests.RunProcedureRequest;
import com.electriccloud.commander.gwt.client.protocol.xml.CommanderRequestCallback;
import com.electriccloud.commander.gwt.client.requests.CgiRequestProxy;
import com.electriccloud.commander.gwt.client.responses.CommanderError;
import com.electriccloud.commander.gwt.client.ui.ListTable;
import com.electriccloud.commander.gwt.client.ui.SimpleErrorBox;
import com.electriccloud.commander.gwt.client.util.CommanderUrlBuilder;
import com.electriccloud.commander.gwt.client.util.XmlUtil;

import static com.electriccloud.commander.gwt.client.util.CommanderUrlBuilder.createPageUrl;
import static com.electriccloud.commander.gwt.client.util.CommanderUrlBuilder.createRedirectUrl;

import static com.electriccloud.commander.gwt.client.ComponentBaseFactory.getPluginName;
import static com.electriccloud.commander.gwt.client.ui.ListTable.constructActionList;

/**
 * EC-Gerrit Configuration List.
 */
public class ConfigurationList
    extends ListBase
{

    //~ Instance fields --------------------------------------------------------

    private GerritConfigList m_configList;

    //~ Constructors -----------------------------------------------------------

    public ConfigurationList()
    {
        super("ecgc","Gerrit Configurations", "All Configurations");
        m_configList = new GerritConfigList();
    }

    //~ Methods ----------------------------------------------------------------

    @Override protected Anchor constructCreateLink()
    {
        CommanderUrlBuilder urlBuilder = createPageUrl(getPluginName(),
                "newConfiguration");

        urlBuilder.setParameter("redirectTo",
            createRedirectUrl().buildString());

        return new Anchor("Create Configuration", urlBuilder.buildString());
    }

    @Override protected void load()
    {
        setStatus("Loading...");

        GerritConfigListLoader loader = new GerritConfigListLoader(m_configList, this,
                new ChainedCallback() {
                    @Override public void onComplete()
                    {
                        loadList();
                    }
                });

        loader.load();
    }

    private void deleteConfiguration(String configName)
    {
        setStatus("Deleting...");
        clearErrorMessages();

        // Build runProcedure request
        RunProcedureRequest request = new RunProcedureRequest(
                "/plugins/EC-Gerrit/project", "DeleteConfiguration");

        request.addActualParameter("config", configName);

        // Launch the procedure
        registerCallback(request.getRequestId(),
            new CommanderRequestCallback() {
                @Override public void handleError(Node responseNode)
                {
                    addErrorMessage(new CommanderError(responseNode));
                }

                @Override public void handleResponse(Node responseNode)
                {

                    if (getLog().isDebugEnabled()) {
                        getLog().debug(
                            "Commander runProcedure request returned: "
                            + responseNode);
                    }

                    waitForJob(XmlUtil.getNodeValueByName(responseNode, "jobId"));
                }
            });

        if (getLog().isDebugEnabled()) {
            getLog().debug("Issuing Commander request: " + request);
        }

        doRequest(request);
    }

    private void loadList()
    {
        ListTable listTable = getListTable();

        if (!m_configList.isEmpty()) {
            listTable.addHeaderRow(true, "Configuration Name", "Server");
        }

        for (String configName : m_configList.getConfigNames()) {

            // Config name
            Label configNameLabel = new Label(configName);

            // Server name
            String configServer      = m_configList.getConfigServer(configName);
            Label  configServerLabel = new Label(configServer);

            // "Edit" link
            CommanderUrlBuilder urlBuilder = createPageUrl(getPluginName(),
                    "editConfiguration");

            urlBuilder.setParameter("configName", configName);
            urlBuilder.setParameter("redirectTo", createRedirectUrl().buildString());

            Anchor editConfigLink = new Anchor("Edit",
                    urlBuilder.buildString());

            // "Delete" link
            Anchor             deleteConfigLink = new Anchor("Delete");
            DeleteClickHandler dch              = new DeleteClickHandler(
                    new DeleteConfirmationDialog(configName,
                        "Are you sure you want to delete the Gerrit configuration '"
                        + configName + "'?") {
                        @Override protected void doDelete()
                        {
                            deleteConfiguration(m_objectId);
                        }
                    });

            deleteConfigLink.addClickHandler(dch);

            // Add the row
            Widget actions = constructActionList(editConfigLink,
                    deleteConfigLink);

            listTable.addRow(configNameLabel, configServerLabel, actions);
        }

        clearStatus();
    }

    private void waitForJob(final String jobId)
    {
        CgiRequestProxy     cgiRequestProxy = new CgiRequestProxy(
                getPluginName(), "gerritMonitor.cgi");
        Map<String, String> cgiParams       = new HashMap<String, String>();

        cgiParams.put("jobId", jobId);

        // Pass debug flag to CGI, which will use it to determine whether to
        // clean up a successful job
        if ("1".equals(getGetParameter("debug"))) {
            cgiParams.put("debug", "1");
        }

        try {
            cgiRequestProxy.issueGetRequest(cgiParams, new RequestCallback() {
                    @Override public void onError(Request request,
                            Throwable exception)
                    {
                        addErrorMessage("CGI request failed:: ", exception);
                    }

                    @Override public void onResponseReceived(Request request,
                            Response response)
                    {
                        String responseString = response.getText();

                        if (getLog().isDebugEnabled()) {
                            getLog().debug(
                                "CGI response received: " + responseString);
                        }

                        if (responseString.startsWith("Success")) {

                            // We're done!
                            Location.reload();
                        }
                        else {
                            SimpleErrorBox      error      = new SimpleErrorBox(
                                    "Error occurred during configuration deletion: "
                                    + responseString);
                            CommanderUrlBuilder urlBuilder = CommanderUrlBuilder
                                    .createUrl("jobDetails.php")
                                    .setParameter("jobId", jobId);

                            error.add(
                                new Anchor("(See job for details)",
                                    urlBuilder.buildString()));
                            addErrorMessage(error);
                        }
                    }
                });
        }
        catch (RequestException e) {
            addErrorMessage("CGI request failed:: ", e);
        }
    }
}
