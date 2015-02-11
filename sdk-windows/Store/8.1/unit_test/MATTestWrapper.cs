using MobileAppTracking;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.Storage.Streams;
using Windows.System.Profile;

namespace MATWindows81UnitTest
{
    public class MATTestWrapper : MobileAppTracker //Used to access protected functions for testing
    {

        private static MATTestWrapper instance;

        //public MATEventQueueWrapper eventQueueWrapper;

        private MATTestWrapper() 
        { 
        }

        // Lazy instantiation singleton
        public new static MATTestWrapper Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = new MATTestWrapper();

                }
                return instance;
            }
        }

        public MATEventQueue GetEventQueue()
        {
            return eventQueue;
        }
        
        public void SetMATEventQueueWrapper()
        {
            eventQueue = new MATEventQueueWrapper(parameters);            
        }

        public void RemoveFromQueue(string key) 
        {
            ((MATEventQueueWrapper)eventQueue).RemoveFromQueueWrapper(key);
        }

        public int GetQueueSize() 
        {
            return ((MATEventQueueWrapper)eventQueue).GetQueueSizeFromWrapper();
        }

        public static long GetUnixTimestamp(DateTime? date)
        {
            return UnixTimestamp(date);
        }

        public void SetIsTestingOfflineBehavior(bool testingOffline)
        {
            SetIsTestingOffline(testingOffline);        
        }
    }

    public class MATEventQueueWrapper : MATEventQueue
    {
        public MATEventQueueWrapper(Parameters parameters) 
        {
            this.parameters = parameters;
        }

        public void RemoveFromQueueWrapper(string key)
        {
            this.RemoveFromQueue(key);
        }

        public int GetQueueSizeFromWrapper() 
        {
            return this.GetQueueSize();
        }
    } 
}
