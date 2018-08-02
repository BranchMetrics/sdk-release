package com.tune;

import android.content.res.Configuration;
import android.content.res.Resources;
import android.util.Log;

import org.json.JSONObject;
import org.junit.After;
import org.junit.Before;

import java.util.Locale;

import static android.support.test.InstrumentationRegistry.getContext;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

public class TuneUnitTest implements TuneTestRequest {
    private static final String logTag = "TUNE Tests";

    protected TuneTestWrapper tune;
    TuneTestParams params;
    TuneTestQueue queue;

    public TuneUnitTest() {
        super();
    }

    @Before
    public void setUp() throws Exception {
        Log.d(logTag, "***SETUP STARTED***");

        // To perform the unit tests under a different locale, uncomment the following line
        // setLocale("az", "AZ");

        tune = TuneTestWrapper.init(getContext(), TuneTestConstants.advertiserId, TuneTestConstants.conversionKey, TuneTestConstants.appId);
        tune.setGoogleAdvertisingId("4e45e24e-8f30-4651-98ec-a80c0fb08eb5", true);
        tune.setTestRequest(this);

        queue = tune.getEventQueue();
        params = new TuneTestParams();

        assertTrue(tune.waitForInit(TuneTestConstants.SERVERTEST_SLEEP));
        Log.d(logTag, "***SETUP COMPLETE***");
    }

    @After
    public void tearDown() throws Exception {
        Log.d(logTag, "***TEARDOWN STARTED***");

        if (tune != null) {
            tune.shutDown();
            queue.clearQueue();
        }

        queue = null;
        tune = null;

        Log.d(logTag, "***TEARDOWN COMPLETE***");
    }

    public static void sleep(int millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    void assertKeyValue(String key, String value) {
        if (!value.equals(params.valueForKey(key)))
            Log.d(logTag, "failing params are " + params);
        assertTrue("key '" + key + "' must equal '" + value + "', found '"
                + params.valueForKey(key) + "' instead",
                value.equals(params.valueForKey(key)));
    }

    void assertHasValueForKey( String key ) {
        assertTrue( "must have a value for '" + key + "', found none",
                params.checkKeyHasValue( key ) );
    }

    void assertNoValueForKey(String key) {
        assertFalse(
                "must not have a value for '" + key + "', found '"
                        + params.valueForKey(key) + "'",
                params.checkKeyHasValue(key));
    }

    void Log(String string) {
        Log.d(logTag, string);
    }

    // request callback
    private final Object mTestWaitObject = new Object();
    public void constructedRequest(String url, String data, JSONObject postBody) {
        if (params == null)
            return;
        String urlPieces[] = url.split("\\?");
        assertTrue("extracting params failed from " + url,
                params.extractParamsString(urlPieces[1]));
        assertTrue("extracting params failed from " + data,
                params.extractParamsString(data));
        assertTrue("extracting JSON failed from " + postBody,
                params.extractParamsJSON(postBody));

        synchronized (mTestWaitObject) {
            mTestWaitObject.notify();
        }
    }

    boolean waitForTuneNotification(long milliseconds) {
        boolean rc = false;
        synchronized (mTestWaitObject) {
            try {
                mTestWaitObject.wait(milliseconds);
                rc = true;
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        return rc;
    }

    /**
     * Helper method to set the Locale based on a given Language and Country
     * @param language lowercase 2 to 8 language code.
     * @param country uppercase two-letter ISO-3166 code and numric-3 UN M.49 area code.
     */
    void setLocale(String language, String country) {
        Locale locale = new Locale(language, country);
        // here we update locale for date formatters
        Locale.setDefault(locale);

        // here we update locale for app resources
        Resources res = getContext().getResources();
        Configuration config = res.getConfiguration();
        config.locale = locale;
        res.updateConfiguration(config, res.getDisplayMetrics());
    }
}
