package com.tune.smartwhere;

import com.tune.TuneUnitTest;

import static com.tune.smartwhere.TuneSmartWhereConfiguration.GRANT_SMARTWHERE_OPT_IN;

/**
 * SmartWhere Configuration Tests -- when SmartWhere is not available.
 */
public class SmartWhereConfigurationTests extends TuneUnitTest {

    public void testOptIn() throws Exception {
        TuneSmartWhereConfiguration config = new TuneSmartWhereConfiguration();

        config.grant(GRANT_SMARTWHERE_OPT_IN);
        assertFalse(config.isSmartWhereEnabled());
    }
}
