using System;
using System.Globalization;
using System.Xml.Linq;
using Windows.ApplicationModel;
using Windows.Security.ExchangeActiveSyncProvisioning;
using Windows.Storage;
using Windows.System.UserProfile;

namespace MobileAppTracking
{
    public class Parameters
    {
        private const string IV = "heF9BATUfWuISyO8";
        private const string SETTINGS_MATID_KEY = "mat_id";
        private const string SETTINGS_MATLASTOPENLOGID_KEY = "mat_last_open_log_id";
        private const string SETTINGS_MATOPENLOGID_KEY = "mat_open_log_id";
        private const string SETTINGS_IS_PAYING_USER_KEY = "mat_is_paying_user";
        private const string SETTINGS_USERID_KEY = "mat_user_id";
        private const string SETTINGS_USEREMAIL_KEY = "mat_user_email";
        private const string SETTINGS_USERNAME_KEY = "mat_user_name";

        public Parameters()
        {
        }

        // Initialize the default starting properties. Should only be called once by MobileAppTracker.
        public Parameters(string advId, string advKey, byte[] bytes)
        {

            this.culture = new CultureInfo("en-US");

            this.advertiserId = advId;
            this.advertiserKey = advKey;

            this.localSettings = ApplicationData.Current.LocalSettings;

            this.urlEncrypter = new Encryption(advKey, IV);

            this.matResponse = null;

            // Default values
            this.AllowDuplicates = false;
            this.DebugMode = false;
            this.ExistingUser = false;
            this.AppAdTracking = true;
            this.Gender = MATGender.NONE;

            this.WindowsAid = AdvertisingManager.AdvertisingId;

            // Get app name asynchronously from appxmanifest
            this.AppName = GetAppName();

            var version = Package.Current.Id.Version;
            this.AppVersion = String.Format("{0}.{1}.{2}.{3}", version.Major, version.Minor, version.Build, version.Revision);

            this.PackageName = Package.Current.Id.Name;

            // Get device info
            EasClientDeviceInformation info = new EasClientDeviceInformation();

            this.DeviceBrand = info.SystemManufacturer.ToString();
            this.DeviceModel = info.SystemProductName.ToString();
            this.DeviceType = info.OperatingSystem.ToString(); //Windows or WindowsPhone

            // Get ASHWID
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

        }

        internal ApplicationDataContainer localSettings;
        internal CultureInfo culture;
        internal Encryption urlEncrypter;

        internal string advertiserId;
        internal string advertiserKey;

        protected internal MATResponse matResponse;
        protected internal MATTestRequest matRequest;

        // MAT properties
        internal int Age { get; set; }
        internal bool AllowDuplicates { get; set; }
        internal double Altitude { get; set; }
        internal bool AppAdTracking { get; set; }
        internal string AppName { get; set; }
        internal string AppVersion { get; set; }
        internal string ASHWID { get; set; }
        internal bool DebugMode { get; set; }
        internal string DeviceModel { get; set; }
        internal string DeviceBrand { get; set; }
        internal string DeviceType { get; set; }
        internal string EventContentType { get; set; }
        internal string EventContentId { get; set; }
        internal int EventLevel { get; set; }
        internal int EventQuantity { get; set; }
        internal string EventSearchString { get; set; }
        internal double EventRating { get; set; }
        internal System.Nullable<DateTime> EventDate1 { get; set; }
        internal System.Nullable<DateTime> EventDate2 { get; set; }
        internal string EventAttribute1 { get; set; }
        internal string EventAttribute2 { get; set; }
        internal string EventAttribute3 { get; set; }
        internal string EventAttribute4 { get; set; }
        internal string EventAttribute5 { get; set; }
        internal bool ExistingUser { get; set; }
        internal string FacebookUserId { get; set; }
        internal MATGender Gender { get; set; }
        internal string GoogleUserId { get; set; }
        internal bool IsPayingUser { get; set; }
        internal string LastOpenLogId { get; set; }
        internal double Latitude { get; set; }
        internal double Longitude { get; set; }
        internal string MatId { get; set; }
        internal string OpenLogId { get; set; }
        internal string PackageName { get; set; }
        internal string TwitterUserId { get; set; }
        internal string UserAgent { get; set; }
        internal string UserEmail { get; set; }
        internal string UserId { get; set; }
        internal string UserName { get; set; }
        internal string WindowsAid { get; set; }
        

        internal void SetMATResponse(MATResponse response)
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
            if (this.localSettings.Values.ContainsKey(key))
                return this.localSettings.Values[key];

            return null;
        }


        private string GetAppName()
        {
            string namespaceName = "http://schemas.microsoft.com/appx/2010/manifest";
            XElement element = XDocument.Load("appxmanifest.xml").Root;
            element = element.Element(XName.Get("Properties", namespaceName));
            element = element.Element(XName.Get("DisplayName", namespaceName));
            return element.Value;
        }

        internal bool IsTestingOffline = false;

        public Parameters Copy()
        {
            Parameters copy = new Parameters();

            copy.advertiserId = this.advertiserId;
            copy.advertiserKey = this.advertiserKey;
            copy.culture = this.culture;
            copy.matRequest = this.matRequest; //Make this a hard copy
            copy.urlEncrypter = this.urlEncrypter;

            copy.Age = this.Age;
            copy.AllowDuplicates = this.AllowDuplicates;
            copy.Altitude = this.Altitude;
            copy.AppAdTracking = this.AppAdTracking;
            copy.AppName = this.AppName;
            copy.AppVersion = this.AppVersion;
            copy.ASHWID = this.ASHWID;
            copy.DebugMode = this.DebugMode;
            copy.DeviceBrand = this.DeviceBrand;
            copy.DeviceModel = this.DeviceModel;
            copy.DeviceType = this.DeviceType;
            copy.EventContentType = this.EventContentType;
            copy.EventContentId = this.EventContentId;
            copy.EventLevel = this.EventLevel;
            copy.EventQuantity = this.EventQuantity;
            copy.EventSearchString = this.EventSearchString;
            copy.EventRating = this.EventRating;
            copy.EventDate1 = this.EventDate1;
            copy.EventDate2 = this.EventDate2;
            copy.EventAttribute1 = this.EventAttribute1;
            copy.EventAttribute2 = this.EventAttribute2;
            copy.EventAttribute3 = this.EventAttribute3;
            copy.EventAttribute4 = this.EventAttribute4;
            copy.EventAttribute5 = this.EventAttribute5;
            copy.ExistingUser = this.ExistingUser;
            copy.FacebookUserId = this.FacebookUserId;
            copy.Gender = this.Gender;
            copy.GoogleUserId = this.GoogleUserId;
            copy.IsPayingUser = this.IsPayingUser;
            copy.LastOpenLogId = this.LastOpenLogId;
            copy.Latitude = this.Latitude;
            copy.Longitude = this.Longitude;
            copy.MatId = this.MatId;
            copy.OpenLogId = this.OpenLogId;
            copy.PackageName = this.PackageName;
            copy.TwitterUserId = this.TwitterUserId;
            copy.UserAgent = this.UserAgent;
            copy.UserEmail = this.UserEmail;
            copy.UserId = this.UserId;
            copy.UserName = this.UserName;
            copy.WindowsAid = this.WindowsAid;

            return copy;
        }
    }
}