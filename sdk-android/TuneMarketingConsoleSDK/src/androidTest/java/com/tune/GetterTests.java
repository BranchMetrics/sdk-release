package com.tune;

public class GetterTests extends TuneUnitTest {
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
        assertNotNull(tune.getMCC());
    }

    public void testMNC() {
        assertNotNull(tune.getMNC());
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
        assertEquals(TuneConstants.SDK_VERSION, tune.getSDKVersion());
    }

    public void testUserAgent() {
        assertNotNull(tune.getUserAgent());
    }
}
