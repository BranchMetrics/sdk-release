using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Net;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;
using System.Xml.Linq;
using Windows.ApplicationModel;
using Windows.Networking.Connectivity;
using Windows.Security.Cryptography;
using Windows.Storage.Streams;
using Windows.System.Profile;
using Windows.Storage;

using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace MobileAppTracking
{
    public enum MATGender
    {
        MALE,
        FEMALE,
        NONE
    }

    public class MobileAppTracker
    {
        private const string DOMAIN = "engine.mobileapptracking.com";
        private const string IV = "heF9BATUfWuISyO8";
        private const string SDK_TYPE = "windows";
        private const string SDK_VERSION = "3.3.1";
        private const string SETTINGS_MATEVENTQUEUE_KEY = "mat_event_queue";
        private const string SETTINGS_MATEVENTQUEUESIZE_KEY = "mat_event_queue_size";
        private const string SETTINGS_MATID_KEY = "mat_id";
        private const string SETTINGS_MATLASTOPENLOGID_KEY = "mat_last_open_log_id";
        private const string SETTINGS_MATOPENLOGID_KEY = "mat_open_log_id";
        private const string SETTINGS_IS_PAYING_USER_KEY = "mat_is_paying_user";
        private const string SETTINGS_USERID_KEY = "mat_user_id";
        private const string SETTINGS_USEREMAIL_KEY = "mat_user_email";
        private const string SETTINGS_USERNAME_KEY = "mat_user_name";

        private ApplicationDataContainer localSettings;
        private CultureInfo culture;
        private Encryption urlEncrypter;

        private readonly object syncLock;

        private bool nextConnectIsFirst = true;

        private string advertiserId;
        private string advertiserKey;

        private MATResponse matResponse;
        protected MATTestRequest matRequest;

        // MAT properties
        public int Age { get; set; }
        public bool AllowDuplicates { get; set; }
        public double Altitude { get; set; }
        public bool AppAdTracking { get; set; }
        public string AppVersion { get; set; }
        public string ASHWID { get; set; }
        public bool DebugMode { get; set; }
        public string EventContentType { get; set; }
        public string EventContentId { get; set; }
        public int EventLevel { get; set; }
        public int EventQuantity { get; set; }
        public string EventSearchString { get; set; }
        public double EventRating { get; set; }
        public System.Nullable<DateTime> EventDate1 { get; set; }
        public System.Nullable<DateTime> EventDate2 { get; set; }
        public string EventAttribute1 { get; set; }
        public string EventAttribute2 { get; set; }
        public string EventAttribute3 { get; set; }
        public string EventAttribute4 { get; set; }
        public string EventAttribute5 { get; set; }
        public bool ExistingUser { get; set; }
        public string FacebookUserId { get; set; }
        public MATGender Gender { get; set; }
        public string GoogleUserId { get; set; }
        public bool IsPayingUser
        {
            get
            {
                if (GetLocalSetting(SETTINGS_IS_PAYING_USER_KEY) != null)
                    return (bool)GetLocalSetting(SETTINGS_IS_PAYING_USER_KEY);
                return false;
            }
            set
            {
                SaveLocalSetting(SETTINGS_IS_PAYING_USER_KEY, value);
            }
        }
        public string LastOpenLogId
        {
            get
            {
                if (GetLocalSetting(SETTINGS_MATLASTOPENLOGID_KEY) != null)
                    return (string)GetLocalSetting(SETTINGS_MATLASTOPENLOGID_KEY);
                return null;
            }
            set
            {
                SaveLocalSetting(SETTINGS_MATLASTOPENLOGID_KEY, value);
            }
        }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public string MatId { get; set; }
        public string OpenLogId
        {
            get
            {
                if (GetLocalSetting(SETTINGS_MATOPENLOGID_KEY) != null)
                    return (string)GetLocalSetting(SETTINGS_MATOPENLOGID_KEY);
                return null;
            }
            set
            {
                SaveLocalSetting(SETTINGS_MATOPENLOGID_KEY, value);
            }
        }
        public string PackageName { get; set; }
        public string TwitterUserId { get; set; }
        public string UserEmail
        {
            get
            {
                return (string)GetLocalSetting(SETTINGS_USEREMAIL_KEY);
            }
            set
            {
                SaveLocalSetting(SETTINGS_USEREMAIL_KEY, value);
            }
        }
        public string UserId
        {
            get
            {
                return (string)GetLocalSetting(SETTINGS_USERID_KEY);
            }
            set
            {
                SaveLocalSetting(SETTINGS_USERID_KEY, value);
            }
        }
        public string UserName
        {
            get
            {
                return (string)GetLocalSetting(SETTINGS_USERNAME_KEY);
            }
            set
            {
                SaveLocalSetting(SETTINGS_USERNAME_KEY, value);
            }
        }

        public void SetMATResponse(MATResponse response)
        {
            this.matResponse = response;
        }

        // Helper function to save key-value pair to ApplicationSettings
        private void SaveLocalSetting(string key, object value)
        {
            localSettings.Values[key] = value;
        }

        // Helper function to get value from ApplicationSettings
        private object GetLocalSetting(string key)
        {
            if (localSettings.Values.ContainsKey(key))
                return localSettings.Values[key];

            return null;
        }

        private void OnNetworkStatusChange(object sender)
        {
            // Get the ConnectionProfile that is currently used to connect to the Internet
            ConnectionProfile profile = NetworkInformation.GetInternetConnectionProfile();

            if (profile != null)
            {
                // NetworkInformation.NetworkStatusChanged fires multiple times for some reason, so we only want to get the first real reconnect
                if (profile.GetNetworkConnectivityLevel() < NetworkConnectivityLevel.InternetAccess)
                {
                    nextConnectIsFirst = true;
                }
                else if (profile.GetNetworkConnectivityLevel() >= NetworkConnectivityLevel.InternetAccess && nextConnectIsFirst)
                {
                    nextConnectIsFirst = false;
                    DumpQueue();
                }
            }
        }

        public MobileAppTracker(string advId, string advKey)
        {
            this.culture = new CultureInfo("en-US");

            this.advertiserId = advId;
            this.advertiserKey = advKey;

            this.localSettings = ApplicationData.Current.LocalSettings;
            this.syncLock = new object();

            this.urlEncrypter = new Encryption(advKey, IV);

            this.matResponse = null;

            // Default values
            this.AllowDuplicates = false;
            this.DebugMode = false;
            this.ExistingUser = false;
            this.AppAdTracking = true;
            this.Gender = MATGender.NONE;

            var version = Package.Current.Id.Version;
            this.AppVersion = String.Format("{0}.{1}.{2}.{3}", version.Major, version.Minor, version.Build, version.Revision);

            this.PackageName = Package.Current.Id.Name;

            // Get ASHWID
            var hardwareId = HardwareIdentification.GetPackageSpecificToken(null).Id;
            var dataReader = DataReader.FromBuffer(hardwareId);
            byte[] bytes = new byte[hardwareId.Length];
            dataReader.ReadBytes(bytes);
            this.ASHWID = BitConverter.ToString(bytes);

            // Check if we can restore existing MAT ID or should generate new one
            if (localSettings.Values.ContainsKey(SETTINGS_MATID_KEY))
            {
                this.MatId = (string)localSettings.Values[SETTINGS_MATID_KEY];
            }
            else // Don't have MAT ID, generate new guid
            {
                this.MatId = System.Guid.NewGuid().ToString();
                SaveLocalSetting(SETTINGS_MATID_KEY, this.MatId);
            }

            // Handles the OnNetworkStatusChange event 
            NetworkStatusChangedEventHandler networkStatusCallback = null;

            // Indicates if the connection profile is registered for network status change events. Set the default value to FALSE. 
            bool registeredNetworkStatusNotif = false;

            networkStatusCallback = new NetworkStatusChangedEventHandler(OnNetworkStatusChange);

            // Register for network status change notifications
            if (!registeredNetworkStatusNotif)
            {
                NetworkInformation.NetworkStatusChanged += networkStatusCallback;
                registeredNetworkStatusNotif = true;
            }

            // Check for internet connectivity and send queued requests        
            ConnectionProfile profile = NetworkInformation.GetInternetConnectionProfile();
            if (profile != null && profile.GetNetworkConnectivityLevel() >= NetworkConnectivityLevel.InternetAccess)
                DumpQueue();
        }

        public void MeasureSession()
        {
            Track("session");
        }

        public void MeasureAction(string eventName, double revenue = 0, string currency = null, string refId = null, List<MATEventItem> eventItems = null)
        {
            Track(eventName, revenue, currency, refId, eventItems);
        }

        private void Track(string eventName, double revenue = 0, string currency = null, string refId = null, List<MATEventItem> eventItems = null)
        {
            DumpQueue();

            string action = "conversion";

            // Don't send close events
            if (eventName.Equals("close"))
                return;
            if (eventName.Equals("open") || eventName.Equals("install") || eventName.Equals("update") || eventName.Equals("session"))
                action = "session";

            if (revenue > 0)
                this.IsPayingUser = true;

            string url = BuildUrl(action, eventName, revenue, currency, refId, eventItems);

            AddToQueue(url);

            if (matResponse != null)
                matResponse.EnqueuedActionWithRefId(refId);
            
            DumpQueue();

            this.EventContentType = null;
            this.EventContentId = null;
            this.EventLevel = 0;
            this.EventQuantity = 0;
            this.EventSearchString = null;
            this.EventRating = 0.0;
            this.EventDate1 = null;
            this.EventDate2 = null;
            this.EventAttribute1 = null;
            this.EventAttribute2 = null;
            this.EventAttribute3 = null;
            this.EventAttribute4 = null;
            this.EventAttribute5 = null;
        }

        // Add a url to event queue to send later
        private void AddToQueue(string url)
        {
            lock (syncLock)
            {
                int eventQueueSize = 0;
                // Get current size of queue if exists
                if (localSettings.Values.ContainsKey(SETTINGS_MATEVENTQUEUESIZE_KEY))
                    eventQueueSize = (int)localSettings.Values[SETTINGS_MATEVENTQUEUESIZE_KEY];

                // Save url as value for key "mat_event_queue_(index)"
                string eventQueueKey = SETTINGS_MATEVENTQUEUE_KEY + "_" + eventQueueSize.ToString();
                SaveLocalSetting(eventQueueKey, url);
                eventQueueSize++;
                SaveLocalSetting(SETTINGS_MATEVENTQUEUESIZE_KEY, eventQueueSize);
            }
        }

        // Send all queued requests
        private void DumpQueue()
        {
            // Check for internet connectivity and return immediately if none found
            ConnectionProfile profile = NetworkInformation.GetInternetConnectionProfile();
            if (profile == null || profile.GetNetworkConnectivityLevel() < NetworkConnectivityLevel.InternetAccess)
                return;

            lock (syncLock)
            {
                if (localSettings.Values.ContainsKey(SETTINGS_MATEVENTQUEUESIZE_KEY))
                {
                    // Get size of queue and iterate through indexes
                    int eventQueueSize = (int)localSettings.Values[SETTINGS_MATEVENTQUEUESIZE_KEY];

                    for (int i = 0; i < eventQueueSize; i++)
                    {
                        string eventQueueKey = SETTINGS_MATEVENTQUEUE_KEY + "_" + i.ToString();
                        if (localSettings.Values.ContainsKey(eventQueueKey))
                        {
                            string url = (string)localSettings.Values[eventQueueKey];
                            if (this.DebugMode)
                                Debug.WriteLine("Sending MAT event to server...");
                            SendRequest(url);
                            if (this.DebugMode)
                                Debug.WriteLine("MAT request sent");
                            // Decrement queue size
                            SaveLocalSetting(SETTINGS_MATEVENTQUEUESIZE_KEY, (int)localSettings.Values[SETTINGS_MATEVENTQUEUESIZE_KEY] - 1);
                        }
                    }
                }
            }
        }

        private string BuildUrl(string action, string eventName, double revenue, string currency, string refId, List<MATEventItem> eventItems)
        {
            StringBuilder url = new StringBuilder("https://");
            url.Append(Uri.EscapeUriString(this.advertiserId)).Append(".");

            if (this.DebugMode)
                url.Append("debug.");
            url.Append(DOMAIN).Append("/serve?sdk=").Append(SDK_TYPE).Append("&ver=").Append(SDK_VERSION);
            url.Append("&advertiser_id=").Append(Uri.EscapeUriString(this.advertiserId));
            url.Append("&mat_id=").Append(Uri.EscapeUriString(this.MatId));
            url.Append("&action=").Append(Uri.EscapeUriString(action));
            url.Append("&package_name=").Append(Uri.EscapeUriString(this.PackageName));
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
            if (this.OpenLogId != null)
                url.Append("&open_log_id=").Append(Uri.EscapeUriString(this.OpenLogId));
            if (this.LastOpenLogId != null)
                url.Append("&last_open_log_id=").Append(Uri.EscapeUriString(this.LastOpenLogId));

            if (this.AllowDuplicates)
                url.Append("&skip_dup=1");
            if (this.DebugMode)
                url.Append("&debug=1");
            if (this.ExistingUser)
                url.Append("&existing_user=1");

            // Construct encrypted data params and append to url
            StringBuilder data = new StringBuilder();
            // Add UNIX timestamp as system date
            long timestamp = UnixTimestamp();
            data.Append("&system_date=").Append(timestamp.ToString());

            data.Append("&app_version=").Append(Uri.EscapeUriString(this.AppVersion));
            data.Append("&os_id=").Append(Uri.EscapeUriString(this.ASHWID));
            if (this.AppAdTracking)
                data.Append("&app_ad_tracking=1");
            else
                data.Append("&app_ad_tracking=0");

            if (revenue > 0)
                data.Append("&revenue=").Append(Uri.EscapeUriString(revenue.ToString(culture)));
            if (currency != null)
                data.Append("&currency_code=").Append(Uri.EscapeUriString(currency));
            if (refId != null)
                data.Append("&advertiser_ref_id=").Append(Uri.EscapeUriString(refId));

            if (this.Age > 0)
                data.Append("&age=").Append(Uri.EscapeUriString(this.Age.ToString(culture)));
            data.Append("&altitude=").Append(Uri.EscapeUriString(this.Altitude.ToString()));
            if (this.EventContentType != null)
                data.Append("&content_type=").Append(Uri.EscapeUriString(this.EventContentType));
            if (this.EventContentId != null)
                data.Append("&content_id=").Append(Uri.EscapeUriString(this.EventContentId));
            data.Append("&level=").Append(this.EventLevel.ToString());
            data.Append("&quantity=").Append(this.EventQuantity.ToString());
            if (this.EventSearchString != null)
                data.Append("&search_string=").Append(Uri.EscapeUriString(this.EventSearchString));
            data.Append("&rating=").Append(Uri.EscapeUriString(this.EventRating.ToString()));
            if (this.EventDate1 != null)
                data.Append("&date1=").Append(Uri.EscapeUriString(UnixTimestamp(this.EventDate1).ToString()));
            if (this.EventDate2 != null)
                data.Append("&date2=").Append(Uri.EscapeUriString(UnixTimestamp(this.EventDate2).ToString()));
            if (this.EventAttribute1 != null)
                data.Append("&attribute_sub1=").Append(Uri.EscapeUriString(this.EventAttribute1));
            if (this.EventAttribute2 != null)
                data.Append("&attribute_sub2=").Append(Uri.EscapeUriString(this.EventAttribute2));
            if (this.EventAttribute3 != null)
                data.Append("&attribute_sub3=").Append(Uri.EscapeUriString(this.EventAttribute3));
            if (this.EventAttribute4 != null)
                data.Append("&attribute_sub4=").Append(Uri.EscapeUriString(this.EventAttribute4));
            if (this.EventAttribute5 != null)
                data.Append("&attribute_sub5=").Append(Uri.EscapeUriString(this.EventAttribute5));
            if (this.FacebookUserId != null)
                data.Append("&facebook_user_id=").Append(Uri.EscapeUriString(this.FacebookUserId));
            if (this.Gender != MATGender.NONE)
                data.Append("&gender=").Append(Uri.EscapeUriString(((int)this.Gender).ToString(culture)));
            if (this.GoogleUserId != null)
                data.Append("&google_user_id=").Append(Uri.EscapeUriString(this.GoogleUserId));
            if (this.IsPayingUser != false)
                data.Append("&is_paying_user=1");
            if (this.Latitude != 0)
                data.Append("&latitude=").Append(Uri.EscapeUriString(this.Latitude.ToString(culture)));
            if (this.Longitude != 0)
                data.Append("&longitude=").Append(Uri.EscapeUriString(this.Longitude.ToString(culture)));
            if (this.TwitterUserId != null)
                data.Append("&twitter_user_id=").Append(Uri.EscapeUriString(this.TwitterUserId));
            if (this.UserEmail != null)
                data.Append("&user_email=").Append(Uri.EscapeUriString(this.UserEmail));
            if (this.UserId != null)
                data.Append("&user_id=").Append(Uri.EscapeUriString(this.UserId));
            if (this.UserName != null)
                data.Append("&user_name=").Append(Uri.EscapeUriString(this.UserName));

            // Add event items to url as json string
            if (eventItems != null)
                data.Append("&site_event_items=").Append(Uri.EscapeUriString(JsonConvert.SerializeObject(eventItems)));

            if (matRequest != null)
                matRequest.ParamsToBeEncrypted(data.ToString());

            // Encrypt data string
            string dataStr = urlEncrypter.Encrypt(data.ToString());
            url.Append("&data=").Append(dataStr);

            url.Append("&response_format=json");

            if (matRequest != null)
                matRequest.ConstructedRequest(url.ToString());

            return url.ToString();
        }

        private void SendRequest(string url)
        {
            HttpWebRequest request = (HttpWebRequest)HttpWebRequest.Create(url);
            request.BeginGetResponse(GetUrlCallback, request);
        }

        private void GetUrlCallback(IAsyncResult result)
        {
            if (result == null || result.AsyncState == null)
            {
                return;
            }
            HttpWebRequest request = result.AsyncState as HttpWebRequest;
            try
            {
                HttpWebResponse response = (HttpWebResponse)request.EndGetResponse(result);

                using (Stream stream = response.GetResponseStream())
                {
                    StreamReader reader = new StreamReader(stream, Encoding.UTF8);
                    string responseString = reader.ReadToEnd();
                    HttpStatusCode statusCode = response.StatusCode;

                    // If status between 200 and 300, success
                    if (statusCode >= HttpStatusCode.OK && statusCode < HttpStatusCode.MultipleChoices)
                    {
                        JToken root = JObject.Parse(responseString);

                        JToken successToken = root["success"];
                        bool success = successToken.ToString().ToLower().Equals("true");

                        if (success)
                        {
                            if (matResponse != null)
                                matResponse.DidSucceedWithData(responseString);

                            // Get site_event_type from json response
                            JToken siteEventTypeToken = root["site_event_type"];
                            string siteEventType = siteEventTypeToken.ToString();

                            // Only store log_id for opens
                            if (siteEventType.Equals("open"))
                            {
                                JToken logIdToken = root["log_id"];
                                string logId = logIdToken.ToString();

                                if (this.OpenLogId == null)
                                    this.OpenLogId = logId;
                                this.LastOpenLogId = logId;
                            }
                        }
                        else
                        {
                            if (matResponse != null)
                                matResponse.DidFailWithError(responseString);
                        }

                        if (this.DebugMode)
                            Debug.WriteLine("Server response is " + responseString);
                    }
                    else if (statusCode == HttpStatusCode.BadRequest && response.Headers["X-MAT-Responder"] != null)
                    {
                        if (matResponse != null)
                            matResponse.DidFailWithError(responseString);

                        Debug.WriteLine("MAT request received 400 error from server, won't be retried");
                        return;
                    }
                    else // Requeue all other requests
                    {
                        Debug.WriteLine("MAT request failed, will be queued");
                        AddToQueue(request.RequestUri.ToString());
                    }
                }
            }
            catch (WebException e)
            {
                Debug.WriteLine(e.Message);
                // Requeue the request for SSL error
                // Have to convert to String because TrustFailure isn't accessible in this .NET WebExceptionStatus for some reason
                if (e.Status.ToString().Equals("TrustFailure"))
                    AddToQueue(request.RequestUri.ToString());
                return;
            }
        }

        private static long UnixTimestamp()
        {
            return UnixTimestamp(DateTime.UtcNow);
        }

        protected static long UnixTimestamp(DateTime? date)
        {
            var utcEpoch = new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc);
            var span = date - utcEpoch;
            return (long)(span ?? TimeSpan.Zero).TotalSeconds;
        }
    }
}