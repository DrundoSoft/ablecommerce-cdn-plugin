using System;
using System.Collections.Generic;
using System.Xml.Serialization;
using System.Text;
using System.IO;
using System.Xml;

namespace Drundo.HttpModule.Configuration
{
   [Serializable]
   public class DrundoHttpModuleConfig
   {
      [XmlElement]
      public string PlatformName { get; set; }
      [XmlElement]
      public string CdnUrlName { get; set; }
      [XmlElement]
      public bool IsSecure { get; set; }
      [XmlElement]
      public bool IsEnabled { get; set; }
      [XmlElement]
      public bool IsScriptEnabled { get; set; }
      [XmlElement]
      public string ScriptRegex { get; set; }
      [XmlElement]
      public string ScriptRegexElement { get; set; }
      [XmlElement]
      public string StyleRegex { get; set; }
      [XmlElement]
      public string StyleRegexElement { get; set; }
      [XmlElement]
      public string ImageRegex { get; set; }
      [XmlElement]
      public string ImageRegexElement { get; set; }

      /// <summary>
      /// CTOR
      /// </summary>
      public DrundoHttpModuleConfig()
      {
         PlatformName = String.Empty;
         CdnUrlName = String.Empty;
         IsSecure = false;
         IsEnabled = false;
         IsScriptEnabled = false;
         ScriptRegex = String.Empty;
         StyleRegex = String.Empty;
         StyleRegexElement = String.Empty;
         ImageRegex = String.Empty;
         ImageRegexElement = String.Empty;
      }

      /// <summary>
      /// Save HttpModule config settings into a configuration file
      /// </summary>
      /// <param name="file"></param>
      /// <param name="config"></param>
      public static void Serialize(string file, DrundoHttpModuleConfig config)
      {
         XmlSerializerNamespaces xns = new XmlSerializerNamespaces();
         XmlSerializer xmlSerializer = new XmlSerializer(config.GetType());
         StreamWriter xmlWriter = File.CreateText(file);
         
         xns.Add(string.Empty, string.Empty);
         xmlSerializer.Serialize(xmlWriter, config, xns);
         xmlWriter.Flush();
         xmlWriter.Close();

         //add type attribute to the root node
         XmlDocument configFile = new XmlDocument();
         configFile.Load(file);

         XmlNode rootNode = configFile.SelectSingleNode("DrundoHttpModuleConfig");
         XmlAttribute typeAttr = configFile.CreateAttribute("type");
         typeAttr.Value = "Drundo.HttpModule.Configuration.DrundoHttpModuleConfig, Drundo.HttpModule";
         rootNode.Attributes.Append(typeAttr);
         configFile.Save(file);
      }

      /// <summary>
      /// Load HttpModile configuration settings from a configuration file  
      /// </summary>
      /// <param name="file"></param>
      /// <returns></returns>
      public static DrundoHttpModuleConfig Deserialize(string file)
      {
         XmlSerializer xmlSerializer = new XmlSerializer(typeof(DrundoHttpModuleConfig));
         StreamReader xmlReader = File.OpenText(file);
         DrundoHttpModuleConfig moduleConfig = (DrundoHttpModuleConfig)xmlSerializer.Deserialize(xmlReader);
         xmlReader.Close();

         return moduleConfig;
      }
   }
}