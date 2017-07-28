package com.tune;

import android.content.Context;
import android.test.AndroidTestCase;
import android.util.Log;

import com.tune.ma.TuneManager;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneGetAdvertisingIdCompleted;

import org.json.JSONObject;

import java.util.UUID;
import java.util.concurrent.TimeUnit;

public class TuneUnitTest extends AndroidTestCase implements TuneTestRequest {
    protected static final String logTag = "TUNE Tests";

    protected TuneTestWrapper tune;
    protected TuneTestParams params;
    protected TuneTestQueue queue;

    public TuneUnitTest() {
        super();
    }

    @Override
    protected void setUp() throws Exception {
        super.setUp();

        getContext().getSharedPreferences("com.tune.ma.profile", Context.MODE_PRIVATE).edit().clear().apply();

        tune = TuneTestWrapper.init(getContext(), TuneTestConstants.advertiserId,
                TuneTestConstants.conversionKey);
        tune.setGoogleAdvertisingId("4e45e24e-8f30-4651-98ec-a80c0fb08eb5", true);
        tune.setTuneTestRequest(this);
        TuneEventBus.post(new TuneGetAdvertisingIdCompleted(TuneGetAdvertisingIdCompleted.Type.GOOGLE_AID, UUID.randomUUID().toString(), false));

        if (tune != null) { // could be null if test has finished already
            queue = tune.getEventQueue();
            queue.clearQueue();
        }

        params = new TuneTestParams();
    }

    @Override
    protected void tearDown() throws Exception {
        if (tune != null) {
            tune.removeBroadcastReceiver();
            tune.clearSharedPrefs();
            tune.pool.shutdown();
            tune.pool.awaitTermination(5, TimeUnit.SECONDS);
            tune.getPubQueue().shutdownNow();
            tune.setOnline(true);
            tune.clearSharedPrefs();
            if (queue != null) {
                queue.clearQueue();
            }
            TuneManager.destroy();
        }
        tune.clearParams();
        tune = null;
        params = null;
        queue = null;

        TuneEventBus.clearFlags();
        TuneEventBus.disable();

        super.tearDown();
    }

    public static void sleep(int millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    public void assertKeyValue(String key, String value) {
        if (!value.equals(params.valueForKey(key)))
            Log.d(logTag, "failing params are " + params);
        assertTrue("key '" + key + "' must equal '" + value + "', found '"
                + params.valueForKey(key) + "' instead",
                value.equals(params.valueForKey(key)));
    }

    public void assertHasValueForKey( String key ) {
        assertTrue( "must have a value for '" + key + "', found none",
                params.checkKeyHasValue( key ) );
    }

    public void assertNoValueForKey(String key) {
        assertFalse(
                "must not have a value for '" + key + "', found '"
                        + params.valueForKey(key) + "'",
                params.checkKeyHasValue(key));
    }

    protected void Log(String string) {
        Log.d(logTag, string);
    }

    // request callback
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
    }
}
