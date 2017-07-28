package com.tune.smartwhere;

import com.tune.BuildConfig;
import com.tune.Tune;
import com.tune.TuneConfigurationException;
import com.tune.TuneUnitTest;
import com.tune.TuneUtils;

public class TuneSmartWhereTestExistence extends TuneUnitTest {

    public void testExistence() throws Exception {
        assertTrue(TuneSmartWhere.isSmartWhereAvailable());
    }

    public void testVersionAttribution() throws Exception {
        String version = Tune.getSDKVersion();
        TuneUtils.log("Gradle Build Version: " + BuildConfig.VERSION_NAME);
        assertFalse(version.contains("-"));
    }

    public void testEnableSmartWhere() throws Exception {
        boolean success = true;

        try {
            Tune.getInstance().enableSmartWhere();
        } catch (TuneConfigurationException e) {
            success = false;
        }

        // SmartWhere does exist in this flavor.
        assertTrue(success);
    }
}
