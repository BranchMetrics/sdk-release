package com.tune.smartwhere;

import com.tune.TuneUnitTest;

import static com.tune.smartwhere.TuneSmartWhereConfiguration.GRANT_SMARTWHERE_OPT_IN;
import static com.tune.smartwhere.TuneSmartWhereConfiguration.GRANT_SMARTWHERE_TUNE_EVENTS;

/**
 * SmartWhere Configuration Tests -- when SmartWhere is available.
 */
public class SmartWhereConfigurationTests extends TuneUnitTest {

    public void testOptIn() throws Exception {
        TuneSmartWhereConfiguration config = new TuneSmartWhereConfiguration();

        config.grant(GRANT_SMARTWHERE_OPT_IN);
        assertTrue(config.isSmartWhereEnabled());
    }

    public void testNoOptIn() throws Exception {
        TuneSmartWhereConfiguration config = new TuneSmartWhereConfiguration();

        config.grant(GRANT_SMARTWHERE_TUNE_EVENTS);

        // Note that opt-in has not been granted yet, so this should fail
        assertFalse(config.isPermissionGranted(GRANT_SMARTWHERE_TUNE_EVENTS));

        // Note that granting one permission should not grant others
        assertFalse(config.isSmartWhereEnabled());
    }

    public void testConfigurationChaining() throws Exception {
        TuneSmartWhereConfiguration config = new TuneSmartWhereConfiguration();

        config.grant(GRANT_SMARTWHERE_OPT_IN).grant(GRANT_SMARTWHERE_TUNE_EVENTS);
        assertTrue(config.isPermissionGranted(GRANT_SMARTWHERE_TUNE_EVENTS));
    }

    public void testGrantAll() throws Exception {
        TuneSmartWhereConfiguration config = new TuneSmartWhereConfiguration();

        config.grantAll();

        assertTrue(config.isSmartWhereEnabled());
        assertTrue(config.isPermissionGranted(GRANT_SMARTWHERE_TUNE_EVENTS));
    }

    public void testRevokePermission() throws Exception {
        TuneSmartWhereConfiguration config = new TuneSmartWhereConfiguration();

        config.grantAll();
        assertTrue(config.isPermissionGranted(GRANT_SMARTWHERE_TUNE_EVENTS));

        config.revoke(GRANT_SMARTWHERE_TUNE_EVENTS);
        assertFalse(config.isPermissionGranted(GRANT_SMARTWHERE_TUNE_EVENTS));
    }

    public void testRevokeAllPermissions() throws Exception {
        TuneSmartWhereConfiguration config = new TuneSmartWhereConfiguration();

        config.grantAll();
        assertTrue(config.isPermissionGranted(GRANT_SMARTWHERE_TUNE_EVENTS));

        config.revokeAll();
        assertFalse(config.isSmartWhereEnabled());
        assertFalse(config.isPermissionGranted(GRANT_SMARTWHERE_TUNE_EVENTS));
    }

    public void testSerialization() {
        TuneSmartWhereConfiguration config = new TuneSmartWhereConfiguration();

        config.grantAll();
        String str = config.toString();

        TuneSmartWhereConfiguration config2 = new TuneSmartWhereConfiguration(str);
        assertTrue(config2.isPermissionGranted(GRANT_SMARTWHERE_TUNE_EVENTS));
    }

}
