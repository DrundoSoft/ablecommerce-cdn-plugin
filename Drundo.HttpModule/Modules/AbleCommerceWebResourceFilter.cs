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
   public class AbleCommerceWebResourceFilter : Stream
   {
      private readonly Stream sink;

      public AbleCommerceWebResourceFilter(Stream sink)
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

      public override void Write(byte[] buffer, int offset, int count)
      {
         var html = Encoding.UTF8.GetString(buffer, offset, count);
         DrundoHttpModuleConfig config = (DrundoHttpModuleConfig)ConfigurationManager.GetSection("DrundoHttpModuleConfig");
         bool IsUseCdnOk = true;

         if ((null != config) && !String.IsNullOrEmpty(config.CdnUrlName) && config.IsEnabled)
         {
            string cdnUrl = config.CdnUrlName;
            string urlPrefix = "http://";

            //Set url prefix to https if cdn supports ssl and current url is https
            if (HttpContext.Current.Request.IsSecureConnection && config.IsSecure)
            {
               urlPrefix = "https://";
            }

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
               Regex imageregex = new Regex(config.ImageRegex, RegexOptions.Compiled);
               string url = string.Format("{0}{1}{2}/", config.ImageRegexElement, urlPrefix, cdnUrl);

               html = imageregex.Replace(html, delegate(Match match)
               {
                  return match.Value.Replace(config.ImageRegexElement, url);
               });

               //Enable CDN for .CSS and JavaScript files
               if (config.IsScriptEnabled)
               {
                  //Process style links
                  Regex styleregex = new Regex(config.StyleRegex, RegexOptions.Compiled);
                  url = string.Format("{0}{1}{2}/", config.StyleRegexElement, urlPrefix, cdnUrl);

                  html = styleregex.Replace(html, delegate(Match match)
                  {
                     return match.Value.Replace(config.StyleRegexElement, url);
                  });

                  //Process script links
                  Regex scriptregex = new Regex(config.ScriptRegex, RegexOptions.Compiled);
                  url = string.Format("{0}{1}{2}/", config.ScriptRegexElement, urlPrefix, cdnUrl);

                  html = scriptregex.Replace(html, delegate(Match match)
                  {
                     return match.Value.Replace(config.ScriptRegexElement, url);
                  });
               }
            }
         }

         var outdata = Encoding.UTF8.GetBytes(html);
         this.sink.Write(outdata, 0, outdata.GetLength(0));
      }
   }
}