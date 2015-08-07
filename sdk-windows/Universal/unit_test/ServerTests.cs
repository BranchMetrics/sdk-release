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
    public class ServerTests : MATUnitTest, MATResponse
    {
        private bool callSuccess;
        private bool callFailed;

        [TestInitialize]
        public override void Setup()
        {
            base.Setup();

            callSuccess = false;
            callFailed = false;

            MATTestWrapper.Instance.SetMATResponse(this);
        }

        [TestMethod]
        public async Task InstallTest()
        {
            MATTestWrapper.Instance.MeasureSession();

            await Task.Delay(TimeSpan.FromSeconds(5));

            Assert.IsTrue(callSuccess);
            Assert.IsFalse(callFailed);
        }

        [TestMethod]
        public async Task UpdateTest()
        {
            MATTestWrapper.Instance.SetExistingUser(true);
            MATTestWrapper.Instance.MeasureSession();

            await Task.Delay(TimeSpan.FromSeconds(5));

            Assert.IsTrue(callSuccess);
            Assert.IsFalse(callFailed);
        }

        [TestMethod]
        public async Task ActionTest()
        {
            MATTestWrapper.Instance.MeasureAction("testActionName");

            await Task.Delay(TimeSpan.FromSeconds(5));

            Assert.IsTrue(callSuccess);
            Assert.IsFalse(callFailed);
        }

        [TestMethod]
        public async Task ActionDuplicateTest()
        {
            MATTestWrapper.Instance.MeasureAction("testActionName");

            await Task.Delay(TimeSpan.FromSeconds(5));

            Assert.IsTrue(callSuccess);
            Assert.IsFalse(callFailed);

            callSuccess = false;

            MATTestWrapper.Instance.MeasureAction("testActionName");

            await Task.Delay(TimeSpan.FromSeconds(5));

            Assert.IsTrue(callSuccess);
            Assert.IsFalse(callFailed);
        }

        [TestMethod]
        public async Task ActionEventItemsTest()
        {
            MATEventItem item1 = new MATEventItem("testItem", 15, 1.05, 12.34, "attribute1", "attribute2", "attribute3", "attribute4", "attribute5");
            MATEventItem item2 = new MATEventItem("testItem2", 9, 2.99, 19.99, "sword1", "sword2", "sword3", "sword4", "sword5");
            List<MATEventItem> itemList = new List<MATEventItem>();
            itemList.Add(item1);
            itemList.Add(item2);

            MATTestWrapper.Instance.MeasureAction("testEventItems", 0, "USD", "1234", itemList);

            await Task.Delay(TimeSpan.FromSeconds(5));

            Assert.IsTrue(callSuccess);
            Assert.IsFalse(callFailed);
        }

        public void EnqueuedActionWithRefId(string refId)
        {
        }

        public void DidSucceedWithData(string response)
        {
            Debug.WriteLine("did succeed");
            callSuccess = true;
        }

        public void DidFailWithError(string error)
        {
            callFailed = true;
        }
    }
}
