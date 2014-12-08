using System;
using System.Collections.Generic;
using Windows.Networking.Connectivity;
using Windows.Storage.Streams;
using Windows.System.Profile;

using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml;
using Windows.UI.Core;


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
        private static MobileAppTracker instance;

        private const string DOMAIN = "engine.mobileapptracking.com";
        private const string IV = "heF9BATUfWuISyO8";
        private const string SDK_TYPE = "windows";
        private const string SDK_VERSION = "3.3";
        private const string SETTINGS_MATEVENTQUEUE_KEY = "mat_event_queue";
        private const string SETTINGS_MATEVENTQUEUESIZE_KEY = "mat_event_queue_size";
        private const string SETTINGS_MATID_KEY = "mat_id";
        private const string SETTINGS_MATLASTOPENLOGID_KEY = "mat_last_open_log_id";
        private const string SETTINGS_MATOPENLOGID_KEY = "mat_open_log_id";
        private const string SETTINGS_IS_PAYING_USER_KEY = "mat_is_paying_user";
        private const string SETTINGS_USERID_KEY = "mat_user_id";
        private const string SETTINGS_USEREMAIL_KEY = "mat_user_email";
        private const string SETTINGS_USERNAME_KEY = "mat_user_name";

        //private Encryption urlEncrypter;
        private bool nextConnectIsFirst = true;

        protected internal Parameters parameters;
        protected internal MATEventQueue eventQueue;
        

        protected internal MobileAppTracker()
        {
        }

        // Lazy instantiation singleton
        public static MobileAppTracker Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = new MobileAppTracker();

                }
                return instance;
            }
        }

        public void InitializeValues(string advId, string advKey)
        {
            var hardwareId = HardwareIdentification.GetPackageSpecificToken(null).Id;
            var dataReader = DataReader.FromBuffer(hardwareId);
            byte[] bytes = new byte[hardwareId.Length];
            dataReader.ReadBytes(bytes);

            this.parameters = new Parameters(advId, advKey, bytes);

            eventQueue = new MATEventQueue(parameters);

            GetUserAgent();

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

            // Send queued requests
            eventQueue.DumpQueue();
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
                    eventQueue.DumpQueue();
                }
            }
        }

        private void GetUserAgent()
        {
            // Only get user agent if running on UI thread
            if (CoreWindow.GetForCurrentThread() != null)
            {
                var dispatcher = CoreWindow.GetForCurrentThread().Dispatcher;
                dispatcher.RunAsync(CoreDispatcherPriority.Normal, delegate()
                {
                    // Create a new WebView and get user agent
                    WebView wv = new WebView();
                    wv.Visibility = Visibility.Collapsed;
                    wv.ScriptNotify += new NotifyEventHandler(UserAgentScriptNotify);
                    string html =
                        "<html><head><script type='text/javascript'>function GetUserAgent() {" +
                        "window.external.notify(navigator.userAgent);}" +
                        "</script></head>" +
                        "<body onload='GetUserAgent();'></body></html>";
                    wv.NavigateToString(html);
                });
            }
        }

        public void UserAgentScriptNotify(object sender, NotifyEventArgs e)
        {
            parameters.UserAgent = e.Value;
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
            string action = "conversion";

            // Don't send close events
            if (eventName.Equals("close"))
                return;
            if (eventName.Equals("open") || eventName.Equals("install") || eventName.Equals("update") || eventName.Equals("session"))
                action = "session";

            if (revenue > 0)
                parameters.IsPayingUser = true;

            //Create hard copy of fields before making async tracking request
            Parameters copy = parameters.Copy();

            eventQueue.ProcessTrackingRequest(action, eventName, revenue, currency, refId, eventItems, copy);

            if (parameters.matResponse != null)
                parameters.matResponse.EnqueuedActionWithRefId(refId);

            parameters.EventContentType = null;
            parameters.EventContentId = null;
            parameters.EventLevel = 0;
            parameters.EventQuantity = 0;
            parameters.EventSearchString = null;
            parameters.EventRating = 0.0;
            parameters.EventDate1 = null;
            parameters.EventDate2 = null;
            parameters.EventAttribute1 = null;
            parameters.EventAttribute2 = null;
            parameters.EventAttribute3 = null;
            parameters.EventAttribute4 = null;
            parameters.EventAttribute5 = null;
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

        // Helper function to save key-value pair to ApplicationSettings
        private void SaveLocalSetting(string key, object value)
        {
            parameters.localSettings.Values[key] = value;
        }

        // Helper function to get value from ApplicationSettings
        private object GetLocalSetting(string key)
        {
            if (parameters.localSettings.Values.ContainsKey(key))
                return parameters.localSettings.Values[key];

            return null;
        }

        public virtual bool IsOnline()
        {
            // Whether we have internet connectivity or not
            ConnectionProfile profile = NetworkInformation.GetInternetConnectionProfile();
            return (profile != null && profile.GetNetworkConnectivityLevel() >= NetworkConnectivityLevel.InternetAccess);
        }

        protected void SetEventQueue(MATEventQueue eventQueue) 
        {
            this.eventQueue = eventQueue;
        }

        //////////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////////
        /*---------------------------Getters----------------------------*/
        //////////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////////

        public int GetAge ()
        {
            return parameters.Age;        
        }
        public bool GetAllowDuplicates () 
        {
            return parameters.AllowDuplicates;
        }
        public double GetAltitude ()
        {
            return parameters.Altitude;
        }
        public bool GetAppAdTracking () 
        {
            return parameters.AppAdTracking;
        }
        public string GetAppName () 
        {
            return parameters.AppName; 
        }
        public string GetAppVersion () 
        { 
            return parameters.AppVersion; 
        }
        public string GetASHWID ()
        { 
            return parameters.ASHWID;
        }
        public bool GetDebugMode () 
        {
            return parameters.DebugMode;
        }
        public string GetEventContentType ()
        {
            return parameters.EventContentType;
        }
        public string GetEventContentId ()
        {
            return parameters.EventContentId;
        }
        public int GetEventLevel ()
        {
            return parameters.EventLevel;
        }
        public int GetEventQuantity ()
        {
            return parameters.EventQuantity;
        }
        public string GetEventSearchString ()
        {
            return parameters.EventSearchString;
        }
        public double GetEventRating ()
        {
            return parameters.EventRating;
        }
        public System.Nullable<DateTime> GetEventDate1 ()
        {
            return parameters.EventDate1;
        }
        public System.Nullable<DateTime> GetEventDate2 ()
        {
            return parameters.EventDate2;
        }
        public string GetEventAttribute1 ()
        {
            return parameters.EventAttribute1;
        }
        public string GetEventAttribute2 ()
        {
            return parameters.EventAttribute2;
        }
        public string GetEventAttribute3 ()
        {  
            return parameters.EventAttribute3;
        }
        public string GetEventAttribute4 ()
        {
            return parameters.EventAttribute4;
        }
        public string GetEventAttribute5 ()
        {
            return parameters.EventAttribute5;
        }
        public bool GetExistingUser ()
        {
            return parameters.ExistingUser;
        }
        public string GetFacebookUserId ()
        {
            return parameters.FacebookUserId;
        }
        public MATGender GetGender ()
        {
            return parameters.Gender;
        }
        public string GetGoogleUserId ()
        {
            return parameters.GoogleUserId;
        }
        public bool GetIsPayingUser () //special
        {
            if (GetLocalSetting(SETTINGS_IS_PAYING_USER_KEY) != null)
                return (bool)GetLocalSetting(SETTINGS_IS_PAYING_USER_KEY);
            return false;
        }
        public string GetLastOpenLogId () //special
        {
            if (GetLocalSetting(SETTINGS_MATLASTOPENLOGID_KEY) != null)
                return (string)GetLocalSetting(SETTINGS_MATLASTOPENLOGID_KEY);
            return null;
        }
        public double GetLatitude ()
        { 
            return parameters.Latitude; 
        }
        public double GetLongitude ()
        { 
            return parameters.Longitude; 
        }
        public string GetMatId ()
        { 
            return parameters.MatId; 
        }
        public string GetOpenLogId () //special
        {
            if (GetLocalSetting(SETTINGS_MATOPENLOGID_KEY) != null)
                return (string)GetLocalSetting(SETTINGS_MATOPENLOGID_KEY);
            return null;
        }
        public string GetPackageName ()
        { 
            return parameters.PackageName; 
        }
        public string GetTwitterUserId ()
        { 
            return parameters.TwitterUserId; 
        }
        public string GetUserEmail () //special
        {
            return (string)GetLocalSetting(SETTINGS_USEREMAIL_KEY);
        }
        public string GetUserId () //special
        {
            return (string)GetLocalSetting(SETTINGS_USERID_KEY);
        }
        public string GetUserName () //special
        {
            return (string)GetLocalSetting(SETTINGS_USERNAME_KEY);
        }


        //////////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////////
        /*---------------------------Setters----------------------------*/
        //////////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////////

        public void SetAge(int age)
        {
            parameters.Age = age;
        }
        public void SetAllowDuplicates(bool allowDuplicates)
        {
            parameters.AllowDuplicates = allowDuplicates;
        }
        public void SetAltitude(double altitude)
        {
            parameters.Altitude = altitude;
        }
        public void SetAppAdTracking(bool appAdTracking)
        {
            parameters.AppAdTracking = appAdTracking;
        }
        public void SetAppName(string appName)
        {
            parameters.AppName = appName;
        }
        public void SetAppVersion(string appVersion)
        {
            parameters.AppVersion = appVersion;
        }
        public void SetASHWID (string ASHWID)
        { 
            parameters.ASHWID = ASHWID;
        }
        public void SetDebugMode(bool debugMode)
        {
            parameters.DebugMode = debugMode;
        }
        public void SetEventContentType(string eventContentType)
        {
            parameters.EventContentType = eventContentType;
        }
        public void SetEventContentId(string eventContentId)
        {
            parameters.EventContentId = eventContentId;
        }
        public void SetEventLevel(int eventLevel)
        {
            parameters.EventLevel = eventLevel;
        }
        public void SetEventQuantity(int eventQuantity)
        {
            parameters.EventQuantity = eventQuantity;
        }
        public void SetEventSearchString(string eventSearchString)
        {
            parameters.EventSearchString = eventSearchString;
        }
        public void SetEventRating(double eventRating)
        {
            parameters.EventRating = eventRating;
        }
        public void SetEventDate1(System.Nullable<DateTime> dateTime1)
        {
            parameters.EventDate1 = dateTime1;
        }
        public void SetEventDate2(System.Nullable<DateTime> dateTime2)
        {
            parameters.EventDate2 = dateTime2;
        }
        public void SetEventAttribute1(string eventAttribute1)
        {
            parameters.EventAttribute1 = eventAttribute1;
        }
        public void SetEventAttribute2(string eventAttribute2)
        {
            parameters.EventAttribute2 = eventAttribute2;
        }
        public void SetEventAttribute3(string eventAttribute3)
        {
            parameters.EventAttribute3 = eventAttribute3;
        }
        public void SetEventAttribute4(string eventAttribute4)
        {
            parameters.EventAttribute4 = eventAttribute4;
        }
        public void SetEventAttribute5(string eventAttribute5)
        {
            parameters.EventAttribute5 = eventAttribute5;
        }
        public void SetExistingUser(bool existingUser)
        {
            parameters.ExistingUser = existingUser;
        }
        public void SetFacebookUserId(string facebookUserId)
        {
            parameters.FacebookUserId = facebookUserId;
        }
        public void SetGender(MATGender gender)
        {
            parameters.Gender = gender;
        }
        public void SetGoogleUserId(string googleUserId)
        {
            parameters.GoogleUserId = googleUserId;
        }
        public void SetIsPayingUser(bool isPayingUser) //special
        {
            parameters.IsPayingUser = isPayingUser;
            SaveLocalSetting(SETTINGS_IS_PAYING_USER_KEY, isPayingUser);
        }
        public void SetLastOpenLogId(string lastOpenLogId) //special
        {
            parameters.LastOpenLogId = lastOpenLogId;
            SaveLocalSetting(SETTINGS_MATLASTOPENLOGID_KEY, lastOpenLogId);
        }
        public void SetLatitude(double latitude) 
        {
            parameters.Latitude = latitude;
        }
        public void SetLongitude(double longitude)
        {
            parameters.Longitude = longitude;
        }
        public void SetMatId(string matId) 
        {
            parameters.MatId = matId;
        }
        public void SetMatTestRequest(MATTestRequest matTestRequest)
        {
            parameters.matRequest = matTestRequest;
        }
        public void SetOpenLogId(string openLogId) //special
        {
            parameters.OpenLogId = openLogId;
            SaveLocalSetting(SETTINGS_MATOPENLOGID_KEY, openLogId);
        }
        public void SetPackageName(string packageName)
        {
            parameters.PackageName = packageName;
        }
        public void SetTwitterUserId(string twitterUserId)
        {
            parameters.TwitterUserId = twitterUserId;
        }
        public void SetUserEmail(string userEmail) //special
        {
            parameters.UserEmail = userEmail;
            SaveLocalSetting(SETTINGS_USEREMAIL_KEY, userEmail);
        }
        public void SetUserId(string userId) //special
        {
            parameters.UserId = userId;
            SaveLocalSetting(SETTINGS_USERID_KEY, userId);
        }
        public void SetUserName(string userName) //special
        {
            parameters.UserName = userName;
            SaveLocalSetting(SETTINGS_USERNAME_KEY, userName);
        }
        public void SetMATResponse(MATResponse response)
        {
            parameters.SetMATResponse(response);
        }
        protected internal void SetIsTestingOffline(bool isTestingOffline) 
        {
            parameters.IsTestingOffline = isTestingOffline;
        }
    }
}
