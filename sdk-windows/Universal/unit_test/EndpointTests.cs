using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.VisualStudio.TestPlatform.UnitTestFramework;

using MobileAppTracking;

namespace MATWindows81UnitTest
{
    [TestClass]
    public class EndpointTests : MATUnitTest
    {
        [TestMethod]
        public async Task InstallEndpointTest()
        {
            MATTestWrapper.Instance.MeasureSession();

            await Task.Delay(TimeSpan.FromSeconds(5));

            Assert.IsTrue(param.CheckDefaultValues());
            Assert.IsTrue(param.CheckActionIsSession());
        }

        [TestMethod]
        public async Task UpdateEndpointTest()
        {
            MATTestWrapper.Instance.SetExistingUser(true);
            MATTestWrapper.Instance.MeasureSession();

            await Task.Delay(TimeSpan.FromSeconds(5));

            Assert.IsTrue(param.CheckDefaultValues());
            Assert.IsTrue(param.CheckActionIsSession());
            Assert.IsTrue(param.CheckKeyIsEqualToValue("existing_user", "1"));
        }

        [TestMethod]
        public async Task ActionNameTest()
        {
            string eventName = "testEvent";
            MATTestWrapper.Instance.MeasureAction(eventName);

            await Task.Delay(TimeSpan.FromSeconds(5));

            Assert.IsTrue(param.CheckDefaultValues());
            Assert.IsTrue(param.CheckActionIsConversion());
            Assert.IsTrue(param.CheckKeyIsEqualToValue("site_event_name", eventName));
        }

        [TestMethod]
        public async Task EventItemsTest()
        {
            string eventName = "testEventItem";
            double revenue = 14.99;
            string currency = "USD";
            string refId = "1234";

            MATEventItem item1 = new MATEventItem("testItem", 15, 1.05, 12.34, "attribute1", "attribute2", "attribute3", "attribute4", "attribute5");
            MATEventItem item2 = new MATEventItem("testItem2", 9, 2.99, 19.99, "sword1", "sword2", "sword3", "sword4", "sword5");
            List<MATEventItem> itemList = new List<MATEventItem>();
            itemList.Add(item1);
            itemList.Add(item2);

            MATTestWrapper.Instance.MeasureAction(eventName, revenue, currency, refId, itemList);

            await Task.Delay(TimeSpan.FromSeconds(5));

            Assert.IsTrue(param.CheckDefaultValues());
            Assert.IsTrue(param.CheckActionIsConversion());
            Assert.IsTrue(param.CheckKeyIsEqualToValue("site_event_name", eventName));
            Assert.IsTrue(param.CheckKeyIsEqualToValue("revenue", revenue.ToString()));
            Assert.IsTrue(param.CheckKeyIsEqualToValue("currency_code", currency));
            Assert.IsTrue(param.CheckKeyIsEqualToValue("advertiser_ref_id", refId));
            Assert.IsTrue(param.CheckEventItems(itemList));

        }
    }
}
