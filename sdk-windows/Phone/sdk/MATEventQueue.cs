using System.Collections.Generic;
using System.Diagnostics;
using Microsoft.Phone.Net.NetworkInformation;
using System.IO.IsolatedStorage;
using System.Threading;

namespace MobileAppTracking
{
    public class MATEventQueue
    {
        private const string SETTINGS_MATEVENTQUEUE_KEY = "mat_event_queue";

        private readonly object syncLock;
        Thread queueThread;

        Parameters parameters;

        internal MATEventQueue(Parameters parameters)
        {
            syncLock = new object();
            this.parameters = parameters;
        }

        // Add a url to event queue to send later
        internal void AddToQueue(MATUrlBuilder.URLInfo url) 
        {
            lock (syncLock)
            {
                if (queueThread == null || !queueThread.IsAlive)
                {
                    queueThread = new Thread(delegate() //Start on separate thread to avoid UI slowdown
                    {
                        List<MATUrlBuilder.URLInfo> eventQueue;
                        // Get existing event queue or create new one
                        if (IsolatedStorageSettings.ApplicationSettings.Contains(SETTINGS_MATEVENTQUEUE_KEY) &&
                            IsolatedStorageSettings.ApplicationSettings[SETTINGS_MATEVENTQUEUE_KEY].GetType() == typeof(List<MATUrlBuilder.URLInfo>))
                        {
                            eventQueue = (List<MATUrlBuilder.URLInfo>)IsolatedStorageSettings.ApplicationSettings[SETTINGS_MATEVENTQUEUE_KEY];
                        }
                        else // No existing queue, create
                        {
                            IsolatedStorageSettings.ApplicationSettings.Remove(SETTINGS_MATEVENTQUEUE_KEY);
                            eventQueue = new List<MATUrlBuilder.URLInfo>();
                        }

                        eventQueue.Add(url);
                        SaveLocalSetting(SETTINGS_MATEVENTQUEUE_KEY, eventQueue);
                    });
                    queueThread.Start();
                }
            }
        }

        // Send all queued requests
        internal void DumpQueue() 
        {
            // Check for internet connectivity and return immediately if none found
            if (!DeviceNetworkInformation.IsNetworkAvailable)
                return;

            // Get existing event queue
            if (IsolatedStorageSettings.ApplicationSettings.Contains(SETTINGS_MATEVENTQUEUE_KEY) &&
                IsolatedStorageSettings.ApplicationSettings[SETTINGS_MATEVENTQUEUE_KEY].GetType() == typeof(List<MATUrlBuilder.URLInfo>)) //This only needs to be entered if a request was previously added to the queue
            {
                List<MATUrlBuilder.URLInfo> eventQueue = (List<MATUrlBuilder.URLInfo>)IsolatedStorageSettings.ApplicationSettings[SETTINGS_MATEVENTQUEUE_KEY];
                List<MATUrlBuilder.URLInfo> sentEvents = new List<MATUrlBuilder.URLInfo>();

                if (eventQueue.Count == 0)
                    return;

                foreach (MATUrlBuilder.URLInfo url in eventQueue)
                {
                    if (parameters.DebugMode)
                        Debug.WriteLine("Sending MAT event to server...");
                    MATUrlRequester urlRequester = new MATUrlRequester(parameters, this); //Individual fields are required for each async request
                    urlRequester.SendRequest(url);
                    // Build list of urls to remove
                    sentEvents.Add(url);
                    if (parameters.DebugMode)
                        Debug.WriteLine("MAT request sent");
                }
                // Remove all the urls we sent so collection is not modified in loop
                foreach (MATUrlBuilder.URLInfo url in sentEvents)
                {
                    eventQueue.Remove(url);
                }
                SaveLocalSetting(SETTINGS_MATEVENTQUEUE_KEY, eventQueue);
            }
        }

        // Helper function to save key-value pair to ApplicationSettings
        private void SaveLocalSetting(string key, object value)
        {
            IsolatedStorageSettings.ApplicationSettings[key] = value;
            IsolatedStorageSettings.ApplicationSettings.Save();
        }

        internal void ProcessTrackingRequest(string action, string eventName, double revenue, string currency, string refId, List<MATEventItem> eventItems, Parameters copy)
        {
            lock (syncLock)
            {
                if (queueThread == null || !queueThread.IsAlive)
                {
                    queueThread = new Thread(delegate() //Start on separate thread to avoid slowdown
                    {
                        DumpQueue(); //Clear anything from the last dump
                        List<MATUrlBuilder.URLInfo> eventQueue;
                        // Get existing event queue or create new one
                        if (IsolatedStorageSettings.ApplicationSettings.Contains(SETTINGS_MATEVENTQUEUE_KEY) &&
                            IsolatedStorageSettings.ApplicationSettings[SETTINGS_MATEVENTQUEUE_KEY].GetType() == typeof(List<MATUrlBuilder.URLInfo>))
                        {
                            eventQueue = (List<MATUrlBuilder.URLInfo>)IsolatedStorageSettings.ApplicationSettings[SETTINGS_MATEVENTQUEUE_KEY];
                        }
                        else // No existing queue, create
                        {
                            IsolatedStorageSettings.ApplicationSettings.Remove(SETTINGS_MATEVENTQUEUE_KEY);
                            eventQueue = new List<MATUrlBuilder.URLInfo>();
                        }

                        MATUrlBuilder.URLInfo url = MATUrlBuilder.BuildUrl(action, eventName, revenue, currency, refId, eventItems, copy);
                        eventQueue.Add(url);
                        SaveLocalSetting(SETTINGS_MATEVENTQUEUE_KEY, eventQueue);
                        
                        if (parameters.matResponse != null)
                            parameters.matResponse.EnqueuedActionWithRefId(refId); 
                        
                        DumpQueue();
                    });
                    queueThread.Start();
                }
            }
        }
    }
}
