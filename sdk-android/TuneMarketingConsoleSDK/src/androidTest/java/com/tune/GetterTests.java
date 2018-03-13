package com.tune;

public class GetterTests extends TuneUnitTest {
    private static final String FAKE_PLATFORM_ADVERTISER_ID = "FAKEPlatformAdId1230001";
    private static final String FAKE_ANDROID_ADVERTISER_ID = "FAKEAndroidId1230001";
    private static final String FAKE_GOOGLE_ADVERTISER_ID = "FAKEGoogleAdId1230001";
    private static final String FAKE_FIRE_ADVERTISER_ID = "FAKEFireAdId1230001";

    public void testAction() {
        String action = tune.getAction();
        assertNull( "action was not null, was " + action, action );
    }

    public void testAdvertiserId() {
        assertEquals(TuneTestConstants.advertiserId, tune.getAdvertiserId());
    }

    public void testAppName() {
        assertNotNull(tune.getAppName());
    }

    public void testAppVersion() {
        assertNotNull(tune.getAppVersion());
    }

    public void testConnectionType() {
        assertNotNull(tune.getConnectionType());
    }

    public void testCountryCode() {
        assertNotNull(tune.getCountryCode());
    }

    public void testDeviceBrand() {
        assertNotNull(tune.getDeviceBrand());
    }

    public void testDeviceCarrier() {
        assertNotNull(tune.getDeviceCarrier());
    }

    public void testDeviceModel() {
        assertNotNull(tune.getDeviceModel());
    }

    public void testInstallDate() {
        sleep(TuneTestConstants.PARAMTEST_SLEEP);
        assertNotNull(tune.getInstallDate());
    }

    public void testLanguage() {
        assertNotNull(tune.getLanguage());
    }
    
    public void testMatId() {
        String matId = tune.getMatId();
        assertNotNull( "MAT ID was null", matId );
    }

    public void testMCC() {
        String mcc = tune.getMCC();
        if (mcc != null) {
            int value = Integer.parseInt(mcc);
            assertTrue(value != 0);
        }
    }

    public void testMNC() {
        String mnc = tune.getMNC();
        if (mnc != null) {
            int value = Integer.parseInt(mnc);
            assertTrue(value != 0);
        }
    }

    public void testOsVersion() {
        assertNotNull(tune.getOsVersion());
    }

    public void testScreenDensity() {
        assertNotNull(tune.getScreenDensity());
    }

    public void testScreenHeight() {
        assertNotNull(tune.getScreenHeight());
    }

    public void testScreenWidth() {
        assertNotNull(tune.getScreenWidth());
    }

    public void testSdkVersion() {
        assertNotNull(Tune.getSDKVersion());
    }

    public void testUserAgent() {
        assertNotNull(tune.getUserAgent());
    }

    public void testGetIAMAppIDIsCorrect() {
        tune.setAdvertiserId("123456");
        tune.setPackageName("com.testing.things");

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertEquals("84cad6ca42428cef41a017b1efc6b225", tune.getIAMAppId());
    }

    public void testGetIAMDeviceIDWhenNoAdvertisingIdSet() {
        tune.setGoogleAdvertisingId(null, false);
        tune.setFireAdvertisingId(null, false);
        tune.setAndroidId(null);

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull(tune.getIAMDeviceId());
        // if no advertising id is set, then we use the MAT id.
        assertEquals(tune.getMatId(), tune.getIAMDeviceId());
    }

    public void testGetIAMDeviceIDWhenPlatformAdvertisingIdSet() {
        tune.setPlatformAdvertisingId(FAKE_PLATFORM_ADVERTISER_ID, false);

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull(tune.getIAMDeviceId());
        assertEquals(FAKE_PLATFORM_ADVERTISER_ID, tune.getIAMDeviceId());
    }

    public void testGetIAMDeviceIDWhenGoogleAdvertisingIdSet() {
        tune.setGoogleAdvertisingId(FAKE_GOOGLE_ADVERTISER_ID, false);

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull(tune.getIAMDeviceId());
        assertEquals(FAKE_GOOGLE_ADVERTISER_ID, tune.getIAMDeviceId());
    }

    public void testGetIAMDeviceIDWhenFireAdvertisingIdSet() {
        tune.setFireAdvertisingId(FAKE_FIRE_ADVERTISER_ID, false);

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull(tune.getIAMDeviceId());
        assertEquals(FAKE_FIRE_ADVERTISER_ID, tune.getIAMDeviceId());
    }

    public void testGetIAMDeviceIDWhenAndroidIdSet() {
        tune.setFireAdvertisingId(null, false);
        tune.setGoogleAdvertisingId(null, false);
        tune.setAndroidId(FAKE_ANDROID_ADVERTISER_ID);

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull(tune.getIAMDeviceId());
        assertEquals(FAKE_ANDROID_ADVERTISER_ID, tune.getIAMDeviceId());
    }

    public void testGetIAMDeviceIDWhenGoogleAndAndroidIdsSet() {
        tune.setGoogleAdvertisingId(FAKE_GOOGLE_ADVERTISER_ID, false);
        tune.setAndroidId(FAKE_ANDROID_ADVERTISER_ID);

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull(tune.getIAMDeviceId());
        assertEquals(FAKE_GOOGLE_ADVERTISER_ID, tune.getIAMDeviceId());
    }

    public void testGetIAMDeviceIDWhenFireAndAndroidIdsSet() {
        tune.setFireAdvertisingId(FAKE_FIRE_ADVERTISER_ID, false);
        tune.setAndroidId(FAKE_ANDROID_ADVERTISER_ID);

        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull(tune.getIAMDeviceId());
        assertEquals(FAKE_FIRE_ADVERTISER_ID, tune.getIAMDeviceId());
    }
}
