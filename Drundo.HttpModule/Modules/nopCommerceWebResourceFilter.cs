using System;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI;
using System.Web.Caching;
using System.Configuration;
using Drundo.HttpModule.Configuration;

namespace Drundo.HttpModule
{
   public class nopCommerceWebResourceFilter : Stream
   {
      #region Generic Overrides
      private readonly Stream sink;

      public nopCommerceWebResourceFilter(Stream sink)
      {
         this.sink = sink;
      }

      public override bool CanRead
      {
         get
         {
            return true;
         }
      }

      public override bool CanSeek
      {
         get
         {
            return true;
         }
      }

      public override bool CanWrite
      {
         get
         {
            return true;
         }
      }

      public override long Length
      {
         get
         {
            return 0;
         }
      }

      public override long Position { get; set; }

      public override void Close()
      {
         this.sink.Close();
      }

      public override void Flush()
      {
         this.sink.Flush();
      }

      public override int Read(byte[] buffer, int offset, int count)
      {
         return this.sink.Read(buffer, offset, count);
      }

      public override long Seek(long offset, SeekOrigin origin)
      {
         return this.sink.Seek(offset, origin);
      }

      public override void SetLength(long value)
      {
         this.sink.SetLength(value);
      }
      #endregion

      /// <summary>
      /// Stream Writer Override
      /// </summary>
      /// <param name="buffer"></param>
      /// <param name="offset"></param>
      /// <param name="count"></param>
      public override void Write(byte[] buffer, int offset, int count)
      {
         var html = Encoding.UTF8.GetString(buffer, offset, count);
         DrundoHttpModuleConfig config = (DrundoHttpModuleConfig)ConfigurationManager.GetSection("DrundoHttpModuleConfig");
         bool IsUseCdnOk = true;

         if ((null != config) && !String.IsNullOrEmpty(config.CdnUrlName) && config.IsEnabled)
         {
            //Do not use CDN if the current url is https and cdn does not support https
            if (HttpContext.Current.Request.IsSecureConnection && !config.IsSecure)
            {
               IsUseCdnOk = false;
            }

            //Skip CDN for Ajax requests
            if (HttpContext.Current.Request.Headers["x-microsoftajax"] != null)
            {
               IsUseCdnOk = false;
            }
            
            if (IsUseCdnOk && config.IsEnabled)
            {
               //Process Image urls
               html = ProcessImageUrls(html);

               //Enable CDN for .CSS and JavaScript files
               if (config.IsScriptEnabled)
               {
                  //Process style links
                  html = ProcessStyleLinks(html);

                  //Process script links
                  html = ProcessScriptLinks(html);
               }
            }
         }

         var outdata = Encoding.UTF8.GetBytes(html);
         this.sink.Write(outdata, 0, outdata.GetLength(0));
      }
      
      /// <summary>
      /// Replaces all javascript links with CDN url
      /// </summary>
      /// <param name="html"></param>
      /// <returns></returns>
      private string ProcessScriptLinks(string html)
      {
         DrundoHttpModuleConfig config = (DrundoHttpModuleConfig)ConfigurationManager.GetSection("DrundoHttpModuleConfig");

         string cdnUrl = config.CdnUrlName;
         string urlPrefix = "http://";

         //Set url prefix to https if cdn supports ssl and current url is https
         if (HttpContext.Current.Request.IsSecureConnection && config.IsSecure)
         {
            urlPrefix = "https://";
         }

         Regex scriptregex = new Regex(config.ScriptRegex, RegexOptions.Compiled);
         string url = string.Format("{0}{1}{2}/", config.ScriptRegexElement, urlPrefix, cdnUrl);

         html = scriptregex.Replace(html, delegate(Match match)
         {
            return match.Value.Replace(config.ScriptRegexElement, url);
         });

         return html;
      }

      /// <summary>
      /// Replaces all css style links with CDN url from config
      /// </summary>
      /// <param name="html"></param>
      /// <returns></returns>
      private string ProcessStyleLinks(string html)
      {
         DrundoHttpModuleConfig config = (DrundoHttpModuleConfig)ConfigurationManager.GetSection("DrundoHttpModuleConfig");

         string cdnUrl = config.CdnUrlName;
         string urlPrefix = "http://";

         //Set url prefix to https if cdn supports ssl and current url is https
         if (HttpContext.Current.Request.IsSecureConnection && config.IsSecure)
         {
            urlPrefix = "https://";
         }

         Regex styleregex = new Regex(config.StyleRegex, RegexOptions.Compiled);
         string url = string.Format("{0}{1}{2}", config.StyleRegexElement, urlPrefix, cdnUrl);

         html = styleregex.Replace(html, delegate(Match match)
         {
            return match.Value.Replace(config.StyleRegexElement, url);
         });

         return html;
      }

      /// <summary>
      /// Replaces all image urls with CDN url from config 
      /// </summary>
      /// <param name="html"></param>
      /// <returns></returns>
      private string ProcessImageUrls(string html)
      {
         DrundoHttpModuleConfig config = (DrundoHttpModuleConfig)ConfigurationManager.GetSection("DrundoHttpModuleConfig");

         string cdnUrl = config.CdnUrlName;
         string urlPrefix = "http://";

         //Set url prefix to https if cdn supports ssl and current url is https
         if (HttpContext.Current.Request.IsSecureConnection && config.IsSecure)
         {
            urlPrefix = "https://";
         }
         
         //Remove all http://domain.com strings
         string urlRegex = String.Format("<img.+src=.http://{0}([^\"]+)\"[^>]+ />", HttpContext.Current.Request.Url.Host);
         string urlMatch = String.Format("http://{0}", HttpContext.Current.Request.Url.Host);
         Regex cleanupRegex = new Regex(urlRegex, RegexOptions.Compiled);
         html = cleanupRegex.Replace(html, delegate(Match match)
         {
            return match.Value.Replace(urlMatch, String.Empty);
         });
         
         Regex imageregex = new Regex(config.ImageRegex, RegexOptions.Compiled);
         string url = String.Format("{0}{1}{2}", config.ImageRegexElement, urlPrefix, cdnUrl);

         html = imageregex.Replace(html, delegate(Match match)
         {
            return match.Value.Replace(config.ImageRegexElement, url);
         });

         return html;
      }
   }
}