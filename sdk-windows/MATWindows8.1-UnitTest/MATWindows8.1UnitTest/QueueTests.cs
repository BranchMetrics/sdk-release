using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.VisualStudio.TestPlatform.UnitTestFramework;

using MobileAppTracking;
using System.Diagnostics;

namespace MATWindows81UnitTest
{
    [TestClass]
    public class QueueTests : MATUnitTest, MATResponse
    {
        [TestCleanup]
        public void Teardown()
        {
            ClearQueue();
        }

        

        [TestMethod]
        public async Task OfflineRequestQueuedTest()
        {
            SetOnline(false);
            MATTestWrapper.Instance.MeasureAction("offlineEvent");

            await Task.Delay(TimeSpan.FromSeconds(5));

            Debug.WriteLine("queueSize is " + MATTestWrapper.Instance.GetQueueSize());
            Assert.IsTrue(MATTestWrapper.Instance.GetQueueSize() == 1);
        }

        [TestMethod]
        public async Task OfflineRequestRetryTest()
        {
            SetOnline(false);
            MATTestWrapper.Instance.MeasureAction("offlineEvent");

            await Task.Delay(TimeSpan.FromSeconds(5));

            Assert.IsTrue(MATTestWrapper.Instance.GetQueueSize() == 1);

            SetOnline(true);
            MATTestWrapper.Instance.MeasureAction("offlineEvent2");

            await Task.Delay(TimeSpan.FromSeconds(5));

            Assert.IsTrue(MATTestWrapper.Instance.GetQueueSize() == 0);
        }

        [TestMethod]
        public async Task Queue2Test()
        {
            MATTestParams.Sleep(2000);
            SetOnline(false);
            MATTestWrapper.Instance.MeasureAction("offlineEvent");
            MATTestWrapper.Instance.MeasureAction("offlineEvent2");

            await Task.Delay(TimeSpan.FromSeconds(5));

            Assert.IsTrue(MATTestWrapper.Instance.GetQueueSize() == 2);
        }

        [TestMethod]
        public void Queue2Retry()
        {
            MATTestParams.Sleep(2000);
            SetOnline(false);
            MATTestWrapper.Instance.MeasureAction("offlineEvent");
            MATTestWrapper.Instance.MeasureAction("offlineEvent2");

            MATTestParams.Sleep(5000);

            Assert.IsTrue(MATTestWrapper.Instance.GetQueueSize() == 2);

            SetOnline(true);
            MATTestWrapper.Instance.MeasureAction("triggerDump");

            MATTestParams.Sleep(5000);

            Assert.IsTrue(MATTestWrapper.Instance.GetQueueSize() == 0);
        }

        public void ClearQueue()
        {
            for (int i = MATTestWrapper.Instance.GetQueueSize() - 1; i >= 0; i--)
            {
                MATTestWrapper.Instance.RemoveFromQueue(i.ToString());
            }
        }

        public void SetOnline(bool online)
        {
            MATTestWrapper.Instance.SetIsTestingOfflineBehavior(!online);
            //this.online = online;
        }

        public void EnqueuedActionWithRefId(string refId)
        {
        }

        public void DidSucceedWithData(string response)
        {
        }

        public void DidFailWithError(string error)
        {
        }
    }
}
