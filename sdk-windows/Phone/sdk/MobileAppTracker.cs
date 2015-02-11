using System.Collections.Generic;
using System.IO.IsolatedStorage;

using Microsoft.Phone.Net.NetworkInformation;
using System;
using System.Threading;
using System.Diagnostics;


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
        private const string IV = "heF9BATUfWuISyO8";

        private Encryption urlEncrypter;
        private bool nextConnectIsFirst = true;

        private Parameters parameters;
        internal MATEventQueue eventQueue;

        // Helper function to get value from ApplicationSettings
        private object GetLocalSetting(string key)
        {
            if (IsolatedStorageSettings.ApplicationSettings.Contains(key))
                return IsolatedStorageSettings.ApplicationSettings[key];

            return null;
        }

        private MobileAppTracker()
        {
        }

        public void InitializeValues(string advId, string advKey)
        {
            urlEncrypter = new Encryption(advKey, IV);

            // Attached objects for attributes, queue functionality, and more
            this.parameters = new Parameters(advId, advKey);
            eventQueue = new MATEventQueue(parameters);

            // Add listener for network availability
            DeviceNetworkInformation.NetworkAvailabilityChanged += DeviceNetworkInformation_NetworkAvailabilityChanged;

            // Check for Internet connectivity and send queued requests 
            if (DeviceNetworkInformation.IsNetworkAvailable)
            {
                eventQueue.DumpQueue();
            }
        }

        // Lazy instantiation singleton
        public static MobileAppTracker Instance
        {
            get{
                if(instance == null){
                    instance = new MobileAppTracker();
                    
                }
                return instance;
            }
        }


        private void DeviceNetworkInformation_NetworkAvailabilityChanged(object sender, NetworkNotificationEventArgs e)
        {
            if (!DeviceNetworkInformation.IsNetworkAvailable)
            {
                nextConnectIsFirst = true;
            }
            else if (DeviceNetworkInformation.IsNetworkAvailable && nextConnectIsFirst)
            {
                // Connected to network, dump event queue if any
                nextConnectIsFirst = false;
                eventQueue.DumpQueue();
            }
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

            //Add to queue and process building operation in separate thread.
            //Copy is required because of async
            Parameters copy = parameters.Copy(); 
            eventQueue.ProcessTrackingRequest(action, eventName, revenue, currency, refId, eventItems, copy);

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
        public bool GetDebugMode () 
        {
            return parameters.DebugMode;
        }
        public string GetDeviceBrand () //only getter
        { 
            return parameters.DeviceBrand; 
        }
        public string GetDeviceCarrier () //only getter
        { 
            return parameters.DeviceCarrier; 
        }
        public string GetDeviceModel () //only getter
        { 
            return parameters.DeviceModel; 
        }
        public string GetDeviceUniqueId () //only getter
        { 
            return parameters.DeviceUniqueId; 
        }
        public string GetDeviceScreenSize () //only getter
        { 
            return parameters.DeviceScreenSize; 
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
            return parameters.IsPayingUser;
        }
        public string GetLastOpenLogId () //special
        {
            return parameters.LastOpenLogId;
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
            return parameters.OpenLogId; 
        }
        public string GetOSVersion () 
        { 
            return parameters.OSVersion; 
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
            return parameters.UserEmail;
        }
        public string GetUserId () //special
        {
            return parameters.UserId;
        }
        public string GetUserName () //special
        {
            return parameters.UserName;
        }
        public string GetWindowsAid()
        {
            return parameters.WindowsAid;
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
        }
        public void SetLastOpenLogId(string lastOpenLogId) //special
        {
            parameters.LastOpenLogId = lastOpenLogId;
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
        }
        public void SetOSVersion(string OSVersion)
        {
            parameters.OSVersion = OSVersion;
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
        }
        public void SetUserId(string userId) //special
        {
            parameters.UserId = userId;
        }
        public void SetUserName(string userName) //special
        {
        parameters.UserName = userName;
        }
        public void SetMATResponse(MATResponse response)
        {
            parameters.SetMATResponse(response);
        }
        public void SetWindowsAid(string windowsAid)
        {
            parameters.WindowsAid = windowsAid;
        }
    }
}
