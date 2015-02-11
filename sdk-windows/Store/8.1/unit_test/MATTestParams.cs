using MobileAppTracking;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Newtonsoft.Json;

namespace MATWindows81UnitTest
{
    public class MATTestParams : Object
    {
        private Dictionary<string, object> dictionary;

        public bool ExtractParamsString(string param)
        {
            String[] components = param.Split(new char[] {'?', '&'});
            for (int i = 0; i < components.Length; i++)
            {
                if (components[i].StartsWith("http") || components[i].Equals(""))
                    continue;

                String[] keyValue = components[i].Split(new char[] {'='});
                if (keyValue[0].Equals(""))
                    continue;

                if (dictionary == null)
                    dictionary = new Dictionary<string, object>();
                dictionary[keyValue[0]] = keyValue[1];
            }
            return true;
        }

        public string ValueForKey(string key)
        {
            if (dictionary == null)
                return null;
            if (dictionary[key] == null)
                return null;
            return Uri.UnescapeDataString(dictionary[key].ToString());
        }

        public bool CheckIsEmpty()
        {
            return (dictionary == null);
        }

        public bool CheckKeyHasValue(string key)
        {
            return (!CheckIsEmpty() && dictionary.ContainsKey(key) && dictionary[key] != null);
        }

        public bool CheckKeyIsEqualToValue(string key, string value)
        {
            return (CheckKeyHasValue(key) && ValueForKey(key).Equals(value));
        }

        public bool CheckActionIsSession()
        {
            return CheckKeyIsEqualToValue("action", "session");
        }

        public bool CheckActionIsConversion()
        {
            return CheckKeyIsEqualToValue("action", "conversion");
        }

        public bool CheckDefaultValues()
        {
            bool appValues = CheckAppValues();
            if (!appValues)
                Debug.WriteLine("App values check failed");

            bool sdkValues = CheckSDKValues();
            if (!sdkValues)
                Debug.WriteLine("SDK values check failed");
            return (appValues && sdkValues);
        }

        public bool CheckAppValues()
        {
            return (CheckKeyIsEqualToValue("advertiser_id", MATTestConstants.ADVERTISER_ID) &&
                    CheckKeyIsEqualToValue("package_name", MATTestConstants.PACKAGE_NAME) &&
                    CheckKeyHasValue("system_date") &&
                    CheckKeyIsEqualToValue("app_version", MATTestConstants.APP_VERSION));
        }

        public bool CheckSDKValues()
        {
            return (CheckKeyIsEqualToValue("sdk", "windows") &&
                    CheckKeyHasValue("ver") &&
                    CheckKeyHasValue("mat_id") &&
                    CheckKeyHasValue("transaction_id"));
        }

        public bool CheckEventItems(List<MATEventItem> items)
        {
            if (dictionary == null)
                return false;

            string unescapedEventItems = Uri.UnescapeDataString(dictionary["site_event_items"].ToString());
            List<MATEventItem> siteEventItems = JsonConvert.DeserializeObject<List<MATEventItem>>(unescapedEventItems);

            for (int i = 0; i < items.Count; i++)
            {
                MATEventItem origItem = items[i];
                MATEventItem requestItem = siteEventItems[i];

                if (!origItem.Equals(requestItem))
                    return false;
            }

            return true;
        }

        public static void Sleep(int ms)
        {
            new System.Threading.ManualResetEvent(false).WaitOne(ms);
        }
    }
}
