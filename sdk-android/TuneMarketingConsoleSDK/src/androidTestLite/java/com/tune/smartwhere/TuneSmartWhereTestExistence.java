package com.tune.smartwhere;

import com.tune.BuildConfig;
import com.tune.Tune;
import com.tune.TuneConfigurationException;
import com.tune.TuneUnitTest;
import com.tune.TuneUtils;

public class TuneSmartWhereTestExistence extends TuneUnitTest {
    private static final String TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_PROXIMITYCONTROL = "com.proximity.library.ProximityControl";

    public void testExistence() throws Exception {
        // Note that we can't check existence via. the public API, because the unit test mocking layer
        // is pretending that the class does in fact exist.
        // In this case we are going to do the forName check ourselves.
        //
        Class clazz = null;
        try {
            clazz = Class.forName(TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_PROXIMITYCONTROL);
        } catch (ClassNotFoundException e) {
        }

        assertNull(clazz);
    }

    public void testVersionAttribution() throws Exception {
        String version = Tune.getSDKVersion();
        TuneUtils.log("Gradle Build Version: " + BuildConfig.VERSION_NAME);
        assertTrue(version.endsWith("-lite"));
    }

    public void testEnableSmartWhere() throws Exception {
        boolean success = true;

        try {
            Tune.getInstance().enableSmartWhere();
        } catch (TuneConfigurationException e) {
            success = false;
        }

        // SmartWhere does not exist in this flavor.
        assertFalse(success);
    }
}
