using System;
using System.Collections.Generic;
using System.Web;
using System.Configuration;
using Drundo.HttpModule.Configuration;

namespace Drundo.HttpModule
{
   public class ContentDelivery : IHttpModule
   {
      /// <summary>
      /// CTOR
      /// </summary>
      public ContentDelivery() { }

      /// <summary>
      /// DTOR
      /// </summary>
      void IHttpModule.Dispose() { }

      /// <summary>
      /// IHttpModule interface Init
      /// </summary>
      /// <param name="context"></param>
      void IHttpModule.Init(HttpApplication context)
      {
         context.BeginRequest += new EventHandler(Application_BeginRequest);
         context.PreRequestHandlerExecute += new EventHandler(Application_PreRequestHandlerExecute);
         context.EndRequest += new EventHandler(Application_EndRequest);
         context.AuthorizeRequest += new EventHandler(Application_AuthorizeRequest);
      }

      /// <summary>
      /// This event is used internally to implement authorization mechanisms 
      /// (for example, to store your access control lists (ACLs) in a database rather than in the file system). 
      /// Although you can override this event, there are not many good reasons to do so.
      /// </summary>
      /// <param name="sender"></param>
      /// <param name="e"></param>
      private void Application_AuthorizeRequest(object sender, EventArgs e) { }

      /// <summary>
      /// This event occurs before the HTTP handler is executed.
      /// </summary>
      /// <param name="sender"></param>
      /// <param name="e"></param>
      private void Application_PreRequestHandlerExecute(object sender, EventArgs e) { }

      /// <summary>
      /// Request has been completed. You may want to build a debugging module that gathers information 
      /// throughout the request and then writes the information to the page.
      /// </summary>
      /// <param name="sender"></param>
      /// <param name="e"></param>
      private void Application_EndRequest(object sender, EventArgs e) { }

      /// <summary>
      /// Request has been started. If you need to do something at the beginning of a request 
      /// (for example, display advertisement banners at the top of each page), synchronize this event.
      /// </summary>
      /// <param name="sender"></param>
      /// <param name="e"></param>
      private void Application_BeginRequest(object sender, EventArgs e)
      {
         HttpContext context = ((HttpApplication)sender).Context;

         string fileExtension = VirtualPathUtility.GetExtension(context.Request.FilePath);

         DrundoHttpModuleConfig config = (DrundoHttpModuleConfig)ConfigurationManager.GetSection("DrundoHttpModuleConfig");

         if (null != config)
         {
            //AbleCommerce 7
            if(config.PlatformName.Equals("AbleCommerce"))
            {
               if (fileExtension.Equals(".aspx"))
               {
                  context.Response.Filter = new AbleCommerceWebResourceFilter(context.Response.Filter);
               }
            }

            //nopCommerce
            if(config.PlatformName.Equals("nopCommerce"))
            {
               context.Response.Filter = new nopCommerceWebResourceFilter(context.Response.Filter);
            }

            //Sitefinity
            if (config.PlatformName.Equals("Sitefinity"))
            {
               context.Response.Filter = new SitefinityWebResourceFilter(context.Response.Filter); 
            }
         }
      }
   }
}