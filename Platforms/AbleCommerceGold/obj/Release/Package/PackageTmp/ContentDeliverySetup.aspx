<%@ Page Language="C#" Title="Install Content Delivery Support for AbleCommerce {0} " %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Xml" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Security.Principal" %>
<%@ Import Namespace="System.Security.AccessControl" %>

<%@ Import Namespace="CommerceBuilder.Utility" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
    private string _AcVersion = "7";
    private const string _ProductVersion = "1.0.1.051214";
    private const string _ProductUrl = "http://cdn.drundo.com/products/drundocdn/ablecommercegold";
    private const string _ManagementUrl = "/admin/store/";
    private const string _ProductFolder1 = "\\bin\\";
    private const string _ProductFolder2 = "\\App_Data\\";
    private const string _ProductFolder3 = "\\Admin\\Store\\";
    private const string _ProductFile1  = "Drundo.HttpModule.dll";
    private const string _ProductFile2  = "DrundoHttpModule.config";
    private const string _ProductFile3  = "ContentDeliverySettings.aspx";
    private const string _DownloadFile1 = "Drundo.HttpModule.dll";
    private const string _DownloadFile3 = "ContentDeliverySettingsAspx.dll";
    private const string _DownloadFile2 = "DrundoHttpModuleConfig.dll";

    /// <summary>
    /// private void HandleError()
    /// </summary>
    /// <param name="errorMessage"></param>
    private void HandleError(string errorMessage)
    {
        MessagePanel.Visible = true;
        ReponseMessage.Text = errorMessage;
    }

    /// <summary>
    /// private string UrlEncode()
    /// </summary>
    /// <param name="key"></param>
    /// <param name="value"></param>
    /// <returns></returns>
    private string UrlEncode(string key, string value)
    {
        return key + "=" + Server.UrlEncode(value);
    }

    /// <summary>
    /// protected void Page_Load()
    /// </summary>
    /// <param name="sender"></param>
    /// <param name="e"></param>
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!Page.IsPostBack)
        {
            string domain = Request.Url.Authority;
            _AcVersion = AbleContext.Current.Version.ToString();
            Page.Title = string.Format(Page.Title, _AcVersion);
            Heading.InnerText = string.Format(Heading.InnerText, _AcVersion);
            MessagePanel.Visible = false;
            AdminPageUrl.Visible = false;
            UninstallButton.Attributes.Add("language", "javascript");
            UninstallButton.Attributes.Add("OnClick", "return confirm('Uninstall Content Delivery Module?');");
        }
    }
    
    /// <summary>
    /// Install module
    /// </summary>
    /// <param name="sender"></param>
    /// <param name="e"></param>
    protected void InstallButton_Click(object sender, EventArgs e)
    {
        MessagePanel.Visible = true;
        WebClient client = new WebClient();
        
        string info = (new System.IO.DirectoryInfo(Server.MapPath("~"))).ToString();
        string approotfolder = info.Substring(0, info.ToString().LastIndexOf("\\") + 1);

        //Download product files
        info = (new System.IO.DirectoryInfo(Server.MapPath(Request.Url.LocalPath))).ToString();
        string currentfolder = info.Substring(0, info.ToString().LastIndexOf("\\") + 1);
        client.DownloadFile(_ProductUrl + _ProductVersion + "/" + _DownloadFile1, currentfolder + _ProductFile1);
        client.DownloadFile(_ProductUrl + _ProductVersion + "/" + _DownloadFile2, currentfolder + _ProductFile2);
        client.DownloadFile(_ProductUrl + _ProductVersion + "/" + _DownloadFile3, currentfolder + _ProductFile3);

        //Deploy Files
        System.IO.File.Copy(currentfolder + _ProductFile1, approotfolder + _ProductFolder1 + _ProductFile1, true);
        System.IO.File.Copy(currentfolder + _ProductFile2, approotfolder + _ProductFolder2 + _ProductFile2, true);
        System.IO.File.Copy(currentfolder + _ProductFile3, approotfolder + _ProductFolder3 + _ProductFile3, true);

        //Deploy Files
        System.IO.File.Delete(currentfolder + _ProductFile1);
        System.IO.File.Delete(currentfolder + _ProductFile2);
        System.IO.File.Delete(currentfolder + _ProductFile3);

        //Update configuration sections
        UpdateWebConfig(true);
        
        //Update admin menu
        UpdateSiteAdminMenu(true);
        UpdateSiteAdminBreadcrumbsMenu(true);

        System.Threading.Thread.Sleep(2000);
        string managementUrl = _ManagementUrl + _ProductFile3;
        StatusMessage.Text = "Content Delivery Module installation completed successfully. Site CDN configuration settings are now available directly from within AbleCommerce Site Administration at:";
        AdminPageUrl.NavigateUrl = managementUrl;
        AdminPageUrl.Text = "Administration > Configure > Content Delivery";
        AdminPageUrl.Visible = true;
    }

    /// <summary>
    /// Uninstall module
    /// </summary>
    /// <param name="sender"></param>
    /// <param name="e"></param>
    protected void UninstallButton_Click(object sender, EventArgs e)
    {
        string info = (new System.IO.DirectoryInfo(Server.MapPath("~"))).ToString();
        string approotfolder = info.Substring(0, info.ToString().LastIndexOf("\\") + 1);

        UpdateWebConfig(false);

        //Update admin menu
        UpdateSiteAdminMenu(false);
        UpdateSiteAdminBreadcrumbsMenu(false);

        //Delete Files
        System.IO.File.Delete(approotfolder + _ProductFolder1 + _ProductFile1);
        System.IO.File.Delete(approotfolder + _ProductFolder2 + _ProductFile2);
        System.IO.File.Delete(approotfolder + _ProductFolder3 + _ProductFile3);
        
        System.Threading.Thread.Sleep(2000);
        MessagePanel.Visible = true;
        StatusMessage.Text = "Content Delivery Module has been successfully uninstalled ...";
    }

    /// <summary>
    /// Update site web config with required module sections
    /// </summary>
    /// <param name="deleteSections"></param>
    private void UpdateWebConfig(bool configure)
    {
        string info = (new System.IO.DirectoryInfo(Server.MapPath("~"))).ToString();
        string approotfolder = info.Substring(0, info.ToString().LastIndexOf("\\") + 1);
        bool isConfigured = false;

        XmlDocument config = new XmlDocument();
        config.Load(approotfolder + "web.config");

        XmlNode moduleconfig = config.SelectSingleNode("//configuration//configSections");

        foreach (XmlNode node in moduleconfig.ChildNodes)
        {
            if (node.Attributes != null && node.Attributes["name"].Value == "DrundoHttpModuleConfig")
                isConfigured = true;
        }

        //Insert required module sections
        if (!isConfigured && configure)
        {
            //<section name ="DrundoHttpModuleConfig" type ="Drundo.HttpModule.Configuration.XmlSerializerSectionHandler, Drundo.HttpModule" restartOnExternalChanges="false" requirePermission="false"/>
            XmlNode configsection = config.CreateElement("section");

            XmlAttribute attrname = config.CreateAttribute("name");
            attrname.Value = "DrundoHttpModuleConfig";

            XmlAttribute attrtype = config.CreateAttribute("type");
            attrtype.Value = "Drundo.HttpModule.Configuration.XmlSerializerSectionHandler, Drundo.HttpModule";

            XmlAttribute attrestart = config.CreateAttribute("restartOnExternalChanges");
            attrestart.Value = "true";

            XmlAttribute attrpermission = config.CreateAttribute("requirePermission");
            attrpermission.Value = "false";

            configsection.Attributes.Append(attrname);
            configsection.Attributes.Append(attrtype);
            configsection.Attributes.Append(attrestart);
            configsection.Attributes.Append(attrpermission);

            moduleconfig.AppendChild(configsection);

            //<DrundoHttpModuleConfig configSource="App_Data\DrundoHttpModule.config"/>
            XmlNode configFile = config.CreateElement("DrundoHttpModuleConfig");

            XmlAttribute attrsource = config.CreateAttribute("configSource");
            attrsource.Value = "App_Data\\DrundoHttpModule.config";
            configFile.Attributes.Append(attrsource);

            XmlNode rootConfig = config.SelectSingleNode("//configuration");
            moduleconfig.ParentNode.InsertAfter(configFile, moduleconfig);

            //<add name="ContentDelivery" type="Drundo.HttpModule.ContentDelivery, Drundo.HttpModule" preCondition="managedHandler"/>
            XmlNode webserverModuleconfig = config.SelectSingleNode("//configuration//system.webServer//modules");
            XmlNode webserverModuleconfigsection = config.CreateElement("add");

            XmlAttribute webserverModuleconfigattrname = config.CreateAttribute("name");
            webserverModuleconfigattrname.Value = "ContentDelivery";
            XmlAttribute webserverModuleconfigattrtype = config.CreateAttribute("type");
            webserverModuleconfigattrtype.Value = "Drundo.HttpModule.ContentDelivery, Drundo.HttpModule";
            XmlAttribute webserverModuleconfigattrcond = config.CreateAttribute("preCondition");
            webserverModuleconfigattrcond.Value = "managedHandler";

            webserverModuleconfigsection.Attributes.Append(webserverModuleconfigattrname);
            webserverModuleconfigsection.Attributes.Append(webserverModuleconfigattrtype);
            webserverModuleconfigsection.Attributes.Append(webserverModuleconfigattrcond);
            webserverModuleconfig.AppendChild(webserverModuleconfigsection);

            //<add name="ContentDelivery" type="Drundo.HttpModule.ContentDelivery, Drundo.HttpModule" preCondition="managedHandler"/>
            XmlNode httpModulesConfig = config.SelectSingleNode("//configuration//system.web//httpModules");
            XmlNode httpModulesConfigSection = config.CreateElement("add");
            XmlAttribute httpModulesConfigattrname = config.CreateAttribute("name");
            httpModulesConfigattrname.Value = "ContentDelivery";
            XmlAttribute httpModulesConfigattrtype = config.CreateAttribute("type");
            httpModulesConfigattrtype.Value = "Drundo.HttpModule.ContentDelivery, Drundo.HttpModule";

            httpModulesConfigSection.Attributes.Append(httpModulesConfigattrname);
            httpModulesConfigSection.Attributes.Append(httpModulesConfigattrtype);
            httpModulesConfig.AppendChild(httpModulesConfigSection);

            //Save configuration
            config.Save(approotfolder + "web.config");
        }

        //Delete all module sections from web.config
        if (isConfigured && !configure)
        {
            XmlNode httpModuleNode = config.SelectSingleNode("//configuration//configSections//section[@name = 'DrundoHttpModuleConfig']");
            httpModuleNode.ParentNode.RemoveChild(httpModuleNode);

            httpModuleNode = config.SelectSingleNode("//configuration//DrundoHttpModuleConfig");
            httpModuleNode.ParentNode.RemoveChild(httpModuleNode);

            httpModuleNode = config.SelectSingleNode("//configuration//system.web//httpModules//add[@name = 'ContentDelivery']");
            httpModuleNode.ParentNode.RemoveChild(httpModuleNode);
            
            httpModuleNode = config.SelectSingleNode("//configuration//system.webServer//modules//add[@name = 'ContentDelivery']");
            httpModuleNode.ParentNode.RemoveChild(httpModuleNode);
            
            //Save configuration
            config.Save(approotfolder + "web.config");
        }
    }
    
    /// <summary>
    /// Update Site Admin Menu Store section
    /// </summary>
    /// <param name="configure"></param>
    private void UpdateSiteAdminMenu(bool configure)
    {
        string info = (new System.IO.DirectoryInfo(Server.MapPath("~"))).ToString();
        string appRootFolder = info.Substring(0, info.ToString().LastIndexOf("\\") + 1);
        bool isConfigured = false;

        XmlDocument sitemap = new XmlDocument();
        sitemap.Load(appRootFolder + "App_Data\\adminmenu.xml");
        XmlNamespaceManager manager = new XmlNamespaceManager(sitemap.NameTable);
        manager.AddNamespace("s", sitemap.DocumentElement.Name);
        //XmlNode menuConfig = sitemap.SelectSingleNode("//s:menuItem[@title = 'Configure']", manager);
        XmlNode menuConfig = sitemap.SelectSingleNode("/menu//menuItem[@title = 'Configure']");
        

        //XmlNode menuConfig = sitemap.SelectSingleNode("/menuItem//menuItem[@title = 'Configure']");
        //XmlNode targetNode = rootNode.SelectSingleNode("/breadCrumb//breadCrumb[@url='" + pageUrl + "']");

        foreach (XmlNode node in menuConfig.ChildNodes)
        {
            if (node.Attributes != null && node.Attributes["title"] != null && node.Attributes["title"].Value == "Content Delivery")
                isConfigured = true;
        }

        //Add menu menu.sitemap section
        if (!isConfigured && configure)
        {
            XmlNode menuSection = sitemap.CreateElement("menuItem");

            XmlAttribute attrName = sitemap.CreateAttribute("title");
            attrName.Value = "Content Delivery";

            XmlAttribute attrUrl = sitemap.CreateAttribute("url");
            attrUrl.Value = "~/Admin/Store/ContentDeliverySettings.aspx";
            
            XmlAttribute attrRoles = sitemap.CreateAttribute("roles");
            attrRoles.Value = "System,Admin,Jr. Admin";
            
            XmlAttribute attrDescr = sitemap.CreateAttribute("description");
            attrDescr.Value = "The CDN Menu allows you to control and manage AbleCommerce Content Delivery Settings.";
            
            menuSection.Attributes.Append(attrName);
            menuSection.Attributes.Append(attrUrl);
            menuSection.Attributes.Append(attrRoles);
            menuSection.Attributes.Append(attrDescr);
            menuConfig.AppendChild(menuSection);

            sitemap.Save(appRootFolder + "App_Data\\adminmenu.xml");
        }

        //Remove menu section
        if (isConfigured && !configure)
        {
            foreach (XmlNode node in menuConfig.ChildNodes)
            {
                if (node.Attributes != null && node.Attributes["title"] != null && node.Attributes["title"].Value == "Content Delivery")
                {
                    menuConfig.RemoveChild(node);
                    sitemap.Save(appRootFolder + "App_Data\\adminmenu.xml");
                }
            }
        }
    }

    /// <summary>
    /// Update Site Breadcrumbs Sitemap
    /// </summary>
    /// <param name="configure"></param>
    private void UpdateSiteAdminBreadcrumbsMenu(bool configure)
    {
        string info = (new System.IO.DirectoryInfo(Server.MapPath("~"))).ToString();
        string appRootFolder = info.Substring(0, info.ToString().LastIndexOf("\\") + 1);
        bool isConfigured = false;

        XmlDocument sitemap = new XmlDocument();
        sitemap.Load(appRootFolder + "App_Data\\adminbreadcrumb.xml");
        XmlNamespaceManager manager = new XmlNamespaceManager(sitemap.NameTable);
        manager.AddNamespace("s", sitemap.DocumentElement.Name);
        //XmlNode menuConfig = sitemap.SelectSingleNode("//s:breadCrumb[@title = 'Configure']", manager);
        XmlNode menuConfig = sitemap.SelectSingleNode("/breadCrumb//breadCrumb[@title = 'Configure']", manager);

        foreach (XmlNode node in menuConfig.ChildNodes)
        {
            if (node.Attributes != null && node.Attributes["title"] != null && node.Attributes["title"].Value == "Content Delivery")
                isConfigured = true;
        }

        //Add menu menu.sitemap section
        if (!isConfigured && configure)
        {
            XmlNode menuSection = sitemap.CreateElement("breadCrumb");
            XmlAttribute attrName = sitemap.CreateAttribute("title");
            attrName.Value = "Content Delivery";

            XmlAttribute attrUrl = sitemap.CreateAttribute("url");
            attrUrl.Value = "~/Admin/Store/ContentDeliverySettings.aspx";

            menuSection.Attributes.Append(attrName);
            menuSection.Attributes.Append(attrUrl);
            menuConfig.AppendChild(menuSection);
            sitemap.Save(appRootFolder + "App_Data\\adminbreadcrumb.xml");
        }

        //Remove menu section
        if (isConfigured && !configure)
        {
            foreach (XmlNode node in menuConfig.ChildNodes)
            {
                if (node.Attributes != null && node.Attributes["title"] != null && node.Attributes["title"].Value == "Content Delivery")
                {
                    menuConfig.RemoveChild(node);
                    sitemap.Save(appRootFolder + "App_Data\\adminbreadcrumb.xml");
                }
            }
        }
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml" >
<head id="Head" runat="server">
    <style type="text/css">
        p { font-size: 12px; }
        .sectionHeader { background-color: #EFEFEF; padding:3px; margin:12px 0px; }
        h2 { font-size: 14px; font-weight: bold; margin: 0px; }
        .error { font-weight:bold; color:red; }
        div.radio { margin:2px 0px 6px 0px; }
        div.radio label { font-weight:bold; padding-top: 6px; position:relative; top:1px; }
        .inputBox { padding:6px;margin: 4px 40px;border:solid 1px #CCCCCC; }
        div.install   {  padding:4px; margin:12px 0px 10px 0px; text-align:center; }
        div.uninstall { padding:4px; margin:12px 0px; text-align:center; }
    </style>
    <script type="text/javascript" language="JavaScript">
        var counter = 0;
        function plswt() {
            counter++;
            if (counter > 1) {
                alert("You have already submitted this form.  Please wait while the install processes.");
                return false;
            }
            return true;
        }
    </script>
</head>

<body style="width:780px;margin:auto">
    <form id="form1" runat="server">
        <br />
        <div class="pageHeader">
            <h1 style="font-size:16px" runat="server" id="Heading">Install Content Delivery For AbleCommerce {0} </h1>
        </div>
        <div style="padding-left:10px;padding-right:10px">
            <asp:ValidationSummary ID="ValidationSummary1" runat="server" />
            <asp:ScriptManager ID="ScriptManager" runat="server" EnablePartialRendering="true"></asp:ScriptManager>
            <asp:UpdatePanel ID="InstallAjax" runat="server">
                <Triggers>
                    <asp:PostBackTrigger ControlID="InstallButton" />
                    <asp:PostBackTrigger ControlID="UninstallButton" />
                </Triggers>
                <ContentTemplate>
                    <br />
                    <div class="inputBox">
                        <div class="install">
                            <asp:Button ID="InstallButton" runat="server" Text="Install CDN Module" OnClick="InstallButton_Click" OnClientClick="if(Page_ClientValidate('')){this.value='Processing...';return plswt();}" Width="250px" Height="30px" />
                        </div>
                        <div class="uninstall">
                            <asp:Button ID="UninstallButton" runat="server" Text="Uninstall CDN Module" OnClick="UninstallButton_Click" Enabled="true" Width="250px" Height="30px" />
                        </div>
                    </div>

                    <asp:Panel ID="MessagePanel" runat="server" Visible="false">
                        <div class="inputBox">
                            <p><asp:Literal ID="StatusMessage" runat="server"></asp:Literal></p>
                            <br />
                            <p><asp:HyperLink ID="AdminPageUrl" runat="server" Visible="false" Font-Bold="true" Font-Underline="true"></asp:HyperLink></p>
                            <br />
                            <div class="error">
                                <p><asp:Literal ID="ReponseMessage" runat="server"></asp:Literal></p>
                            </div>
                        </div>
                    </asp:Panel>
                </ContentTemplate>
            </asp:UpdatePanel>
        </div>
    </form>
</body>
</html>