using System;
using System.IO.IsolatedStorage;
using System.Xml.Linq;
using System.Text.RegularExpressions;
using Microsoft.Phone.Info;
using Microsoft.Phone.Net.NetworkInformation;
using System.Windows;
using System.Diagnostics;

namespace MobileAppTracking
{
    public class MATParameters
    {
        internal MATParameters()
        {
        }
        //Initialize the default starting properties. Should only be called once by MobileAppTracker.
        internal MATParameters(string advId, string advKey) 
        {
            // Initialize Parameters
            this.advertiserId = advId;
            this.advertiserKey = advKey;

            matResponse = null;

            this.AllowDuplicates = false;
            this.DebugMode = false;
            this.ExistingUser = false;
            this.AppAdTracking = true;
            this.Gender = MATGender.NONE;

            // Get Windows AID through Reflection if app on WP8.1 device
            var type = Type.GetType("Windows.System.UserProfile.AdvertisingManager, Windows, Version=255.255.255.255, Culture=neutral, PublicKeyToken=null, ContentType=WindowsRuntime");
            this.WindowsAid = type != null ? (string)type.GetProperty("AdvertisingId").GetValue(null, null) : null;

            XElement app = XDocument.Load("WMAppManifest.xml").Root.Element("App");
            this.AppName = GetValue(app, "Title");
            this.AppVersion = GetValue(app, "Version");

            string productId = GetValue(app, "ProductID");
            if (productId == null)
            {
                // TODO: figure out what Win10 did to the ProductID
            }
            else
            {
                this.PackageName = Regex.Match(productId, "(?<={).*(?=})").Value;
            }

            byte[] deviceUniqueId = (byte[])DeviceExtendedProperties.GetValue("DeviceUniqueId");
            this.DeviceUniqueId = Convert.ToBase64String(deviceUniqueId);
            this.DeviceBrand = DeviceStatus.DeviceManufacturer;
            this.DeviceModel = DeviceStatus.DeviceName;
            this.DeviceCarrier = DeviceNetworkInformation.CellularMobileOperator;

            Version version = Environment.OSVersion.Version;
            this.OSVersion = String.Format("{0}.{1}.{2}.{3}", version.Major, version.Minor, version.Build, version.Revision);
            this.DeviceScreenSize = GetScreenRes();

            // Check if we can restore existing MAT ID or should generate new one
            if (IsolatedStorageSettings.ApplicationSettings.Contains(MATConstants.SETTINGS_MATID_KEY))
            {
                this.MatId = (string)IsolatedStorageSettings.ApplicationSettings[MATConstants.SETTINGS_MATID_KEY];
            }
            else // Don't have MAT ID, generate new guid
            {
                this.MatId = System.Guid.NewGuid().ToString();
                SaveLocalSetting(MATConstants.SETTINGS_MATID_KEY, this.MatId);
            }

            // Get saved values from LocalSettings
            if (GetLocalSetting(MATConstants.SETTINGS_PHONENUMBER_KEY) != null)
            {
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

        internal string advertiserId;
        internal string advertiserKey;

        internal MATResponse matResponse;
        protected internal MATTestRequest matRequest;

        internal int Age { get; set; }
        internal bool AllowDuplicates { get; set; }
        internal double Altitude { get; set; }
        internal bool AppAdTracking { get; set; }
        internal string AppName { get; set; } //getter, not setter
        internal string AppVersion { get; set; } //getter, not setter
        internal bool DebugMode { get; set; } 
        internal string DeviceBrand { get; set; } //getter, not setter
        internal string DeviceCarrier { get; set; } //getter, not setter
        internal string DeviceModel { get; set; } //getter, not setter
        internal string DeviceUniqueId { get; set; } //getter, not setter
        internal string DeviceScreenSize { get; set; } //getter, not setter
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
        internal bool IsPayingUser
        {
            get
            {
                if (GetLocalSetting(MATConstants.SETTINGS_IS_PAYING_USER_KEY) != null)
                    return (bool)GetLocalSetting(MATConstants.SETTINGS_IS_PAYING_USER_KEY);
                return false;
            }
            set
            {
                SaveLocalSetting(MATConstants.SETTINGS_IS_PAYING_USER_KEY, value);
            }
        }
        internal string LastOpenLogId
        {
            get
            {
                if (GetLocalSetting(MATConstants.SETTINGS_MATLASTOPENLOGID_KEY) != null)
                    return (string)GetLocalSetting(MATConstants.SETTINGS_MATLASTOPENLOGID_KEY);
                return null;
            }
            set
            {
                SaveLocalSetting(MATConstants.SETTINGS_MATLASTOPENLOGID_KEY, value);
            }
        }
        internal double Latitude { get; set; }
        internal double Longitude { get; set; }
        internal string MatId { get; set; }
        internal string OpenLogId
        {
            get
            {
                if (GetLocalSetting(MATConstants.SETTINGS_MATOPENLOGID_KEY) != null)
                    return (string)GetLocalSetting(MATConstants.SETTINGS_MATOPENLOGID_KEY);
                return null;
            }
            set
            {
                SaveLocalSetting(MATConstants.SETTINGS_MATOPENLOGID_KEY, value);
            }
        }
        internal string OSVersion { get; set; }
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
        internal string UserEmail
        {
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
        internal string UserId
        {
            get
            {
                return (string)GetLocalSetting(MATConstants.SETTINGS_USERID_KEY);
            }
            set
            {
                SaveLocalSetting(MATConstants.SETTINGS_USERID_KEY, value);
            }
        }
        internal string UserName
        {
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
            IsolatedStorageSettings.ApplicationSettings[key] = value;
            IsolatedStorageSettings.ApplicationSettings.Save();
        }

        // Helper function to get value from ApplicationSettings
        private object GetLocalSetting(string key)
        {
            if (IsolatedStorageSettings.ApplicationSettings.Contains(key))
                return IsolatedStorageSettings.ApplicationSettings[key];

            return null;
        }

        private static string GetValue(XElement app, string attrName)
        {
            XAttribute at = app.Attribute(attrName);
            return at != null ? at.Value : null;
        }

        private string GetScreenRes()
        {
            Size screenRes;
            try
            {
                screenRes = (Size)DeviceExtendedProperties.GetValue("PhysicalScreenResolution");
                return "" + screenRes.Width + "x" + screenRes.Height;
            }
            catch (Exception e)
            {
                Debug.WriteLine("Could not retrieve screen info: " + e);
                return "Unknown";
            }
        }

        public MATParameters Copy()
        {
            MATParameters copy = new MATParameters();

            copy.advertiserId = this.advertiserId;
            copy.advertiserKey = this.advertiserKey;
            copy.matRequest = this.matRequest; //Make this a hard copy

            copy.Age = this.Age;
            copy.AllowDuplicates = this.AllowDuplicates;
            copy.Altitude = this.Altitude;
            copy.AppAdTracking = this.AppAdTracking;
            copy.AppName = this.AppName;
            copy.AppVersion = this.AppVersion;
            copy.DebugMode = this.DebugMode;
            copy.DeviceBrand = this.DeviceBrand;
            copy.DeviceCarrier = this.DeviceCarrier;
            copy.DeviceModel = this.DeviceModel;
            copy.DeviceUniqueId = this.DeviceUniqueId;
            copy.DeviceScreenSize = this.DeviceScreenSize;
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
            copy.OSVersion = this.OSVersion;
            copy.PackageName = this.PackageName;
            copy.PhoneNumber = this.PhoneNumber;
            copy.TwitterUserId = this.TwitterUserId;
            copy.UserEmail = this.UserEmail;
            copy.UserEmailMd5 = this.UserEmailMd5;
            copy.UserEmailSha1 = this.UserEmailSha1;
            copy.UserEmailSha256 = this.UserEmailSha256;
            copy.UserId = this.UserId;
            copy.UserName = this.UserName;
            copy.UserNameMd5 = this.UserNameMd5;
            copy.UserNameSha1 = this.UserNameSha1;
            copy.UserNameSha256 = this.UserNameSha256;
            copy.WindowsAid = this.WindowsAid;

            return copy;
        }
   }
}
