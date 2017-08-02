package com.tune.smartwhere;

import com.tune.BuildConfig;
import com.tune.Tune;
import com.tune.TuneConfigurationException;
import com.tune.TuneUtils;

public class TuneSmartwhereTestExistence extends TuneSmartWhereTests {

    public void testExistence() throws Exception {
        assertTrue(TuneSmartWhere.isSmartWhereAvailable());
    }

    public void testVersionAttribution() throws Exception {
        String version = Tune.getSDKVersion();
        TuneUtils.log("Gradle Build Version: " + BuildConfig.VERSION_NAME);
        assertFalse(version.contains("-"));
    }

    public void testNoOptIn() throws Exception {
        assertFalse(TuneSmartWhere.getInstance().isEnabled());
    }

    public void testEnableSmartWhere() throws Exception {
        boolean success = true;

        try {
            Tune.getInstance().enableSmartwhere();
        } catch (TuneConfigurationException e) {
            success = false;
        }

        // SmartWhere does exist in this flavor.
        assertTrue(success);

        assertTrue(TuneSmartWhere.getInstance().isEnabled());
    }

    public void testEnableDisableSmartWhere() throws Exception {
        boolean success = true;

        try {
            Tune.getInstance().enableSmartwhere();
            Tune.getInstance().disableSmartwhere();
        } catch (TuneConfigurationException e) {
            success = false;
        }

        // SmartWhere does exist in this flavor.
        assertTrue(success);
    }

    public void testEnableTuneSharing() throws Exception {
        boolean success = true;

        try {
            Tune.getInstance().enableSmartwhere();
            Tune.getInstance().configureSmartwhere(new TuneSmartwhereConfiguration()
                    .grant(TuneSmartwhereConfiguration.GRANT_SMARTWHERE_TUNE_EVENTS));
        } catch (TuneConfigurationException e) {
            success = false;
        }

        assertTrue(TuneSmartWhere.getInstance().isEnabled());
        assertTrue(TuneSmartWhere.getInstance().getConfiguration().isPermissionGranted(TuneSmartwhereConfiguration.GRANT_SMARTWHERE_TUNE_EVENTS));

        assertTrue(success);
    }

}
