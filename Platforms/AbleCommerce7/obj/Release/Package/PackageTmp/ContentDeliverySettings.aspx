<%@ Page Language="C#" MasterPageFile="~/Admin/Admin.master"  Title="Configure Site Content Delivery Settings"  EnableViewState="false" ClassName="Admin_Store_ContentDeliverySettings" Inherits="CommerceBuilder.Web.UI.AbleCommerceAdminPage" %>
<%@ Register Assembly="CommerceBuilder.Web" Namespace="CommerceBuilder.Web.UI.WebControls" TagPrefix="cb" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Xml" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Security.Principal" %>
<%@ Import Namespace="System.Security.AccessControl" %>
<%@ Import Namespace="CommerceBuilder.Common" %>
<%@ Import Namespace="CommerceBuilder.Data" %>
<%@ Import Namespace="CommerceBuilder.Utility" %>
<%@ Import Namespace="Drundo.HttpModule.Configuration" %>

<script runat="server">

    protected void Page_Load(object sender, System.EventArgs e)
    {
        if (!Page.IsPostBack)
        {
            if (String.IsNullOrEmpty(_CDNUrlTextBox.Text))
            {
                _MessagePanel.Visible = false;
            }
            
            string configFilepath = GetConfigFilePath();
            DrundoHttpModuleConfig config = DrundoHttpModuleConfig.Deserialize(configFilepath);

            _CDNUrlTextBox.Text = config.CdnUrlName;
            _EnableCDNCheckbox.Checked = config.IsEnabled;
            _EnableCSSCheckBox.Checked = config.IsScriptEnabled;
            _EnableSSLSupportCheckBox.Checked = config.IsSecure;
        }
    }

    /// <summary>
    /// Save CDN configuration settings
    /// </summary>
    private void SaveSettings()
    {
        string configFilePath = GetConfigFilePath();

        DrundoHttpModuleConfig config = DrundoHttpModuleConfig.Deserialize(configFilePath);
        config.CdnUrlName = _CDNUrlTextBox.Text;
        config.IsSecure = _EnableSSLSupportCheckBox.Checked;
        config.IsEnabled = _EnableCDNCheckbox.Checked;
        config.IsScriptEnabled = _EnableCSSCheckBox.Checked;

        DrundoHttpModuleConfig.Serialize(configFilePath, config);
    }

    /// <summary>
    /// Save configuration settings
    /// </summary>
    /// <param name="sender"></param>
    /// <param name="e"></param>
    protected void SaveButton_Click(object sender, EventArgs e)
    {
        SaveSettings();

        _SavedMessage.Text = String.Format("Content Delivery Settings Saved at {0:t}<br /><br />", DateTime.Now);
        _SavedMessage.Visible = true;
    }

    /// <summary>
    /// Displays test url on cdn url update
    /// </summary>
    /// <param name="sender"></param>
    /// <param name="e"></param>
    protected void CDNUrlTextBox_OnTextChanged(object sender, EventArgs e)
    {
        string urlPrefix = "http://";
    
        if (_EnableSSLSupportCheckBox.Checked)
            urlPrefix = "https://";

        string testUrl = String.Format("{0}{1}/app_themes/ablecommerceadmin/images/logo.gif", urlPrefix, _CDNUrlTextBox.Text);
        _MessagePanel.Visible = true;
        _TestCDNUrlHyperLink.Text = testUrl;
        _TestCDNUrlHyperLink.NavigateUrl = testUrl;
    }

    /// <summary>
    /// Returns module configuration file path
    /// </summary>
    /// <returns></returns>
    private string GetConfigFilePath()
    {
        const string configFolder = "\\App_Data\\DrundoHttpModule.config";
        string info = (new System.IO.DirectoryInfo(Server.MapPath("~"))).ToString();
        string appRootFolder = info.Substring(0, info.ToString().LastIndexOf("\\") + 1);
        string configFilePath = appRootFolder + configFolder;

        return configFilePath;
    }
</script>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" Runat="Server">
    <div class="pageHeader">
    	<div class="caption">
    		<h1><asp:Localize ID="Caption" runat="server" Text="Configure Site Content Delivery Settings"></asp:Localize></h1>
    	</div>
    </div>
    <table cellpadding="2" cellspacing="0" class="innerLayout">
		<tr>
		    <td>
                <ajax:UpdatePanel ID="PageAjax" runat="server" UpdateMode="Always">
                    <ContentTemplate>
		                <table class="inputForm">
                            <tr>
                                <th class="rowHeader" style="vertical-align:top;">
                                    <cb:ToolTipLabel ID="EnabledLabel" runat="server" 
                                        Text="Enable CDN:" AssociatedControlID="_EnableCDNCheckbox" 
                                        ToolTip="Indicates whether the content delivery network feature is enabled for the store."
                                    />
                                </th>
                                <td>
                                    <asp:CheckBox ID="_EnableCDNCheckbox" runat="server" Checked="false" />
                                </td>
                            </tr>
                            <tr>
                                <th class="rowHeader">
                                    <cb:ToolTipLabel ID="CDNUrlLabel" runat="server" AssociatedControlID="_CdnUrlTextBox"
                                        Text="Content Delivery Url:" 
                                        ToolTip="Enter Content Delivery Url provided by your CDN provider." 
                                    />
                                </th>
                                <td>
                                    <asp:TextBox ID="_CDNUrlTextBox" runat="server"  Width="320px" AutoPostBack="True" ClientIDMode="Inherit" OnTextChanged="CDNUrlTextBox_OnTextChanged" ></asp:TextBox>
                                    <span style="font-style:italic; margin-left: 10px;">Example: dwerojsngq223w.cloudfront.net </span> 
                                </td>
                                <td>
                                    <asp:RequiredFieldValidator id="RequiredFieldValidator" ControlToValidate="_CDNUrlTextBox" ErrorMessage="Content Delivery Url is a requried field." Display="Static" Width="100%" runat="server">*</asp:RequiredFieldValidator>
                                </td>
                            </tr>
                            <tr>
                                <th class="rowHeader">
                                    <cb:ToolTipLabel ID="EnableSSLSupportLabel" runat="server" AssociatedControlID="_EnableSSLSupportCheckBox"
                                        Text="Enable Https Support" 
                                        ToolTip="Indicates whether a secure socket layer (SSL) is available with your CDN provider. Check this box if your CDN provider supports https requests." 
                                    />
                                </th>
                                <td>
                                    <asp:CheckBox ID="_EnableSSLSupportCheckBox" runat="server" Checked="false" />
                                </td>
                            </tr>
                            <tr>
                                <th class="rowHeader">
                                    <cb:ToolTipLabel ID="EnableCSSLabel" runat="server"  AssociatedControlID="_EnableCSSCheckBox" 
                                        Text="Enable CDN for .CSS and JavaScript files"
                                        ToolTip="If checked all site .css and external JavaScript files will be delivered trough CDN. Enable this option only if your CDN provider supports https connections."
                                    />
                                </th>
                                <td>
                                    <asp:CheckBox ID="_EnableCSSCheckBox" runat="server" Checked="false" />
                                </td>
                            </tr>
                            <asp:Panel ID="_MessagePanel" runat="server" Visible="false">
                                <tr>
                                    <td colspan="2">
                                        <p style=" margin-left: 40px; margin-right: 20px;">
                                            <span style="color: Red; font-weight: bold;"> WARNING:</span>
                                            <span style="margin-left: 2px;">Test some static urls e.g., <asp:HyperLink ID="_TestCDNUrlHyperLink" runat="server" Target="_blank" Enabled="true" Visible="true" ViewStateMode="Enabled" NavigateUrl=""></asp:HyperLink> to ensure your CDN service is working before enabling CDN.</span>
                                        </p>
                                    </td>
                                </tr>
                            </asp:Panel>
                            <tr>
                                <td align="center" colspan="2">
                                    <br />
                                    <asp:ValidationSummary ID="_ValidationSummary" runat="server" DisplayMode="SingleParagraph" ShowMessageBox="false" />
                                    <asp:Label ID="_SavedMessage" runat="server" SkinID="GoodCondition" EnableViewState="False" Visible="false"></asp:Label>
                                    <asp:Button Id="_SaveCDNSettingsButon" runat="server" Text="Save Settings" OnClick="SaveButton_Click" CssClass="button" />
                                </td>
                            </tr>
		                </table>
		            </ContentTemplate>
		        </ajax:UpdatePanel>
		    </td>
		</tr>
    </table>
</asp:Content>
