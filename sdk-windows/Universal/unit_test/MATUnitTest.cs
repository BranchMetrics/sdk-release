using MobileAppTracking;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Microsoft.VisualStudio.TestPlatform.UnitTestFramework;
using System.Diagnostics;

namespace MATWindows81UnitTest
{
    public class MATUnitTest : MATTestRequest
    {
        protected MATTestParams param;

        [TestInitialize]
        public virtual void Setup()
        {
            MATTestWrapper.InitializeValues(MATTestConstants.ADVERTISER_ID, MATTestConstants.KEY);
            MATTestWrapper.Instance.SetMATEventQueueWrapper();
            MATTestWrapper.Instance.SetMatTestRequest(this);

            MATTestWrapper.Instance.SetAllowDuplicates(true);
            MATTestWrapper.Instance.SetDebugMode(true);
            MATTestWrapper.Instance.SetPackageName(MATTestConstants.PACKAGE_NAME);

            param = new MATTestParams();
        }

        public void AssertKeyValue(string key, string value)
        {
            Assert.IsTrue(value.Equals(param.ValueForKey(key)));
        }

        public void AssertNoValueForKey(string key)
        {
            Assert.IsFalse(param.CheckKeyHasValue(key));
        }

        public void ParamsToBeEncrypted(string data)
        {
            Assert.IsTrue(param.ExtractParamsString(data));
        }

        public void ConstructedRequest(string url)
        {
            Assert.IsTrue(param.ExtractParamsString(url));
        }
    }
}
