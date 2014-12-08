using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Text;


namespace MobileAppTracking
{
    public class MATUrlBuilder
    {
        private const string DOMAIN = "engine.mobileapptracking.com";
        private const string IV = "heF9BATUfWuISyO8";
        private const string SDK_TYPE = "windows";
        private const string SDK_VERSION = "3.3";
        
        //TODO: Look into using JSON rather than strings
        public static string BuildUrl(string action, string eventName, double revenue, string currency, string refId, List<MATEventItem> eventItems, Parameters parameters)
        {
            StringBuilder url = new StringBuilder("https://");
            url.Append(Uri.EscapeUriString(parameters.advertiserId)).Append(".");

            if (parameters.DebugMode)
                url.Append("debug.");
            url.Append(DOMAIN).Append("/serve?sdk=").Append(SDK_TYPE).Append("&ver=").Append(SDK_VERSION);
            url.Append("&advertiser_id=").Append(Uri.EscapeUriString(parameters.advertiserId));
            url.Append("&mat_id=").Append(Uri.EscapeUriString(parameters.MatId));
            url.Append("&action=").Append(Uri.EscapeUriString(action));
            url.Append("&package_name=").Append(Uri.EscapeUriString(parameters.PackageName));
            url.Append("&transaction_id=").Append(Guid.NewGuid().ToString().ToUpper());
            // Append event name/ID for events
            if (action.Equals("conversion"))
            {
                long value;
                if (long.TryParse(eventName, out value))
                    url.Append("&site_event_id=").Append(eventName);
                else
                    url.Append("&site_event_name=").Append(Uri.EscapeUriString(eventName));
            }

            // Append open log id
            if (parameters.OpenLogId != null)
                url.Append("&open_log_id=").Append(Uri.EscapeUriString(parameters.OpenLogId));
            if (parameters.LastOpenLogId != null)
                url.Append("&last_open_log_id=").Append(Uri.EscapeUriString(parameters.LastOpenLogId));

            if (parameters.AllowDuplicates)
                url.Append("&skip_dup=1");
            if (parameters.DebugMode)
                url.Append("&debug=1");
            if (parameters.ExistingUser)
                url.Append("&existing_user=1");

            // Construct encrypted data params and append to url
            StringBuilder data = new StringBuilder();
            // Add UNIX timestamp as system date
            long timestamp = UnixTimestamp();
            data.Append("&system_date=").Append(timestamp.ToString());

            data.Append("&windows_aid=").Append(Uri.EscapeUriString(parameters.WindowsAid));
            data.Append("&app_name=").Append(Uri.EscapeUriString(parameters.AppName));
            data.Append("&app_version=").Append(Uri.EscapeUriString(parameters.AppVersion));
            data.Append("&os_id=").Append(Uri.EscapeUriString(parameters.ASHWID));
            if (parameters.UserAgent != null)
                data.Append("&user_agent=").Append(Uri.EscapeUriString(parameters.UserAgent));
            if (parameters.AppAdTracking)
                data.Append("&app_ad_tracking=1");
            else
                data.Append("&app_ad_tracking=0");

            if (revenue > 0)
                data.Append("&revenue=").Append(Uri.EscapeUriString(revenue.ToString(parameters.culture)));
            if (currency != null)
                data.Append("&currency_code=").Append(Uri.EscapeUriString(currency));
            if (refId != null)
                data.Append("&advertiser_ref_id=").Append(Uri.EscapeUriString(refId));

            if (parameters.Age > 0)
                data.Append("&age=").Append(Uri.EscapeUriString(parameters.Age.ToString(parameters.culture)));
            data.Append("&altitude=").Append(Uri.EscapeUriString(parameters.Altitude.ToString()));
            if (parameters.EventContentType != null)
                data.Append("&content_type=").Append(Uri.EscapeUriString(parameters.EventContentType));
            if (parameters.EventContentId != null)
                data.Append("&content_id=").Append(Uri.EscapeUriString(parameters.EventContentId));
            data.Append("&level=").Append(parameters.EventLevel.ToString());
            data.Append("&quantity=").Append(parameters.EventQuantity.ToString());
            if (parameters.EventSearchString != null)
                data.Append("&search_string=").Append(Uri.EscapeUriString(parameters.EventSearchString));
            data.Append("&rating=").Append(Uri.EscapeUriString(parameters.EventRating.ToString()));
            if (parameters.EventDate1 != null)
                data.Append("&date1=").Append(Uri.EscapeUriString(UnixTimestamp(parameters.EventDate1).ToString()));
            if (parameters.EventDate2 != null)
                data.Append("&date2=").Append(Uri.EscapeUriString(UnixTimestamp(parameters.EventDate2).ToString()));
            if (parameters.EventAttribute1 != null)
                data.Append("&attribute_sub1=").Append(Uri.EscapeUriString(parameters.EventAttribute1));
            if (parameters.EventAttribute2 != null)
                data.Append("&attribute_sub2=").Append(Uri.EscapeUriString(parameters.EventAttribute2));
            if (parameters.EventAttribute3 != null)
                data.Append("&attribute_sub3=").Append(Uri.EscapeUriString(parameters.EventAttribute3));
            if (parameters.EventAttribute4 != null)
                data.Append("&attribute_sub4=").Append(Uri.EscapeUriString(parameters.EventAttribute4));
            if (parameters.EventAttribute5 != null)
                data.Append("&attribute_sub5=").Append(Uri.EscapeUriString(parameters.EventAttribute5));
            if (parameters.DeviceBrand != null)
                data.Append("&device_brand=").Append(Uri.EscapeUriString(parameters.DeviceBrand));
            if (parameters.DeviceModel != null)
                data.Append("&device_model=").Append(Uri.EscapeUriString(parameters.DeviceModel));
            if (parameters.DeviceType != null)
                data.Append("&device_type=").Append(Uri.EscapeUriString(parameters.DeviceType));
            if (parameters.FacebookUserId != null)
                data.Append("&facebook_user_id=").Append(Uri.EscapeUriString(parameters.FacebookUserId));
            if (parameters.Gender != MATGender.NONE)
                data.Append("&gender=").Append(Uri.EscapeUriString(((int)parameters.Gender).ToString(parameters.culture)));
            if (parameters.GoogleUserId != null)
                data.Append("&google_user_id=").Append(Uri.EscapeUriString(parameters.GoogleUserId));
            if (parameters.IsPayingUser != false)
                data.Append("&is_paying_user=1");
            if (parameters.Latitude != 0)
                data.Append("&latitude=").Append(Uri.EscapeUriString(parameters.Latitude.ToString(parameters.culture)));
            if (parameters.Longitude != 0)
                data.Append("&longitude=").Append(Uri.EscapeUriString(parameters.Longitude.ToString(parameters.culture)));
            if (parameters.TwitterUserId != null)
                data.Append("&twitter_user_id=").Append(Uri.EscapeUriString(parameters.TwitterUserId));
            if (parameters.UserEmail != null)
                data.Append("&user_email=").Append(Uri.EscapeUriString(parameters.UserEmail));
            if (parameters.UserId != null)
                data.Append("&user_id=").Append(Uri.EscapeUriString(parameters.UserId));
            if (parameters.UserName != null)
                data.Append("&user_name=").Append(Uri.EscapeUriString(parameters.UserName));

            // Add event items to url as json string
            if (eventItems != null)
                data.Append("&site_event_items=").Append(Uri.EscapeUriString(JsonConvert.SerializeObject(eventItems)));

            if (parameters.matRequest != null)
                parameters.matRequest.ParamsToBeEncrypted(data.ToString());

            // Encrypt data string
            string dataStr = parameters.urlEncrypter.Encrypt(data.ToString());
            url.Append("&data=").Append(dataStr);

            url.Append("&response_format=json");

            if (parameters.matRequest != null)
                parameters.matRequest.ConstructedRequest(url.ToString());

            return url.ToString();
        }

        public static long UnixTimestamp()
        {
            return UnixTimestamp(DateTime.UtcNow);
        }

        public static long UnixTimestamp(DateTime? date)
        {
            var utcEpoch = new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc);
            var span = date - utcEpoch;
            return (long)(span ?? TimeSpan.Zero).TotalSeconds;
        }
    }
}
