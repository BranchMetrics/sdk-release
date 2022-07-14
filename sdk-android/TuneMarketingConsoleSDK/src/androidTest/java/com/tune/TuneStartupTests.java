package com.tune;

import androidx.test.ext.junit.runners.AndroidJUnit4;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import static androidx.test.platform.app.InstrumentationRegistry.getContext;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

@RunWith(AndroidJUnit4.class)
public class TuneStartupTests extends TuneUnitTest {
    private static final int RETRY_TOTAL = 10;

    @Before
    public void setUp() {
        // Intentionally not calling super.setUp() so that we can control this at the unit
        // test level.
    }

    @After
    public void tearDown() {
        // Intentionally not calling super.tearDown() so that we can control this at the unit
        // test level.
    }

    @Test
    public void testStartupShutdown() {
        int attempt = 0;

        try {
            for (attempt = 0; attempt < RETRY_TOTAL; attempt++) {
                super.setUp();
                tune.measureEvent("registration");
                sleep(0);
                super.tearDown();
            }
        } catch (Exception e) {
            assertFalse("Failure on attempt #" + attempt, true);
        }
    }

    @Test
    public void testNullStartupPackage() {
        Tune.init(getContext(), TuneTestConstants.advertiserId, TuneTestConstants.conversionKey, null);

        TuneInternal tuneInternal = TuneInternal.getInstance();
        assertTrue(tuneInternal.waitForInit(TuneTestConstants.SERVERTEST_SLEEP));

        assertEquals(tuneInternal.getPackageName(), TuneTestConstants.appId);

        tuneInternal.shutDown();
    }

    @Test
    public void testAlternateStartupPackage() {
        String testPackage = "com.tune.testStartupPackage";
        Tune.init(getContext(), TuneTestConstants.advertiserId, TuneTestConstants.conversionKey, testPackage);

        TuneInternal tuneInternal = TuneInternal.getInstance();
        assertTrue(tuneInternal.waitForInit(TuneTestConstants.SERVERTEST_SLEEP));

        assertEquals(testPackage, tuneInternal.getPackageName());

        // SDK-77: Ensure that initialization completes with an alternate package name.
        assertTrue(tuneInternal.getTuneParams().didParametersInitializationComplete());

        tuneInternal.shutDown();
    }
}
