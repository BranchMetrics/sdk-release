using System;
using System.Collections.Generic;
using System.Diagnostics;
using Windows.Networking.Connectivity;
using System.Threading.Tasks;

namespace MobileAppTracking
{
    
    public class MATEventQueue
    {
        protected internal MATParameters parameters;
        private readonly Object syncLock;
        
        protected internal MATEventQueue(MATParameters parameters)
        {
            this.parameters = parameters;
            syncLock = new Object();
        }

        protected internal MATEventQueue() 
        {
            syncLock = new Object();
        }

        protected internal int GetQueueSize()
        {
            // Get current size of queue if exists
            if (GetLocalSetting(MATConstants.SETTINGS_MATEVENTQUEUESIZE_KEY) != null)
                return (int)GetLocalSetting(MATConstants.SETTINGS_MATEVENTQUEUESIZE_KEY);

            return 0;
        }

        // Add a url to event queue to send later
        protected internal void AddToQueue(Object url, Object attempt)
        {
            lock (syncLock)
            {
                int eventQueueSize = GetQueueSize();

                // Save url as value for key "mat_event_queue_(index)"
                string eventQueueKey = MATConstants.SETTINGS_MATEVENTQUEUE_KEY + "_" + eventQueueSize.ToString();
                string eventQueueAttempt = MATConstants.SETTINGS_MATEVENTQUEUE_ATTEMPT_KEY + "_" + eventQueueSize.ToString();
                SaveLocalSetting(eventQueueKey, url);
                SaveLocalSetting(eventQueueAttempt, (int)attempt); //increment attempt number by one
                eventQueueSize++;
                SaveLocalSetting(MATConstants.SETTINGS_MATEVENTQUEUESIZE_KEY, eventQueueSize);
            }
        }

        protected internal void RemoveFromQueue(string key)
        {
            SaveLocalSetting(MATConstants.SETTINGS_MATEVENTQUEUESIZE_KEY, GetQueueSize() - 1);
            string eventQueueKey = MATConstants.SETTINGS_MATEVENTQUEUE_KEY + "_" + key.ToString();
            string eventqueueAttemptKey = MATConstants.SETTINGS_MATEVENTQUEUE_ATTEMPT_KEY + "_" + key.ToString();
            parameters.localSettings.Values.Remove(eventQueueKey);
            parameters.localSettings.Values.Remove(eventqueueAttemptKey);
        }

        // Add a url to event queue to send later
        internal void ProcessTrackingRequest(string action, string eventName, double revenue, string currency, string refId, List<MATEventItem> eventItems, MATParameters paramCopy)
        {
            Debug.WriteLine("Processing tracking request");
            lock (syncLock)
            {
                Task.Factory.StartNew(() =>
                {
                    DumpQueue();
                    string url = MATUrlBuilder.BuildUrl(action, eventName, revenue, currency, refId, eventItems, paramCopy);
                    AddToQueue(url, 0);
                    DumpQueue();
                });
           }

        }

        // Send all queued requests
        protected internal void DumpQueue()
        {
            // Check for internet connectivity and return immediately if none found
            if (!IsOnline() || parameters.IsTestingOffline)
                return;

            lock (syncLock)
            {
                int eventQueueSize = GetQueueSize();
                if (eventQueueSize > 0)
                {
                    for (int i = 0; i < eventQueueSize; i++)
                    {
                        string eventQueueKey = MATConstants.SETTINGS_MATEVENTQUEUE_KEY + "_" + i.ToString();
                        string eventQueueAttemptKey = MATConstants.SETTINGS_MATEVENTQUEUE_ATTEMPT_KEY + "_" + i.ToString();
                        if (parameters.localSettings.Values.ContainsKey(eventQueueKey))
                        {
                            string url = (string)parameters.localSettings.Values[eventQueueKey];
                            int urlAttempt = (int)parameters.localSettings.Values[eventQueueAttemptKey];
                            if (parameters.DebugMode)
                                Debug.WriteLine("Sending MAT event to server...");
                            MATUrlRequester urlRequester = new MATUrlRequester(parameters, this);
                            urlRequester.SendRequest(url, urlAttempt);
                            if (parameters.DebugMode)
                                Debug.WriteLine("MAT request sent");
                            // Decrement queue size
                            SaveLocalSetting(MATConstants.SETTINGS_MATEVENTQUEUESIZE_KEY, (int)parameters.localSettings.Values[MATConstants.SETTINGS_MATEVENTQUEUESIZE_KEY] - 1);
                        }
                    }
                }
            }
        }

        public virtual bool IsOnline()
        {
            // Whether we have internet connectivity or not
            ConnectionProfile profile = NetworkInformation.GetInternetConnectionProfile();
            return (profile != null && profile.GetNetworkConnectivityLevel() >= NetworkConnectivityLevel.InternetAccess);
        }
        
        // Helper function to get value from ApplicationSettings
        private object GetLocalSetting(string key)
        {
            if (parameters.localSettings.Values.ContainsKey(key))
                return parameters.localSettings.Values[key];

            return null;
        }

        // Helper function to save key-value pair to ApplicationSettings
        private void SaveLocalSetting(string key, Object value)
        {
            parameters.localSettings.Values[key] = value;
        }
    }
}
