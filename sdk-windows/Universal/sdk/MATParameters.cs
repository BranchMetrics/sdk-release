using System;
using System.Globalization;
using System.Xml.Linq;
using Windows.ApplicationModel;
using Windows.Security.ExchangeActiveSyncProvisioning;
using Windows.Storage;
using Windows.System.UserProfile;

namespace MobileAppTracking
{
    public class MATParameters
    {
        public MATParameters()
        {
            this.localSettings = ApplicationData.Current.LocalSettings;
        }

        // Initialize the default starting properties. Should only be called once by MobileAppTracker.
        public MATParameters(string advId, string advKey, byte[] bytes)
        {
            this.culture = new CultureInfo("en-US");

            this.advertiserId = advId;
            this.advertiserKey = advKey;

            this.localSettings = ApplicationData.Current.LocalSettings;

            this.urlEncrypter = new MATEncryption(advKey, MATConstants.IV);

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
            if (localSettings.Values.ContainsKey(MATConstants.SETTINGS_MATID_KEY))
            {
                this.MatId = (string)localSettings.Values[MATConstants.SETTINGS_MATID_KEY];
            }
            else // Don't have MAT ID, generate new guid
            {
                this.MatId = System.Guid.NewGuid().ToString();
                SaveLocalSetting(MATConstants.SETTINGS_MATID_KEY, this.MatId);
            }

            // Get saved values from LocalSettings
            if (GetLocalSetting(MATConstants.SETTINGS_PHONENUMBER_KEY) != null) {
                this.PhoneNumber = (string)GetLocalSetting(MATConstants.SETTINGS_PHONENUMBER_KEY);
                this.PhoneNumberMd5 = MATEncryption.Md5(this.PhoneNumber);
                this.PhoneNumberSha1 = MATEncryption.Sha1(this.PhoneNumber);
                this.PhoneNumberSha256 = MATEncryption.Sha256(this.PhoneNumber);
            }

            if (GetLocalSetting(MATConstants.SETTINGS_USEREMAIL_KEY) != null)
            {
                this.UserEmail = (string)GetLocalSetting(MATConstants.SETTINGS_USEREMAIL_KEY);
                this.UserEmailMd5 = MATEncryption.Md5(this.UserEmail);
                this.UserEmailSha1 = MATEncryption.Sha1(this.UserEmail);
                this.UserEmailSha256 = MATEncryption.Sha256(this.UserEmail);
            }

            this.UserId = (string)GetLocalSetting(MATConstants.SETTINGS_USERID_KEY);

            if (GetLocalSetting(MATConstants.SETTINGS_USERNAME_KEY) != null)
            {
                this.UserName = (string)GetLocalSetting(MATConstants.SETTINGS_USERNAME_KEY);
                this.UserNameMd5 = MATEncryption.Md5(this.UserName);
                this.UserNameSha1 = MATEncryption.Sha1(this.UserName);
                this.UserNameSha256 = MATEncryption.Sha256(this.UserName);
            }
        }

        internal ApplicationDataContainer localSettings;
        internal CultureInfo culture;
        internal MATEncryption urlEncrypter;

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
        internal string PhoneNumber
        {
            get
            {
                return (string)GetLocalSetting(MATConstants.SETTINGS_PHONENUMBER_KEY);
            }
            set
            {
                if (value != null)
                {
                    PhoneNumberMd5 = MATEncryption.Md5(value);
                    PhoneNumberSha1 = MATEncryption.Sha1(value);
                    PhoneNumberSha256 = MATEncryption.Sha256(value);
                    SaveLocalSetting(MATConstants.SETTINGS_PHONENUMBER_KEY, value);
                }
            }
        }
        internal string PhoneNumberMd5 { get; set; }
        internal string PhoneNumberSha1 { get; set; }
        internal string PhoneNumberSha256 { get; set; }
        internal string TwitterUserId { get; set; }
        internal string UserAgent { get; set; }
        internal string UserEmail {
            get
            {
                return (string)GetLocalSetting(MATConstants.SETTINGS_USEREMAIL_KEY);
            }
            set
            {
                if (value != null)
                {
                    UserEmailMd5 = MATEncryption.Md5(value);
                    UserEmailSha1 = MATEncryption.Sha1(value);
                    UserEmailSha256 = MATEncryption.Sha256(value);
                    SaveLocalSetting(MATConstants.SETTINGS_USEREMAIL_KEY, value);
                }
            }
        }
        internal string UserEmailMd5 { get; set; }
        internal string UserEmailSha1 { get; set; }
        internal string UserEmailSha256 { get; set; }
        internal string UserId { get; set; }
        internal string UserName {
            get
            {
                return (string)GetLocalSetting(MATConstants.SETTINGS_USERNAME_KEY);
            }
            set
            {
                if (value != null)
                {
                    UserNameMd5 = MATEncryption.Md5(value);
                    UserNameSha1 = MATEncryption.Sha1(value);
                    UserNameSha256 = MATEncryption.Sha256(value);
                    SaveLocalSetting(MATConstants.SETTINGS_USERNAME_KEY, value);
                }
            }
        }
        internal string UserNameMd5 { get; set; }
        internal string UserNameSha1 { get; set; }
        internal string UserNameSha256 { get; set; }
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

        // Reads app name from Package.appxmanifest
        private string GetAppName()
        {
            // 8.1 manifest
            string namespaceName8_1 = "http://schemas.microsoft.com/appx/2010/manifest";
            // 10 manifest
            string namespaceName10 = "http://schemas.microsoft.com/appx/manifest/foundation/windows10";

            XElement element = XDocument.Load("appxmanifest.xml").Root;
            try {
                // For Windows 8.1
                if (element.Element(XName.Get("Properties", namespaceName8_1)) != null) {
                    element = element.Element(XName.Get("Properties", namespaceName8_1));
                    element = element.Element(XName.Get("DisplayName", namespaceName8_1));
                }
                else
                {
                    // For Windows 10
                    element = element.Element(XName.Get("Properties", namespaceName10));
                    element = element.Element(XName.Get("DisplayName", namespaceName10));
                }
                return element.Value;
            }
            catch (Exception)
            {
                return "";
            }
        }

        internal bool IsTestingOffline = false;

        public MATParameters Copy()
        {
            MATParameters copy = new MATParameters();

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
            copy.PhoneNumber = this.PhoneNumber;
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