package com.tune;

import android.Manifest.permission;
import android.support.test.rule.GrantPermissionRule;
import android.support.test.runner.AndroidJUnit4;

import com.tune.utils.TuneSharedPrefsDelegate;
import com.tune.utils.TuneStringUtils;
import com.tune.utils.TuneUtils;

import org.json.JSONArray;
import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.Arrays;
import java.util.Date;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static android.support.test.InstrumentationRegistry.getContext;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;


@RunWith(AndroidJUnit4.class)
public class ParametersTests extends TuneUnitTest {
    @Rule
    public GrantPermissionRule mRuntimePermissionRule = GrantPermissionRule.grant(permission.GET_ACCOUNTS);

    @Before
    public void setUp() throws Exception {
        super.setUp();

        tune.setOnline(false);
    }

    @After
    public void tearDown() throws Exception {
        tune.setOnline(true);

        super.tearDown();
    }

    // Provides a way to restart Tune in the middle of a unit test, so that we can test
    // the restart state of the Parameters.
    private void restartTune() throws Exception {
        tune.retainSharedPrefs(true);
        tearDown();
        setUp();
        tune.retainSharedPrefs(false);
        sleep(TuneTestConstants.PARAMTEST_SLEEP);
    }

    @Test
    public void testAgeValid() {
        final int age = 35;
        String expectedAge = Integer.toString(age);

        tune.setAge(age);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.AGE);

        assertEquals(age, tune.getAge());
    }

    @Test
    public void testAgeYoung() {
        final int age = 6;
        String expectedAge = Integer.toString(age);

        tune.setAge(age);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.AGE);
    }

    @Test
    public void testAgeOld() {
        final int age = 65536;
        String expectedAge = Integer.toString(age);

        tune.setAge(age);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.AGE);

        assertEquals(age, tune.getAge());
    }

    @Test
    public void testAgeZero() {
        final int age = 0;
        String expectedAge = Integer.toString(age);

        tune.setAge(age);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.AGE);

        assertEquals(age, tune.getAge());
    }

    @Test
    public void testAgeNegative() {
        final int age = -304;
        String expectedAge = Integer.toString(age);

        tune.setAge(age);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.AGE);

        assertEquals(age, tune.getAge());
    }

    @Test
    public void testAgeNull() {
        // don't set an age, the param will be null
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues() );
        assertNoValueForKey(TuneUrlKeys.AGE);
        assertEquals(0, tune.getAge());
    }

    @Test
    public void testAgeSetGet() {
        final int age = 99;
        tune.setAge(age);

        // Assert that there is nothing going asynchronous between calls
        assertEquals(age, tune.getAge());
    }

    @Test
    public void testAltitudeValid() {
        final double altitude = 43;
        String expectedAltitude = Double.toString( altitude );

        tune.setLocation(0, 0, altitude);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.ALTITUDE);

        assertEquals(altitude, tune.getLocation().getAltitude(), 0.0001);
    }

    @Test
    public void testAltitudeZero() {
        final double altitude = 0;
        String expectedAltitude = Double.toString( altitude );

        tune.setLocation(0, 0, altitude);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.ALTITUDE);

        assertEquals(altitude, tune.getLocation().getAltitude(), 0.0001);
    }

    @Test
    public void testAltitudeVeryLarge() {
        final double altitude = 65536;
        String expectedAltitude = Double.toString( altitude );

        tune.setLocation(0, 0, altitude);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification( TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.ALTITUDE);

        assertEquals(altitude, tune.getLocation().getAltitude(), 0.0001);
    }

    @Test
    public void testAltitudeVerySmall() {
        final double altitude = Double.MIN_VALUE;
        String expectedAltitude = Double.toString(altitude);

        tune.setLocation(0, 0, altitude);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.ALTITUDE);

        assertEquals(altitude, tune.getLocation().getAltitude(), 0.0001);
    }

    @Test
    public void testAndroidId() {
        final String androidId = "59a3747895bdb03d";

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        tune.setAndroidId(androidId);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.ANDROID_ID, androidId);
        assertEquals(androidId, tune.getAndroidId());

        // A side effect of setAndroidId() is to set the hash value as well
        assertEquals(tune.getTuneParams().getAndroidIdSha256(), TuneUtils.sha256(androidId));
    }

    @Test
    public void testAndroidIdNull() {
        sleep( TuneTestConstants.PARAMTEST_SLEEP );

        tune.setAndroidId(null);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey(TuneUrlKeys.ANDROID_ID);
        assertNull(tune.getAndroidId());
    }

    @Test
    public void testAndroidIdSha256() {
        final String androidIdSha256 = TuneUtils.sha256("59a3747895bdb03d");

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        tune.getTuneParams().setAndroidIdSha256(androidIdSha256);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.ANDROID_ID_SHA256, androidIdSha256);
    }

    /**
     * Test default COPPA scenario with neither age nor COPPA set.
     */
    @Test
    public void testCOPPA() {
        assertFalse(tune.isPrivacyProtectedDueToAge());
    }

    /**
     * Test age and COPPA interactions without specifically setting isCOPPA.
     */
    @Test
    public void testCOPPA_ageOnly() {
        final int youth = TuneConstants.COPPA_MINIMUM_AGE - 1;
        final int adult = 21;

        tune.setAge(youth);
        assertTrue(tune.isPrivacyProtectedDueToAge());

        tune.setAge(adult);
        assertFalse(tune.isPrivacyProtectedDueToAge());
    }

    /**
     * Test age and COPPA interactions without specifically setting Age.
     */
    @Test
    public void testCOPPA_Only() {
        assertTrue(tune.setPrivacyProtectedDueToAge(true));
        assertTrue(tune.isPrivacyProtectedDueToAge());

        assertTrue(tune.setPrivacyProtectedDueToAge(false));
        assertFalse(tune.isPrivacyProtectedDueToAge());
    }

    /**
     * Test age and COPPA interaction using setAge and setCOPPA, age set first.
     */
    @Test
    public void testCOPPA_ageBefore() {
        final int youth = TuneConstants.COPPA_MINIMUM_AGE - 1;

        // Set Age below COPPA boundary
        tune.setAge(youth);
        assertTrue(tune.isPrivacyProtectedDueToAge());          // This should succeed because youth

        assertTrue(tune.setPrivacyProtectedDueToAge(true));     // This should also succeed
        assertTrue(tune.isPrivacyProtectedDueToAge());

        assertFalse(tune.setPrivacyProtectedDueToAge(false));   // Can't turn off COPPA for youth
        assertTrue(tune.isPrivacyProtectedDueToAge());          // This should still be true
    }

    /**
     * Test age and COPPA interaction using setAge and setCOPPA, COPPA set first.
     */
    @Test
    public void testCOPPA_ageAfter() {
        final int adult = 21;

        // Set Age above COPPA boundary
        tune.setAge(adult);
        assertFalse(tune.isPrivacyProtectedDueToAge());         // This should fail because adult

        assertTrue(tune.setPrivacyProtectedDueToAge(true));     // This should actually succeed.  Age doesn't apply in this case
        assertTrue(tune.isPrivacyProtectedDueToAge());          // This should succeed because of the COPPA flag

        assertTrue(tune.setPrivacyProtectedDueToAge(false));    // This should also succeed
        assertFalse(tune.isPrivacyProtectedDueToAge());         // This should still fail because adult
    }

    /**
     * Additional test around setting Age after setting COPPA(true).
     */
    @Test
    public void testSetAge_afterCOPPA_true() {
        final int youth = TuneConstants.COPPA_MINIMUM_AGE - 1;
        final int adult = 21;

        tune.setPrivacyProtectedDueToAge(true);              // COPPA(true)
        assertTrue(tune.isPrivacyProtectedDueToAge());       // This should succeed even though age was never set

        tune.setAge(youth);
        assertTrue(tune.isPrivacyProtectedDueToAge());       // This should succeed regardless of age

        tune.setAge(adult);
        assertTrue(tune.isPrivacyProtectedDueToAge());       // This should succeed regardless of age
    }

    /**
     * Additional test around setting Age after setting COPPA(false).
     */
    @Test
    public void testSetAge_afterCOPPA_false() {
        final int youth = TuneConstants.COPPA_MINIMUM_AGE - 1;
        final int adult = 21;

        tune.setPrivacyProtectedDueToAge(false);             // COPPA(false)
        assertFalse(tune.isPrivacyProtectedDueToAge());      // This should be false because neither COPPA nor Age are an issue

        tune.setAge(youth);
        assertTrue(tune.isPrivacyProtectedDueToAge());       // This should succeed regardless of COPPA setting

        tune.setAge(adult);
        assertFalse(tune.isPrivacyProtectedDueToAge());      // This should be false because neither COPPA nor Age are an issue
    }

    @Test
    public void testIsCOPPA_True() {
        final int age = TuneConstants.COPPA_MINIMUM_AGE - 1;
        tune.setAge(age);

        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertKeyValue( TuneUrlKeys.IS_COPPA, TuneConstants.PREF_SET );
    }

    @Test
    public void testIsCOPPA_False() {
        final int age = TuneConstants.COPPA_MINIMUM_AGE + 1;
        tune.setAge(age);

        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertKeyValue( TuneUrlKeys.IS_COPPA, TuneConstants.PREF_UNSET );
    }

    @Test
    public void testIsCOPPA_AdTracking() {
        // Default test -- tracking params should be SET
        String googleAdvertisingId = UUID.randomUUID().toString();

        tune.setGoogleAdvertisingId(googleAdvertisingId, true);
        tune.setAppAdTrackingEnabled(true);
        tune.measureEvent("session");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertKeyValue( TuneUrlKeys.APP_AD_TRACKING, TuneConstants.PREF_SET );
        assertKeyValue( TuneUrlKeys.GOOGLE_AD_TRACKING_DISABLED, TuneConstants.PREF_SET );

        // Re-create the test params so the old ones are not counted here.
        params = new TuneTestParams();

        // COPPA TEST -- tracking params should now be UNSET
        tune.setAppAdTrackingEnabled(true);
        tune.setAge(TuneConstants.COPPA_MINIMUM_AGE - 1);

        tune.measureEvent("session");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertKeyValue( TuneUrlKeys.APP_AD_TRACKING, TuneConstants.PREF_UNSET );
        assertKeyValue( TuneUrlKeys.GOOGLE_AD_TRACKING_DISABLED, TuneConstants.PREF_UNSET );
    }

    @Test
    public void testSetCOPPADoesntRemoveAction() {
        tune.setPrivacyProtectedDueToAge(true);

        tune.measureEvent("session");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertKeyValue( TuneUrlKeys.ACTION, "session" );
    }

    // Only use this method for checking if age has been fully propagated.
    private void setAgeAndWait(int age) {
        tune.setAge(age);
        sleep(TuneTestConstants.PARAMTEST_SLEEP);
    }

    // Only use this method for checking if privacy protection has been fully propagated.
    private boolean setPrivacyProtectedDueToAgeAndWait(boolean privacyProtected) {
        boolean rc = tune.setPrivacyProtectedDueToAge(privacyProtected);
        if (rc) {
            sleep(TuneTestConstants.PARAMTEST_SLEEP);
        }

        return rc;
    }


    @Test
    public void testDeviceBrand() {
        String expectedDeviceBrand = "HTC";

        tune.getTuneParams().setDeviceBrand(expectedDeviceBrand);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.DEVICE_BRAND, expectedDeviceBrand);
        assertEquals(expectedDeviceBrand, tune.getDeviceBrand());
    }

    @Test
    public void testDeviceId() {
        String expectedDeviceId = "1234567890";

        tune.getTuneParams().setDeviceId(expectedDeviceId);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.DEVICE_ID, expectedDeviceId);
        assertEquals(expectedDeviceId, tune.getDeviceId());
    }

    @Test
    public void testDeviceModel() {
        String expectedDeviceModel = "Nexus 6";

        tune.getTuneParams().setDeviceModel(expectedDeviceModel);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.DEVICE_MODEL, "Nexus+6");
        assertEquals(expectedDeviceModel, tune.getDeviceModel());
    }

    @Test
    public void testEventParameters() {
        final double revenue = 4.99;
        final String currency = "CAD";
        final String refId = "12345";
        final String contentType = "content type";
        final String contentId = "content ID";
        final int level = 14;
        final int quantity = 63;
        final String searchString = "search string";
        final double rating = 3.14;
        final Date date1 = new Date();
        final Date date2 = new Date();
        final String attr1 = "attribute1";
        final String attr2 = "attribute2";
        final String attr3 = "attribute3";
        final String attr4 = "attribute4";
        final String attr5 = "attribute5";

        String expectedCurrency = null,
               expectedRefId = null,
               expectedContentType = null,
               expectedContentId = null,
               expectedSearchString = null,
               expectedAttribute1 = null,
               expectedAttribute2 = null,
               expectedAttribute3 = null,
               expectedAttribute4 = null,
               expectedAttribute5 = null;
        try {
            expectedCurrency = URLEncoder.encode(currency, "UTF-8");
            expectedRefId = URLEncoder.encode(refId, "UTF-8");
            expectedContentType = URLEncoder.encode(contentType, "UTF-8");
            expectedContentId = URLEncoder.encode(contentId, "UTF-8");
            expectedSearchString = URLEncoder.encode(searchString, "UTF-8");
            expectedAttribute1 = URLEncoder.encode(attr1, "UTF-8");
            expectedAttribute2 = URLEncoder.encode(attr2, "UTF-8");
            expectedAttribute3 = URLEncoder.encode(attr3, "UTF-8");
            expectedAttribute4 = URLEncoder.encode(attr4, "UTF-8");
            expectedAttribute5 = URLEncoder.encode(attr5, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }

        TuneEvent eventData = new TuneEvent("registration")
            .withRevenue(revenue)
            .withCurrencyCode(currency)
            .withAdvertiserRefId(refId)
            .withContentType(contentType)
            .withContentId(contentId)
            .withLevel(level)
            .withQuantity(quantity)
            .withSearchString(searchString)
            .withRating(rating)
            .withDate1(date1)
            .withDate2(date2)
            .withAttribute1(attr1)
            .withAttribute2(attr2)
            .withAttribute3(attr3)
            .withAttribute4(attr4)
            .withAttribute5(attr5);
        tune.measureEvent(eventData);
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.REVENUE, Double.toString(revenue));
        assertKeyValue(TuneUrlKeys.REF_ID, expectedRefId);
        assertKeyValue(TuneUrlKeys.CONTENT_TYPE, expectedContentType);
        assertKeyValue(TuneUrlKeys.CONTENT_ID, expectedContentId);
        assertKeyValue(TuneUrlKeys.LEVEL, Integer.toString(level));
        assertKeyValue(TuneUrlKeys.QUANTITY, Integer.toString(quantity));
        assertKeyValue(TuneUrlKeys.SEARCH_STRING, expectedSearchString );
        assertKeyValue(TuneUrlKeys.RATING, Double.toString(rating));
        assertKeyValue(TuneUrlKeys.DATE1, Long.toString(date1.getTime()/1000));
        assertKeyValue(TuneUrlKeys.DATE2, Long.toString(date2.getTime()/1000));
        assertKeyValue(TuneUrlKeys.ATTRIBUTE1, expectedAttribute1);
        assertKeyValue(TuneUrlKeys.ATTRIBUTE2, expectedAttribute2);
        assertKeyValue(TuneUrlKeys.ATTRIBUTE3, expectedAttribute3);
        assertKeyValue(TuneUrlKeys.ATTRIBUTE4, expectedAttribute4);
        assertKeyValue(TuneUrlKeys.ATTRIBUTE5, expectedAttribute5);
    }

    @Test
    public void testEventParametersCleared() {
        final double revenue = 4.99;
        final String currency = "CAD";
        final String refId = "12345";
        final String contentType = "content type";
        final String contentId = "content ID";
        final int level = 14;
        final int quantity = 63;
        final String searchString = "search string";
        final double rating = 3.14;
        final Date date1 = new Date();
        final Date date2 = new Date();
        final String attr1 = "attribute1";
        final String attr2 = "attribute2";
        final String attr3 = "attribute3";
        final String attr4 = "attribute4";
        final String attr5 = "attribute5";
        final String form = TuneEvent.DEVICE_FORM_WEARABLE;

        TuneEvent eventData = new TuneEvent("purchase")
                                 .withRevenue(revenue)
                                 .withCurrencyCode(currency)
                                 .withAdvertiserRefId(refId)
                                 .withContentType(contentType)
                                 .withContentId(contentId)
                                 .withLevel(level)
                                 .withQuantity(quantity)
                                 .withSearchString(searchString)
                                 .withRating(rating)
                                 .withDate1(date1)
                                 .withDate2(date2)
                                 .withAttribute1(attr1)
                                 .withAttribute2(attr2)
                                 .withAttribute3(attr3)
                                 .withAttribute4(attr4)
                                 .withAttribute5(attr5)
                                 .withDeviceForm(form);
        tune.measureEvent(eventData);
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));
        assertTrue("params default values failed " + params, params.checkDefaultValues());

        params = new TuneTestParams();
        tune.measureEvent("purchase");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.REVENUE, "0.0");
        assertNoValueForKey(TuneUrlKeys.REF_ID);
        assertNoValueForKey(TuneUrlKeys.CONTENT_TYPE);
        assertNoValueForKey(TuneUrlKeys.CONTENT_ID);
        assertNoValueForKey(TuneUrlKeys.LEVEL);
        assertNoValueForKey(TuneUrlKeys.QUANTITY);
        assertNoValueForKey(TuneUrlKeys.SEARCH_STRING);
        assertNoValueForKey(TuneUrlKeys.RATING);
        assertNoValueForKey(TuneUrlKeys.DATE1);
        assertNoValueForKey(TuneUrlKeys.DATE2);
        assertNoValueForKey(TuneUrlKeys.ATTRIBUTE1);
        assertNoValueForKey(TuneUrlKeys.ATTRIBUTE2);
        assertNoValueForKey(TuneUrlKeys.ATTRIBUTE3);
        assertNoValueForKey(TuneUrlKeys.ATTRIBUTE4);
        assertNoValueForKey(TuneUrlKeys.ATTRIBUTE5);
        assertNoValueForKey(TuneUrlKeys.DEVICE_FORM);
    }

    @Test
    public void testExistingUser() {
        tune.setExistingUser(true);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.EXISTING_USER, "1");
        assertTrue(tune.getExistingUser());
    }

    @Test
    public void testFacebookUserId() {
        final String userId = "fakeUserId";

        tune.setFacebookUserId(userId);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.FACEBOOK_USER_ID);

        assertEquals(userId, tune.getFacebookUserId());
    }

    @Test
    public void testGenderMale() {
        final TuneGender gender = TuneGender.MALE;
        final String expectedGender = "0";

        tune.setGender(gender);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.GENDER);

        assertEquals(gender, tune.getGender());
    }

    @Test
    public void testGenderFemale() {
        final TuneGender gender = TuneGender.FEMALE;
        final String expectedGender = "1";

        tune.setGender(gender);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.GENDER);

        assertEquals(gender, tune.getGender());
    }

    @Test
    public void testGenderUnknown() {
        final TuneGender gender = TuneGender.UNKNOWN;

        tune.setGender(gender);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey(TuneUrlKeys.GENDER);
        assertEquals(gender, tune.getGender());
    }

    @Test
    public void testGenderNotSetUnknown() {
        // do not call set gender
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey(TuneUrlKeys.GENDER);
        assertEquals(TuneGender.UNKNOWN, tune.getGender());
    }

    @Test
    public void testGoogleAdvertisingId() {
        String googleAdvertisingId = UUID.randomUUID().toString();

        tune.setGoogleAdvertisingId(googleAdvertisingId, false);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.GOOGLE_AID, googleAdvertisingId);
        assertKeyValue(TuneUrlKeys.GOOGLE_AD_TRACKING_DISABLED, TuneConstants.PREF_UNSET);
        assertEquals(googleAdvertisingId, tune.getTuneParams().getGoogleAdvertisingId());
        assertFalse(tune.getTuneParams().getPlatformAdTrackingLimited());

        // Check that the platform advertising id is also *NOT* set
        assertKeyValue(TuneUrlKeys.PLATFORM_AID, googleAdvertisingId);
        assertKeyValue(TuneUrlKeys.PLATFORM_AD_TRACKING_DISABLED, TuneConstants.PREF_UNSET);
        assertEquals(googleAdvertisingId, tune.getPlatformAdvertisingId());
        assertFalse(tune.getPlatformAdTrackingLimited());
    }

    @Test
    public void testSetGoogleAdvertisingIdNull() {
        tune.setGoogleAdvertisingId(null, false);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey(TuneUrlKeys.GOOGLE_AID);
        assertKeyValue(TuneUrlKeys.GOOGLE_AD_TRACKING_DISABLED, TuneConstants.PREF_UNSET);
        assertEquals(null, tune.getTuneParams().getGoogleAdvertisingId());
        assertFalse(tune.getTuneParams().getPlatformAdTrackingLimited());

        // Check that the platform advertising id is also *NOT* set
        assertNoValueForKey(TuneUrlKeys.PLATFORM_AID);
        assertKeyValue(TuneUrlKeys.PLATFORM_AD_TRACKING_DISABLED, TuneConstants.PREF_UNSET);
        assertEquals(null, tune.getPlatformAdvertisingId());
        assertFalse(tune.getPlatformAdTrackingLimited());
    }

    @Test
    public void testGoogleUserId() {
        // TODO: REVISIT.  Tune has not finished initializing by the time this test starts to run.
        sleep( TuneTestConstants.PARAMTEST_SLEEP );

        final String userId = "fakeUserId";

        tune.setGoogleUserId(userId);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.GOOGLE_USER_ID);

        assertEquals(userId, tune.getGoogleUserId());
    }

    @Test
    public void testIsPayingUser() {
        tune.setPayingUser(true);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.IS_PAYING_USER, "1");
        assertTrue(tune.isPayingUser());
    }

    @Test
    public void testIsPayingUserAutoCollect() {
        tune.setPayingUser(false);
        tune.measureEvent(new TuneEvent("registration").withRevenue(1.0).withCurrencyCode("USD"));
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.IS_PAYING_USER, "1");
        assertTrue(tune.isPayingUser());
    }

    @Test
    public void testIsPayingUserFalse() {
        tune.setPayingUser(false);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.IS_PAYING_USER, "0");
        assertFalse(tune.isPayingUser());
    }

    @Test
    public void testIsPayingUserNull() {
        // do not set is paying user
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey(TuneUrlKeys.IS_PAYING_USER);
        assertFalse(tune.isPayingUser());
    }

    @Test
    public void testLatitudeValidGtZero() {
        final double latitude = 43;
        String expectedLatitude = Double.toString(latitude);

        tune.setLocation(latitude, 0, 0);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.LATITUDE);

        assertEquals(latitude, tune.getLocation().getLatitude(), 0.0001);
    }

    @Test
    public void testLatitudeValidLtZero() {
        final double latitude = -122;
        String expectedLatitude = Double.toString(latitude);

        tune.setLocation(latitude, 0, 0);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.LATITUDE);

        assertEquals(latitude, tune.getLocation().getLatitude(), 0.0001);
    }

    @Test
    public void testLatitudeZero() {
        final double latitude = 0;
        String expectedLatitude = Double.toString(latitude);

        tune.setLocation(latitude, 0, 0);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.LATITUDE);

        assertEquals(latitude, tune.getLocation().getLatitude(), 0.0001);
    }

    @Test
    public void testLatitudeVeryLarge() {
        final double latitude = 43654;
        String expectedLatitude = Double.toString(latitude);

        tune.setLocation(latitude, 0, 0);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.LATITUDE);

        assertEquals(latitude, tune.getLocation().getLatitude(), 0.0001);
    }

    @Test
    public void testLatitudeVerySmall() {
        final double latitude = -64645;
        String expectedLatitude = Double.toString(latitude);

        tune.setLocation(latitude, 0, 0);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.LATITUDE);

        assertEquals(latitude, tune.getLocation().getLatitude(), 0.0001);
    }

    @Test
    public void testLatitudeNull() {
        // don't set latitude, will be null
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey(TuneUrlKeys.LATITUDE);
        assertEquals(null, tune.getLocation());
    }

    @Test
    public void testAppVersionNull() {
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.APP_VERSION, "0");
        assertEquals(0, tune.getAppVersion());
    }

    @Test
    public void testAppAdTrackingTrue() {
        final String expectedAppAdTracking = TuneConstants.PREF_SET;

        tune.setAppAdTrackingEnabled(true);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.APP_AD_TRACKING, expectedAppAdTracking);
        assertTrue(tune.getAppAdTrackingEnabled());
    }

    @Test
    public void testAppAdTrackingFalse() {
        final String expectedAppAdTracking = TuneConstants.PREF_UNSET;

        tune.setAppAdTrackingEnabled(false);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.APP_AD_TRACKING, expectedAppAdTracking);
        assertFalse(tune.getAppAdTrackingEnabled());
    }

    @Test
    public void testAppAdTrackingDefault() {
        // Reference: SDK-845
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey(TuneUrlKeys.APP_AD_TRACKING);
    }

    @Test
    public void testTuneSetLocationDisableAutoCollect() {
        final double latitude = 87;
        final double longitude = -122;

        tune.setLocation(latitude, longitude, 0);
        assertFalse(tune.locationListener.isListening());
    }

    @Test
    public void testTuneLocation() {
        final double latitude = 87;
        final double longitude = -122;
        String expectedLatitude = Double.toString(latitude);
        String expectedLongitude = Double.toString(longitude);

        tune.setLocation(latitude, longitude, 0);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.LATITUDE);
        assertNoValueForKey(TuneUrlKeys.LONGITUDE);
    }

    @Test
    public void testLongitudeValidGtZero() {
        final double longitude = 43;
        String expectedLongitude = Double.toString(longitude);

        tune.setLocation(0, longitude, 0);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.LONGITUDE);

        assertEquals(longitude, tune.getLocation().getLongitude(), 0.0001);
    }

    @Test
    public void testLongitudeValidLtZero() {
        final double longitude = -122;
        String expectedLongitude = Double.toString(longitude);

        tune.setLocation(0, longitude, 0);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.LONGITUDE);

        assertEquals(longitude, tune.getLocation().getLongitude(), 0.0001);
    }

    @Test
    public void testLongitudeValidLarge() {
        final double longitude = 304;
        String expectedLongitude = Double.toString(longitude);

        tune.setLocation(0, longitude, 0);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.LONGITUDE);

        assertEquals(longitude, tune.getLocation().getLongitude(), 0.0001);
    }

    @Test
    public void testLongitudeZero() {
        final double longitude = 0;
        String expectedLongitude = Double.toString(longitude);

        tune.setLocation(0, longitude, 0);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.LONGITUDE);

        assertEquals(longitude, tune.getLocation().getLongitude(), 0.0001);
    }

    @Test
    public void testLongitudeVeryLarge() {
        final double longitude = 43654;
        String expectedLongitude = Double.toString(longitude);

        tune.setLocation(0, longitude, 0);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.LONGITUDE);

        assertEquals(longitude, tune.getLocation().getLongitude(), 0.0001);
    }

    @Test
    public void testLongitudeVerySmall() {
        final double longitude = -64645;
        String expectedLongitude = Double.toString(longitude);

        tune.setLocation(0, longitude, 0);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.LONGITUDE);

        assertEquals(longitude, tune.getLocation().getLongitude(), 0.0001);
    }

    @Test
    public void testLongitudeNull() {
        // do not set longitude
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey(TuneUrlKeys.LONGITUDE);
        assertEquals(null, tune.getLocation());
    }

    @Test
    public void testLocation() {
        final double latitude = 47.612296;
        final double longitude = -122.345853;
        final double altutude = 3.141592654;

        tune.setLocation(latitude, longitude, altutude);

        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.LATITUDE);
        assertNoValueForKey(TuneUrlKeys.LONGITUDE);
        assertNoValueForKey(TuneUrlKeys.ALTITUDE);
    }

    @Test
    public void testLocationChanged() {
        final double latitude = 47.612296;
        final double longitude = -122.345853;
        final double altutude = 3.141592654;

        // Set an unexpected location
        tune.setLocation(latitude - 10.0, longitude - 100.0, altutude - 1.0);

        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // Now set the expected location
        tune.setLocation(latitude, longitude, altutude);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.LATITUDE);
        assertNoValueForKey(TuneUrlKeys.LONGITUDE);
        assertNoValueForKey(TuneUrlKeys.ALTITUDE);
    }

    @Test
    public void testOsVersion() {
        String osVersion = "5.1.1";
        tune.setOsVersion(osVersion);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.OS_VERSION, osVersion);
        assertEquals(osVersion, tune.getOsVersion());
    }

    @Test
    public void testPackageNameDefault() {
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
    }

    @Test
    public void testPhoneNumber() {
        final String phoneNumber = "(123) 456-7890";
        // Hash will correspond to digits of number
        String phoneNumberDigits = "1234567890";
        tune.setPhoneNumber(phoneNumber);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey("user_phone");
        assertKeyValue(TuneUrlKeys.USER_PHONE_SHA256, TuneUtils.sha256(phoneNumberDigits));
    }

    @Test
    public void testPhoneNumberForeign() {
        String phoneNumber = "+१२३.४५६.७८९०";
        String phoneNumberDigits = "1234567890";
        tune.setPhoneNumber(phoneNumber);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey("user_phone");
        assertKeyValue(TuneUrlKeys.USER_PHONE_SHA256, TuneUtils.sha256(phoneNumberDigits));

        phoneNumber = "(١٢٣)٤٥٦-٧.٨.٩ ٠";
        tune.setPhoneNumber(phoneNumber);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey("user_phone");
        assertKeyValue(TuneUrlKeys.USER_PHONE_SHA256, TuneUtils.sha256(phoneNumberDigits));

        phoneNumber = "၁၂-၃၄-၅၆၇.၈၉ ၀";
        tune.setPhoneNumber(phoneNumber);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey("user_phone");
        assertKeyValue(TuneUrlKeys.USER_PHONE_SHA256, TuneUtils.sha256(phoneNumberDigits));

        phoneNumber = "(１２３)４５６-７８９０";
        tune.setPhoneNumber(phoneNumber);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey("user_phone");
        assertKeyValue(TuneUrlKeys.USER_PHONE_SHA256, TuneUtils.sha256(phoneNumberDigits));
    }

    @Test
    public void testPlatformAdvertisingId() {
        String platformAdvertisingId = UUID.randomUUID().toString();

        tune.setPlatformAdvertisingId(platformAdvertisingId, true);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.PLATFORM_AID, platformAdvertisingId);
        assertKeyValue(TuneUrlKeys.PLATFORM_AD_TRACKING_DISABLED, TuneConstants.PREF_SET);
        assertEquals(platformAdvertisingId, tune.getPlatformAdvertisingId());
        assertTrue(tune.getPlatformAdTrackingLimited());
    }

    @Test
    public void testSetPlatformAdvertisingIdNull() {
        tune.setPlatformAdvertisingId(null, false);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey(TuneUrlKeys.PLATFORM_AID);
        assertKeyValue(TuneUrlKeys.PLATFORM_AD_TRACKING_DISABLED, TuneConstants.PREF_UNSET);
        assertEquals(null, tune.getPlatformAdvertisingId());
        assertFalse(tune.getPlatformAdTrackingLimited());
    }

    @Test
    public void testPluginName() {
        final String[] testPluginNames = {
                "air",
                "cocos2dx",
                "js",
                "marmalade",
                "phonegap",
                "titanium",
                "unity",
                "xamarin"
        };

        for (String pluginName : testPluginNames) {
            tune.setPluginName(pluginName);
            tune.measureEvent("registration");
            assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

            assertTrue("params default values failed " + params, params.checkDefaultValues());
            assertKeyValue(TuneUrlKeys.SDK_PLUGIN, pluginName);
            assertEquals(pluginName, tune.getTuneParams().getPluginName());
        }
    }

    @Test
    public void testPluginNameInvalid() {
        tune.setPluginName("fake_plugin");
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey(TuneUrlKeys.SDK_PLUGIN);
    }

    @Test
    public void testReferralUrl() {
        String referralUrl = "tune://";

        tune.setReferralUrl(referralUrl);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.REFERRAL_URL, "tune%3A%2F%2F");
        assertEquals(referralUrl, tune.getReferralUrl());
    }

    @Test
    public void testReferrer() {
        // Clear SharedPreferences referrer value
        new TuneSharedPrefsDelegate(getContext().getApplicationContext(), TuneConstants.PREFS_TUNE).putString(TuneConstants.KEY_REFERRER, "");

        final String referrer = "aTestReferrer";

        tune.setInstallReferrer( referrer );
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.INSTALL_REFERRER, referrer);
        assertEquals(referrer, tune.getInstallReferrer());
    }

    @Test
    public void testReferrerNull() {
        // Clear SharedPreferences referrer
        new TuneSharedPrefsDelegate(getContext().getApplicationContext(), TuneConstants.PREFS_TUNE).remove(TuneConstants.KEY_REFERRER);

        tune.setInstallReferrer(null);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values should have failed " + params, params.checkDefaultValues());
        assertNoValueForKey(TuneUrlKeys.INSTALL_REFERRER);
        assertEquals(null, tune.getInstallReferrer());
    }

    @Test
    public void testTwitterUserId() {
        final String id = "testId";

        tune.setTwitterUserId( id );
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.TWITTER_USER_ID);

        assertEquals(id, tune.getTwitterUserId());
    }

    @Test
    public void testUserEmail() {
        final String email = "testUserEmail@test.com";
        tune.setUserEmail( email );
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey("user_email");
        assertKeyValue(TuneUrlKeys.USER_EMAIL_SHA256, TuneUtils.sha256(email));
        assertEquals(email, tune.getUserEmail());
    }

    @Test
    public void testUserEmailsNotSaved() {
        TuneSharedPrefsDelegate testSharedPreferences = new TuneSharedPrefsDelegate(getContext().getApplicationContext(), TuneConstants.PREFS_TUNE);

        // No emails are stored in the test suite's Shared Preferences by default
        assertEquals("", testSharedPreferences.getStringFromSharedPreferences(TuneConstants.KEY_USER_EMAIL));
        assertEquals("", testSharedPreferences.getStringFromSharedPreferences(TuneConstants.KEY_USER_EMAILS));
    }

    @Test
    public void testSetUserEmails() {
        TuneSharedPrefsDelegate testSharedPreferences = new TuneSharedPrefsDelegate(getContext().getApplicationContext(), TuneConstants.PREFS_TUNE);
        testSharedPreferences.saveToSharedPreferences(TuneConstants.KEY_USER_EMAILS, null);

        final String[] emailsArray = {"test@tune.com", "test@testing.com", "test@jennifertunetest.com"};

        tune.setUserEmails(emailsArray);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        final JSONArray emailsFromSharedPrefs = new JSONArray(Arrays.asList(emailsArray));

        String sharedPrefernceEmailsString = testSharedPreferences.getStringFromSharedPreferences(TuneConstants.KEY_USER_EMAILS);

        // Test that the emails aside from the primary Gmail are stored in Shared Preferences
        assertTrue(sharedPrefernceEmailsString.contains("test@tune.com"));
        assertTrue(sharedPrefernceEmailsString.contains("test@testing.com"));
        assertTrue(sharedPrefernceEmailsString.contains("test@jennifertunetest.com"));


        // Test emails' retrieval and conversation back into JSON via their getter method (i.e. number of expected emails and that all of them are present)
        assertTrue(emailsFromSharedPrefs.length() == 3);
        assertTrue(emailsFromSharedPrefs.toString().contains("test@tune.com"));
        assertTrue(emailsFromSharedPrefs.toString().contains("test@testing.com"));
        assertTrue(emailsFromSharedPrefs.toString().contains("test@jennifertunetest.com"));
    }

    @Test
    public void testSetUserEmailsNullArray() throws Exception {
        tune.setUserEmails(null);

        assertNull(tune.getUserEmails());
    }

    @Test
    public void testSetUserEmailsEmptyArray() throws Exception {
        String[] emails = new String[] {""};
        tune.setUserEmails(emails);

        assertNull(tune.getUserEmails());
    }

    @Test
    public void testUserEmailsSetWithNullAndEmptyArrayValues() {
        TuneSharedPrefsDelegate testSharedPreferences = new TuneSharedPrefsDelegate(getContext().getApplicationContext(), TuneConstants.PREFS_TUNE);
        testSharedPreferences.saveToSharedPreferences(TuneConstants.KEY_USER_EMAILS, null);

        final String[] emailsArray = {"test@tune.com", "", null, "test@jennifertunetest.com"};

        tune.setUserEmails(emailsArray);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        String emailsFromSharedPrefs = testSharedPreferences.getStringFromSharedPreferences(TuneConstants.KEY_USER_EMAILS);

        // Test that the emails aside from the primary Gmail are stored in Shared Preferences; no invalid values stored
        assertTrue(emailsFromSharedPrefs.contains("test@tune.com"));
        assertTrue(emailsFromSharedPrefs.contains(""));
//        assertFalse(emailsFromSharedPrefs.contains(null));
        assertTrue(emailsFromSharedPrefs.contains("test@jennifertunetest.com"));

        JSONArray sharedPrefsEmailsRetrieved = tune.getUserEmails();

        // Test emails' retrieval and conversation back into JSON via their getter method (i.e. number of expected emails and that all of them are present)
        assertTrue(sharedPrefsEmailsRetrieved.length() == 2);
        assertTrue(sharedPrefsEmailsRetrieved.toString().contains("test@tune.com"));
        assertTrue(sharedPrefsEmailsRetrieved.toString().contains("test@jennifertunetest.com"));
    }

    @Test
    public void testCanRecoverUserEmailsFromSharedPrefs() {
        TuneSharedPrefsDelegate testSharedPreferences = new TuneSharedPrefsDelegate(getContext().getApplicationContext(), TuneConstants.PREFS_TUNE);
        testSharedPreferences.saveToSharedPreferences(TuneConstants.KEY_USER_EMAILS, null);

        final String[] emailsArray = {"test@tune.com", "test@testing.com", "test@jennifertunetest.com"};
        final JSONArray emailsAsJSON = new JSONArray(Arrays.asList(emailsArray));
        final String emailsAsString = emailsAsJSON.toString();

        testSharedPreferences.saveToSharedPreferences(TuneConstants.KEY_USER_EMAILS, emailsAsString);

        String emailsFromSharedPrefs = testSharedPreferences.getStringFromSharedPreferences(TuneConstants.KEY_USER_EMAILS);

        // Test that user emails are saved as Shared Preferences without calling setUserEmails() or collectEmails()
        assertTrue(emailsFromSharedPrefs.contains("test@tune.com"));
        assertTrue(emailsFromSharedPrefs.contains("test@testing.com"));
        assertTrue(emailsFromSharedPrefs.contains("test@jennifertunetest.com"));

        JSONArray sharedPrefsEmailsRetrieved = tune.getUserEmails();

        // Test emails' retrieval and conversation back into JSON via their getter method without calling setUserEmails() or collectEmails()
        assertTrue(sharedPrefsEmailsRetrieved.length() == 3);
        assertTrue(sharedPrefsEmailsRetrieved.toString().contains("test@tune.com"));
        assertTrue(sharedPrefsEmailsRetrieved.toString().contains("test@testing.com"));
        assertTrue(sharedPrefsEmailsRetrieved.toString().contains("test@jennifertunetest.com"));
    }

    @Test
    public void testCollectEmails() {
        TuneSharedPrefsDelegate testSharedPreferences = new TuneSharedPrefsDelegate(getContext().getApplicationContext(), TuneConstants.PREFS_TUNE);
        tune.collectEmails();
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        verify(tune.getAccountManager(getContext()), times(1)).getAccountsByType(TuneConstants.GOOGLE_ACCOUNT_TYPE);

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey("user_email");
        assertHasValueForKey(TuneUrlKeys.USER_EMAIL_SHA256);
        assertHasValueForKey(TuneUrlKeys.USER_EMAILS);

        String setUserEmailsPref = testSharedPreferences.getStringFromSharedPreferences(TuneConstants.KEY_USER_EMAILS);
        assertEquals("[\"testing@tune.com\"]", setUserEmailsPref);
    }

    @Test
    public void testClearEmails() {
        // NOTE ideally we'd test adding/clearing emails with additional tests factoring in enabled and revoked GET_ACCOUNT permissions, but that's not possible with the rule declared at the top of the test suite.
        // TODO Look into options for turning GET_ACCOUNT permission on and then off for testing
        TuneSharedPrefsDelegate testSharedPreferences = new TuneSharedPrefsDelegate(getContext().getApplicationContext(), TuneConstants.PREFS_TUNE);
        tune.collectEmails();
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        verify(tune.getAccountManager(getContext()), times(1)).getAccountsByType(TuneConstants.GOOGLE_ACCOUNT_TYPE);

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey("user_email");
        assertHasValueForKey(TuneUrlKeys.USER_EMAIL_SHA256);
        assertHasValueForKey(TuneUrlKeys.USER_EMAILS);

        tune.clearEmails();
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey("user_email");
        assertNull(tune.params.getUserEmailSha256());
        assertEquals(null, tune.params.getUserEmails());

        String clearedUserEmailsPref = testSharedPreferences.getStringFromSharedPreferences(TuneConstants.KEY_USER_EMAILS);
        assertEquals("", clearedUserEmailsPref);
    }

    @Test
    public void testUserId() {
        final String id = "testId";

        tune.setUserId(id);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        // v6.0.5 redacted always
        assertNoValueForKey(TuneUrlKeys.USER_ID);

        assertEquals(id, tune.getUserId());
    }

    @Test
    public void testUserName() {
        final String id = "testUserName";
        tune.setUserName(id);
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey("user_name");
        assertKeyValue(TuneUrlKeys.USER_NAME_SHA256, TuneUtils.sha256(id));
        assertEquals(id, tune.getUserName());
    }

    @Test
    public void testUserIdsAutoPopulated() {
        final String testId = "aTestId";
        final String testEmail = "aTestEmail";
        final String testName = "aTestUserName";

        tune.setUserId( testId );
        tune.setUserEmail( testEmail );
        tune.setUserName( testName );

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertTrue( "should have saved user id", testId.equals( tune.readUserIdKey( TuneConstants.KEY_USER_ID ) ) );
        assertTrue( "should have saved user email", testEmail.equals( tune.readUserIdKey( TuneConstants.KEY_USER_EMAIL ) ) );
        assertTrue( "should have saved user name", testName.equals( tune.readUserIdKey( TuneConstants.KEY_USER_NAME ) ) );

        assertTrue( "should have read user id", testId.equals( tune.getUserId() ) );
        assertTrue( "should have read user email", testEmail.equals( tune.getUserEmail() ) );
        assertTrue( "should have read user name", testName.equals( tune.getUserName() ) );
    }


    // Build and locale are required for AdWords attribution
    @Test
    public void testDeviceBuildAutoPopulated() {
        assertNotNull(tune.getDeviceBuild());
    }

    @Test
    public void testLocaleAutoPopulated() {
        assertNotNull(tune.getLocale());

        // Locale should be in format "{language}_{country}"
        // where {language} is some unstable language code: https://developer.android.com/reference/java/util/Locale.html#getLanguage()
        // and {country} is empty string, an uppercase ISO 3166 2-letter code, or a UN M.49 3-digit code: https://developer.android.com/reference/java/util/Locale.html#getCountry()
        String localePattern = "^[a-z]*_(^$|[A-Z]{2}|[0-9]{3})$";

        Pattern pattern = Pattern.compile(localePattern);
        Matcher matcher = pattern.matcher(tune.getLocale());

        assertTrue(matcher.matches());
    }

    /**
     * The goal here is to call something that eventually gets to {@link TuneUrlBuilder#appendTuneLinkParameters(TuneParameters, String)}
     * so that we can check to see if the {@link TuneParameters#ACTION_CLICK} was appended, even if privacy rules apply.
     * Reference: SDK-542
     */
    @Test
    public void testTuneLinkParameters() {
        final String clickedTuneLinkUrl = "https://tlnk.io/some.url";
        tune.setPrivacyProtectedDueToAge(true);

        tune.setReferralUrl(clickedTuneLinkUrl);
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertKeyValue( TuneUrlKeys.ACTION, TuneParameters.ACTION_CLICK );
    }

    @Test
    public void testSDKLocale() {
        TuneParameters.SDKTYPE type = TuneParameters.SDKTYPE.ANDROID;

        // Default
        assertEquals("android", type.toString());

        // Test Jira SDK-672 -- Error with az and tr locales
        setLocale("az", "AZ");
        assertEquals("android", type.toString());

        setLocale("tr", "TR");
        assertEquals("android", type.toString());
    }

    @Test
    public void testSetDeviceCpuSubtype() {
        final String fakeDeviceCpuSubtype = "fake_device_cpu_subtype";
        tune.params.setDeviceCpuSubtype(fakeDeviceCpuSubtype);

        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue(TuneUrlKeys.DEVICE_CPU_SUBTYPE, fakeDeviceCpuSubtype);
        assertEquals(fakeDeviceCpuSubtype, tune.params.getDeviceCpuSubtype());
    }

    @Test
    public void testDeviceCpuSubtypeNull() {
        tune.measureEvent("registration");
        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertNoValueForKey(TuneUrlKeys.DEVICE_CPU_SUBTYPE);
        assertNull(tune.params.getDeviceCpuSubtype());
    }

    @Test
    public void testUserEmail_afterRestart() throws Exception {
        final String email = "testUserEmail_afterRestart@test.com";
        tune.setUserEmail(email);

        assertEquals(email, tune.getTuneParams().getUserEmail());
        assertEquals(TuneUtils.sha256(email), tune.getTuneParams().getUserEmailSha256());

        // Restart Tune
        restartTune();

        assertEquals(email, tune.getTuneParams().getUserEmail());
        assertEquals(TuneUtils.sha256(email), tune.getTuneParams().getUserEmailSha256());
    }

    @Test
    public void testUserName_afterRestart() throws Exception {
        final String name = "TestUserName AfterRestart";
        tune.setUserName(name);

        assertEquals(name, tune.getTuneParams().getUserName());
        assertEquals(TuneUtils.sha256(name), tune.getTuneParams().getUserNameSha256());

        // Restart Tune
        restartTune();

        assertEquals(name, tune.getTuneParams().getUserName());
        assertEquals(TuneUtils.sha256(name), tune.getTuneParams().getUserNameSha256());
    }

    @Test
    public void testPhoneNumber_afterRestart() throws Exception {
        final String number = "18888253270";
        tune.setPhoneNumber(number);

        assertEquals(number, tune.getTuneParams().getPhoneNumber());
        assertEquals(TuneUtils.sha256(number), tune.getTuneParams().getPhoneNumberSha256());

        // Restart Tune
        restartTune();

        assertEquals(number, tune.getTuneParams().getPhoneNumber());
        assertEquals(TuneUtils.sha256(number), tune.getTuneParams().getPhoneNumberSha256());
    }
}
