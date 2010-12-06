
// ConfigurationManagementFactory.java --
//
// ConfigurationManagementFactory.java is part of ElectricCommander.
//
// Copyright (c) 2005-2010 Electric Cloud, Inc.
// All rights reserved.
//

package ecplugins.gerrit.client;

import com.google.gwt.core.client.EntryPoint;
import com.google.gwt.core.client.JavaScriptObject;

import com.electriccloud.commander.gwt.client.BrowserContext;
import com.electriccloud.commander.gwt.client.Component;
import com.electriccloud.commander.gwt.client.ComponentBaseFactory;
import com.electriccloud.commander.gwt.client.FormBase;
import com.electriccloud.commander.gwt.client.PropertySheetEditor;

import static com.electriccloud.commander.gwt.client.util.CommanderUrlBuilder.createPageUrl;

public class ConfigurationManagementFactory
    extends ComponentBaseFactory
    implements EntryPoint
{

    //~ Methods ----------------------------------------------------------------

    @Override public Component getComponent(JavaScriptObject jso)
    {
        String    panel     = getParameter(jso, "panel");
        Component component;

        if ("create".equals(panel)) {
            component = new CreateConfiguration();
        }
        else if ("edit".equals(panel)) {
            String configName    = BrowserContext.getInstance()
                                                 .getGetParameter("configName");
            String propSheetPath = "/plugins/" + getPluginName()
                    + "/project/gerrit_cfgs/" + configName;
            String formXmlPath   = "/plugins/" + getPluginName()
                    + "/project/ui_forms/GerritEditConfigForm";

            component = new PropertySheetEditor("ecgc",
                    "Edit Gerrit Configuration", configName, propSheetPath,
                    formXmlPath, getPluginName());

            ((FormBase) component).setDefaultRedirectToUrl(createPageUrl(
                    getPluginName(), "configurations").buildString());
        }
        else {

            // Default panel is "list"
            component = new ConfigurationList();
        }

        return component;
    }
}
