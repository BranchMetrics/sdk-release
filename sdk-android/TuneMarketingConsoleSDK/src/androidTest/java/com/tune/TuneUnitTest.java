package com.tune;

import android.test.AndroidTestCase;
import android.util.Log;

import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneGetAdvertisingIdCompleted;
import com.tune.ma.profile.TuneUserProfile;
import com.tune.ma.push.TunePushManager;
import com.tune.ma.utils.TuneSharedPrefsDelegate;

import org.json.JSONObject;

import java.util.UUID;

public class TuneUnitTest extends AndroidTestCase implements TuneTestRequest {
    private static final String logTag = "TUNE Tests";

    protected TuneTestWrapper tune;
    TuneTestParams params;
    TuneTestQueue queue;

    public TuneUnitTest() {
        super();
    }

    @Override
    protected void setUp() throws Exception {
        super.setUp();
        Log.d(logTag, "***SETUP STARTED***");

        // Clear the Tune User Profile settings.  Note that this should have called
        // <code> new TuneUserProfile(getContext()).deleteSharedPrefs(); </code> but the constructor
        // for TuneUserProfile is very expensive.
        new TuneSharedPrefsDelegate(getContext(), TuneUserProfile.PREFS_TMA_PROFILE).clearSharedPreferences();
        new TuneSharedPrefsDelegate(getContext(), TunePushManager.PREFS_TMA_PUSH).clearSharedPreferences();

        tune = TuneTestWrapper.init(getContext(), TuneTestConstants.advertiserId, TuneTestConstants.conversionKey);
        tune.setGoogleAdvertisingId("4e45e24e-8f30-4651-98ec-a80c0fb08eb5", true);
        tune.setTuneTestRequest(this);
        TuneEventBus.post(new TuneGetAdvertisingIdCompleted(TuneGetAdvertisingIdCompleted.Type.GOOGLE_AID, UUID.randomUUID().toString(), false));

        queue = tune.getEventQueue();
        params = new TuneTestParams();

        tune.waitForInit(TuneTestConstants.SERVERTEST_SLEEP);
        Log.d(logTag, "***SETUP COMPLETE***");
    }

    @Override
    protected void tearDown() throws Exception {
        Log.d(logTag, "***TEARDOWN STARTED***");

        if (tune != null) {
            tune.shutDown();
            queue.clearQueue();
        }

        queue = null;
        tune = null;

        Log.d(logTag, "***TEARDOWN COMPLETE***");
        super.tearDown();
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
}
