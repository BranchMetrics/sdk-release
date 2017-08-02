package com.tune.smartwhere;

import com.tune.TuneUnitTest;

import static com.tune.smartwhere.TuneSmartwhereConfiguration.GRANT_SMARTWHERE_TUNE_EVENTS;

/**
 * SmartWhere Configuration Tests -- when SmartWhere is available.
 */
public class SmartwhereConfigurationTests extends TuneUnitTest {

    public void testGrantAll() throws Exception {
        TuneSmartwhereConfiguration config = new TuneSmartwhereConfiguration();

        config.grantAll();

        assertTrue(config.isPermissionGranted(GRANT_SMARTWHERE_TUNE_EVENTS));
    }

    public void testRevokePermission() throws Exception {
        TuneSmartwhereConfiguration config = new TuneSmartwhereConfiguration();

        config.grantAll();
        assertTrue(config.isPermissionGranted(GRANT_SMARTWHERE_TUNE_EVENTS));

        config.revoke(GRANT_SMARTWHERE_TUNE_EVENTS);
        assertFalse(config.isPermissionGranted(GRANT_SMARTWHERE_TUNE_EVENTS));
    }

    public void testRevokeAllPermissions() throws Exception {
        TuneSmartwhereConfiguration config = new TuneSmartwhereConfiguration();

        config.grantAll();
        assertTrue(config.isPermissionGranted(GRANT_SMARTWHERE_TUNE_EVENTS));

        config.revokeAll();
        assertFalse(config.isPermissionGranted(GRANT_SMARTWHERE_TUNE_EVENTS));
    }

    public void testSerialization() {
        TuneSmartwhereConfiguration config = new TuneSmartwhereConfiguration();

        config.grantAll();
        String str = config.toString();

        TuneSmartwhereConfiguration config2 = new TuneSmartwhereConfiguration(str);
        assertTrue(config2.isPermissionGranted(GRANT_SMARTWHERE_TUNE_EVENTS));
    }

}
