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
    public class ParametersTest : MATUnitTest
    {

        [TestMethod]
        public void ConstructorTest()
        {
            Assert.IsNotNull(MATTestWrapper.Instance);
        }

        [TestMethod]
        public void TestAgeValid()
        {
            int age = 35;
            string expectedAge = age.ToString();

            MATTestWrapper.Instance.SetAge(age);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);
            
            AssertKeyValue("age", expectedAge);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestAgeYoung()
        {
            int age = 6;
            string expectedAge = age.ToString();

            MATTestWrapper.Instance.SetAge(age);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("age", expectedAge);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestAgeOld()
        {
            int age = 65536;
            string expectedAge = age.ToString();

            MATTestWrapper.Instance.SetAge(age);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("age", expectedAge);

            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestAgeZero()
        {
            int age = 0;
            string expectedAge = age.ToString();

            MATTestWrapper.Instance.SetAge(age);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertNoValueForKey("age");
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestAgeNegative()
        {
            int age = -304;
            string expectedAge = age.ToString();

            MATTestWrapper.Instance.SetAge(age);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertNoValueForKey("age");
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestAltitudeValid()
        {
            double altitude = 43;
            string expectedAltitude = altitude.ToString();

            MATTestWrapper.Instance.SetAltitude(altitude);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("altitude", expectedAltitude);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestAltitudeZero()
        {
            double altitude = 0;
            string expectedAltitude = altitude.ToString();

            MATTestWrapper.Instance.SetAltitude(altitude);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("altitude", expectedAltitude);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestAltitudeVeryLarge()
        {
            double altitude = 65536;
            string expectedAltitude = altitude.ToString();

            MATTestWrapper.Instance.SetAltitude(altitude);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("altitude", expectedAltitude);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestAltitudeVerySmall()
        {
            double altitude = -6701;
            string expectedAltitude = altitude.ToString();

            MATTestWrapper.Instance.SetAltitude(altitude);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("altitude", expectedAltitude);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestAppAdTrackingFalse()
        {
            MATTestWrapper.Instance.SetAppAdTracking(false);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("app_ad_tracking", "0");
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestAppAdTrackingTrue()
        {
            MATTestWrapper.Instance.SetAppAdTracking(true);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("app_ad_tracking", "1");
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestEventContentType()
        {
            string value = "testContentType";
            MATTestWrapper.Instance.SetEventContentType(value);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("content_type", value);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestEventContentId()
        {
            string value = "testContentId";
            MATTestWrapper.Instance.SetEventContentId(value);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("content_id", value);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestEventLevel()
        {
            int level = 13;
            MATTestWrapper.Instance.SetEventLevel(level);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("level", level.ToString());
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestEventQuantity()
        {
            int quantity = 63;
            MATTestWrapper.Instance.SetEventQuantity(quantity);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("quantity", quantity.ToString());
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestEventSearchString()
        {
            string value = "testSearchString";
            MATTestWrapper.Instance.SetEventSearchString(value);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("search_string", value);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestEventRating()
        {
            double rating = 3.14;
            MATTestWrapper.Instance.SetEventRating(rating);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("rating", rating.ToString());
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestEventDate1()
        {
            DateTime date = new DateTime(2014, 3, 31, 13, 13, 13);
            long expectedTime = MATTestWrapper.GetUnixTimestamp(date);

            MATTestWrapper.Instance.SetEventDate1(date);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("date1", expectedTime.ToString());
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestEventDate2()
        {
            DateTime date = new DateTime(2014, 1, 15, 14, 13, 12);
            long expectedTime = MATTestWrapper.GetUnixTimestamp(date);

            MATTestWrapper.Instance.SetEventDate2(date);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("date2", expectedTime.ToString());
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestEventParametersCleared()
        {
            MATTestWrapper.Instance.SetEventContentType("testContentType");
            MATTestWrapper.Instance.SetEventContentId("testContentId");
            MATTestWrapper.Instance.SetEventLevel(3);
            MATTestWrapper.Instance.SetEventQuantity(63);
            MATTestWrapper.Instance.SetEventSearchString("testSearchString");
            MATTestWrapper.Instance.SetEventRating(493.23);
            MATTestWrapper.Instance.SetEventDate1(new DateTime(2013, 3, 4, 5, 6, 7));
            MATTestWrapper.Instance.SetEventDate2(new DateTime(2013, 3, 4, 5, 6, 7));
            MATTestWrapper.Instance.SetEventAttribute1("attr1");
            MATTestWrapper.Instance.SetEventAttribute2("attr2");
            MATTestWrapper.Instance.SetEventAttribute3("attr3");
            MATTestWrapper.Instance.SetEventAttribute4("attr4");
            MATTestWrapper.Instance.SetEventAttribute5("attr5");

            MATTestWrapper.Instance.MeasureAction("purchase");
            MATTestParams.Sleep(3000);

            Assert.IsTrue(param.CheckDefaultValues());
            Assert.IsTrue(param.CheckKeyHasValue("content_type"));
            Assert.IsTrue(param.CheckKeyHasValue("content_id"));
            Assert.IsTrue(param.CheckKeyHasValue("level"));
            Assert.IsTrue(param.CheckKeyHasValue("quantity"));
            Assert.IsTrue(param.CheckKeyHasValue("search_string"));
            Assert.IsTrue(param.CheckKeyHasValue("rating"));
            Assert.IsTrue(param.CheckKeyHasValue("date1"));
            Assert.IsTrue(param.CheckKeyHasValue("date2"));
            Assert.IsTrue(param.CheckKeyHasValue("attribute_sub1"));
            Assert.IsTrue(param.CheckKeyHasValue("attribute_sub2"));
            Assert.IsTrue(param.CheckKeyHasValue("attribute_sub3"));
            Assert.IsTrue(param.CheckKeyHasValue("attribute_sub4"));
            Assert.IsTrue(param.CheckKeyHasValue("attribute_sub5"));

            param = new MATTestParams();
            MATTestWrapper.Instance.MeasureAction("purchase");
            MATTestParams.Sleep(3000);

            Assert.IsTrue(param.CheckDefaultValues());
            Assert.IsFalse(param.CheckKeyHasValue("content_type"));
            Assert.IsFalse(param.CheckKeyHasValue("content_id"));
            AssertKeyValue("level", 0.ToString());
            AssertKeyValue("quantity", 0.ToString());
            Assert.IsFalse(param.CheckKeyHasValue("search_string"));
            AssertKeyValue("rating", 0.ToString());
            Assert.IsFalse(param.CheckKeyHasValue("date1"));
            Assert.IsFalse(param.CheckKeyHasValue("date2"));
            Assert.IsFalse(param.CheckKeyHasValue("attribute_sub1"));
            Assert.IsFalse(param.CheckKeyHasValue("attribute_sub2"));
            Assert.IsFalse(param.CheckKeyHasValue("attribute_sub3"));
            Assert.IsFalse(param.CheckKeyHasValue("attribute_sub4"));
            Assert.IsFalse(param.CheckKeyHasValue("attribute_sub5"));
        }

        [TestMethod]
        public void TestEventAttribute1()
        {
            string attribute = "att1";
            MATTestWrapper.Instance.SetEventAttribute1(attribute);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("attribute_sub1", attribute);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestEventAttribute2()
        {
            string attribute = "att2";
            MATTestWrapper.Instance.SetEventAttribute2(attribute);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("attribute_sub2", attribute);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestEventAttribute3()
        {
            string attribute = "att3";
            MATTestWrapper.Instance.SetEventAttribute3(attribute);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("attribute_sub3", attribute);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestEventAttribute4()
        {
            string attribute = "att4";
            MATTestWrapper.Instance.SetEventAttribute4(attribute);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("attribute_sub4", attribute);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestEventAttribute5()
        {
            string attribute = "att5";
            MATTestWrapper.Instance.SetEventAttribute5(attribute);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("attribute_sub5", attribute);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestExistingUser()
        {
            MATTestWrapper.Instance.SetExistingUser(true);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("existing_user", "1");
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestFacebookUserId()
        {
            string userId = "fakeUserId";
            MATTestWrapper.Instance.SetFacebookUserId(userId);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("facebook_user_id", userId);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestGenderMale()
        {
            string expectedGender = ((int)MATGender.MALE).ToString();
            MATTestWrapper.Instance.SetGender(MATGender.MALE);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("gender", expectedGender);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestGenderFemale()
        {
            string expectedGender = ((int)MATGender.FEMALE).ToString();
            MATTestWrapper.Instance.SetGender(MATGender.FEMALE);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("gender", expectedGender);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestGenderNone()
        {
            string expectedGender = ((int)MATGender.NONE).ToString();
            MATTestWrapper.Instance.SetGender(MATGender.NONE);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertNoValueForKey("gender");
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestGoogleUserId()
        {
            string userId = "fakeUserId";
            MATTestWrapper.Instance.SetGoogleUserId(userId);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("google_user_id", userId);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestIsPayingUserFalse()
        {
            MATTestWrapper.Instance.SetIsPayingUser(false);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertNoValueForKey("is_paying_user");
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestIsPayingUserTrue()
        {
            MATTestWrapper.Instance.SetIsPayingUser(true);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("is_paying_user", "1");
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestLatitudeValidGtZero()
        {
            double latitude = 43;
            string expectedLatitude = latitude.ToString();
            MATTestWrapper.Instance.SetLatitude(latitude);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("latitude", expectedLatitude);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestLatitudeValidLtZero()
        {
            double latitude = -122;
            string expectedLatitude = latitude.ToString();
            MATTestWrapper.Instance.SetLatitude(latitude);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("latitude", expectedLatitude);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestLongitudeValidGtZero()
        {
            double longitude = 43;
            string expectedLongitude = longitude.ToString();
            MATTestWrapper.Instance.SetLongitude(longitude);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("longitude", expectedLongitude);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestLongitudeValidLtZero()
        {
            double longitude = -122;
            string expectedLongitude = longitude.ToString();
            MATTestWrapper.Instance.SetLongitude(longitude);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("longitude", expectedLongitude);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestPackageNameDefault()
        {
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("package_name", "com.mobileapptracking.windowsunittest");
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestPackageNameAlternate()
        {
            string packageName = "some.fake.package.name";
            MATTestWrapper.Instance.SetPackageName(packageName);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("package_name", packageName);
        }

        [TestMethod]
        public void TestTwitterUserId()
        {
            string userId = "fakeUserId";
            MATTestWrapper.Instance.SetTwitterUserId(userId);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("twitter_user_id", userId);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestUserEmail()
        {
            string email = "testUserEmail@test.com";
            MATTestWrapper.Instance.SetUserEmail(email);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("user_email", "testUserEmail@test.com");
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestUserId()
        {
            string userId = "testId";
            MATTestWrapper.Instance.SetUserId(userId);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("user_id", userId);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestUserName()
        {
            string username = "testUserName";
            MATTestWrapper.Instance.SetUserName(username);
            MATTestWrapper.Instance.MeasureAction("registration");
            MATTestParams.Sleep(3000);

            AssertKeyValue("user_name", username);
            Assert.IsTrue(param.CheckDefaultValues());
        }

        [TestMethod]
        public void TestUserIdsAutopopulate()
        {
            string userId = "aTestUserId";
            string userEmail = "aTestUserEmail";
            string userName = "aTestUserName";

            MATTestWrapper.Instance.SetUserId(userId);
            MATTestWrapper.Instance.SetUserEmail(userEmail);
            MATTestWrapper.Instance.SetUserName(userName);

            //MATTestWrapper.Instance. = new MATTestWrapper(MATTestConstants.ADVERTISER_ID, MATTestConstants.KEY); Singleton implementation doesn't allow for this
            MATTestWrapper.Instance.SetMatTestRequest(this);
            MATTestWrapper.Instance.SetPackageName(MATTestConstants.PACKAGE_NAME);

            MATTestWrapper.Instance.MeasureAction("purchase");
            MATTestParams.Sleep(3000);

            AssertKeyValue("user_id", userId);
            AssertKeyValue("user_email", userEmail);
            AssertKeyValue("user_name", userName);
            Assert.IsTrue(param.CheckDefaultValues());
        }
    }
}
