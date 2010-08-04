
// CreateConfiguration.java --
//
// CreateConfiguration.java is part of ElectricCommander.
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
import com.google.gwt.user.client.ui.Anchor;
import com.google.gwt.xml.client.Node;

import com.electriccloud.commander.gwt.client.FormBase;
import com.electriccloud.commander.gwt.client.FormBuilderLoader;
import com.electriccloud.commander.gwt.client.legacyrequests.CommanderRequestCallback;
import com.electriccloud.commander.gwt.client.legacyrequests.RunProcedureRequest;
import com.electriccloud.commander.gwt.client.requests.CgiRequestProxy;
import com.electriccloud.commander.gwt.client.responses.CommanderError;
import com.electriccloud.commander.gwt.client.ui.FormBuilder;
import com.electriccloud.commander.gwt.client.ui.FormTable;
import com.electriccloud.commander.gwt.client.ui.SimpleErrorBox;
import com.electriccloud.commander.gwt.client.util.CommanderUrlBuilder;

import static com.electriccloud.commander.gwt.client.util.CommanderUrlBuilder.createPageUrl;
import static com.electriccloud.commander.gwt.client.util.CommanderUrlBuilder.createUrl;

import static com.electriccloud.commander.gwt.client.ComponentBaseFactory.getPluginName;

/**
 * Create Gerrit Configuration.
 */
public class CreateConfiguration
    extends FormBase
{

    //~ Constructors -----------------------------------------------------------

    public CreateConfiguration()
    {
        super("New Gerrit Configuration", "Gerrit Configurations");

        CommanderUrlBuilder urlBuilder = createPageUrl(getPluginName(),
                "configurations");

        setDefaultRedirectToUrl(urlBuilder.buildString());
    }

    //~ Methods ----------------------------------------------------------------

    @Override protected FormTable initializeFormTable()
    {
        FormBuilder fb = new FormBuilder();

        return fb;
    }

    @Override protected void load()
    {
        FormBuilder fb = (FormBuilder) getFormTable();

        setStatus("Loading...");

        FormBuilderLoader loader = new FormBuilderLoader(fb, this);

        loader.setCustomEditorPath("/plugins/EC-Gerrit"
            + "/project/ui_forms/GerritCreateConfigForm");
        loader.load();
        clearStatus();
    }

    @Override protected void submit()
    {
        setStatus("Saving...");
        clearAllErrors();

        FormBuilder fb = (FormBuilder) getFormTable();

        if (!fb.validate()) {
            clearStatus();

            return;
        }

        // Build runProcedure request
        RunProcedureRequest request = new RunProcedureRequest(
                "/plugins/EC-Gerrit/project", "CreateConfiguration");
        Map<String, String> params  = fb.getValues();

        for (String paramName : params.keySet()) {
            request.addActualParameter(paramName, params.get(paramName));
        }

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

                    waitForJob(getNodeValueByName(responseNode, "jobId"));
                }
            });

        if (getLog().isDebugEnabled()) {
            getLog().debug("Issuing Commander request: " + request);
        }

        doRequest(request);
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
                    @Override public void onError(
                            Request   request,
                            Throwable exception)
                    {
                        addErrorMessage("CGI request failed: ", exception);
                    }

                    @Override public void onResponseReceived(
                            Request  request,
                            Response response)
                    {
                        String responseString = response.getText();

                        if (getLog().isDebugEnabled()) {
                            getLog().debug(
                                "CGI response received: " + responseString);
                        }

                        if (responseString.startsWith("Success")) {

                            // We're done!
                            cancel();
                        }
                        else {
                            SimpleErrorBox      error      = new SimpleErrorBox(
                                    "Error occurred during configuration creation: "
                                    + responseString);
                            CommanderUrlBuilder urlBuilder = createUrl(
                                    "jobDetails.php")
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
            addErrorMessage("CGI request failed: ", e);
        }
    }
}
