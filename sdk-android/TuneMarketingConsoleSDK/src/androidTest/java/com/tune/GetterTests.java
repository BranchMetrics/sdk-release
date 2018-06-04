package com.tune;

import android.support.test.runner.AndroidJUnit4;

import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

@RunWith(AndroidJUnit4.class)
public class GetterTests extends TuneUnitTest {
    private static final String FAKE_PLATFORM_ADVERTISER_ID = "FAKEPlatformAdId1230001";
    private static final String FAKE_ANDROID_ADVERTISER_ID = "FAKEAndroidId1230001";
    private static final String FAKE_GOOGLE_ADVERTISER_ID = "FAKEGoogleAdId1230001";
    private static final String FAKE_FIRE_ADVERTISER_ID = "FAKEFireAdId1230001";

    @Test
    public void testAction() {
        String action = tune.getAction();
        assertNull( "action was not null, was " + action, action );
    }

    @Test
    public void testAdvertiserId() {
        assertEquals(TuneTestConstants.advertiserId, tune.getAdvertiserId());
    }

    @Test
    public void testAppName() {
        assertNotNull(tune.getAppName());
    }

    @Test
    public void testAppVersion() {
        assertNotNull(tune.getAppVersion());
    }

    @Test
    public void testConnectionType() {
        assertNotNull(tune.getConnectionType());
    }

    @Test
    public void testCountryCode() {
        assertNotNull(tune.getCountryCode());
    }

    @Test
    public void testDeviceBrand() {
        assertNotNull(tune.getDeviceBrand());
    }

    @Test
    public void testDeviceCarrier() {
        assertNotNull(tune.getDeviceCarrier());
    }

    @Test
    public void testDeviceModel() {
        assertNotNull(tune.getDeviceModel());
    }

    @Test
    public void testInstallDate() {
        sleep(TuneTestConstants.PARAMTEST_SLEEP);
        assertNotNull(tune.getInstallDate());
    }

    @Test
    public void testLanguage() {
        assertNotNull(tune.getLanguage());
    }

    @Test
    public void testMatId() {
        String matId = tune.getMatId();
        assertNotNull( "MAT ID was null", matId );
    }

    @Test
    public void testMCC() {
        String mcc = tune.getMCC();
        if (mcc != null) {
            int value = Integer.parseInt(mcc);
            assertTrue(value != 0);
        }
    }

    @Test
    public void testMNC() {
        String mnc = tune.getMNC();
        if (mnc != null) {
            int value = Integer.parseInt(mnc);
            assertTrue(value != 0);
        }
    }

    @Test
    public void testOsVersion() {
        assertNotNull(tune.getOsVersion());
    }

    @Test
    public void testScreenDensity() {
        assertNotNull(tune.getScreenDensity());
    }

    @Test
    public void testScreenHeight() {
        assertNotNull(tune.getScreenHeight());
    }

    @Test
    public void testScreenWidth() {
        assertNotNull(tune.getScreenWidth());
    }

    @Test
    public void testSdkVersion() {
        assertNotNull(Tune.getSDKVersion());
    }

    @Test
    public void testUserAgent() {
        assertNotNull(tune.getUserAgent());
    }

    @Test
    public void testGetIAMAppIDIsCorrect() {
        tune.setAdvertiserId("123456");
        tune.setPackageName("com.testing.things");

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertEquals("84cad6ca42428cef41a017b1efc6b225", tune.getIAMAppId());
    }

    @Test
    public void testGetIAMDeviceIDWhenNoAdvertisingIdSet() {
        tune.setGoogleAdvertisingId(null, false);
        tune.setFireAdvertisingId(null, false);
        tune.setAndroidId(null);

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull(tune.getIAMDeviceId());
        // if no advertising id is set, then we use the MAT id.
        assertEquals(tune.getMatId(), tune.getIAMDeviceId());
    }

    @Test
    public void testGetIAMDeviceIDWhenPlatformAdvertisingIdSet() {
        tune.setPlatformAdvertisingId(FAKE_PLATFORM_ADVERTISER_ID, false);

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull(tune.getIAMDeviceId());
        assertEquals(FAKE_PLATFORM_ADVERTISER_ID, tune.getIAMDeviceId());
    }

    @Test
    public void testGetIAMDeviceIDWhenGoogleAdvertisingIdSet() {
        tune.setGoogleAdvertisingId(FAKE_GOOGLE_ADVERTISER_ID, false);

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull(tune.getIAMDeviceId());
        assertEquals(FAKE_GOOGLE_ADVERTISER_ID, tune.getIAMDeviceId());
    }

    @Test
    public void testGetIAMDeviceIDWhenFireAdvertisingIdSet() {
        tune.setFireAdvertisingId(FAKE_FIRE_ADVERTISER_ID, false);

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull(tune.getIAMDeviceId());
        assertEquals(FAKE_FIRE_ADVERTISER_ID, tune.getIAMDeviceId());
    }

    @Test
    public void testGetIAMDeviceIDWhenAndroidIdSet() {
        tune.setFireAdvertisingId(null, false);
        tune.setGoogleAdvertisingId(null, false);
        tune.setAndroidId(FAKE_ANDROID_ADVERTISER_ID);

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull(tune.getIAMDeviceId());
        assertEquals(FAKE_ANDROID_ADVERTISER_ID, tune.getIAMDeviceId());
    }

    @Test
    public void testGetIAMDeviceIDWhenGoogleAndAndroidIdsSet() {
        tune.setGoogleAdvertisingId(FAKE_GOOGLE_ADVERTISER_ID, false);
        tune.setAndroidId(FAKE_ANDROID_ADVERTISER_ID);

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull(tune.getIAMDeviceId());
        assertEquals(FAKE_GOOGLE_ADVERTISER_ID, tune.getIAMDeviceId());
    }

    @Test
    public void testGetIAMDeviceIDWhenFireAndAndroidIdsSet() {
        tune.setFireAdvertisingId(FAKE_FIRE_ADVERTISER_ID, false);
        tune.setAndroidId(FAKE_ANDROID_ADVERTISER_ID);

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull(tune.getIAMDeviceId());
        assertEquals(FAKE_FIRE_ADVERTISER_ID, tune.getIAMDeviceId());
    }
}
