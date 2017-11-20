package com.tune;

public class TuneStartupTests extends TuneUnitTest {
    private static final int RETRY_TOTAL = 10;

    public void testStartupShutdown() {
        int attempt = 0;

        // The first startUp happens for us by the test framework.  Tear it down
        try {
            tearDown();
        } catch (Exception e) {
            assertFalse("First Teardown Failed", true);
        }

        try {
            for (attempt = 0; attempt < RETRY_TOTAL; attempt++) {
                setUp();
                tune.measureEvent("registration");
                sleep(0);
                tearDown();
            }
        } catch (Exception e) {
            assertFalse("Failure on attempt #" + attempt, true);
        }

        // Now we have to set it back up again so the test framework can shut it down correctly.
        try {
            setUp();
        } catch (Exception e) {
            assertFalse("Final SetUp Failed", true);
        }
    }
}
