package com.tune.ma.connected;

import android.util.Log;

import com.tune.TuneTestConstants;
import com.tune.TuneUnitTest;
import com.tune.ma.TuneManager;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.TuneConnectedModeTurnedOn;
import com.tune.mocks.MockApi;

/**
 * Created by johng on 2/4/16.
 */
public class TuneConnectedModeTests extends TuneUnitTest {
    private TuneConnectedModeManager connectedModeManager;
    private MockApi mockApi;

    @Override
    protected void setUp() throws Exception {
        super.setUp();

        connectedModeManager = TuneManager.getInstance().getConnectedModeManager();

        mockApi = new MockApi();
        TuneManager.getInstance().setApi(mockApi);
    }

    @Override
    protected void tearDown() throws Exception {
        // App background always ends connected mode
        TuneEventBus.post(new TuneAppBackgrounded());

        mockApi = null;
        super.tearDown();
    }

    public void testConnectedCallsConnect() {
        // Spoof connected mode being turned on
        TuneEventBus.post(new TuneConnectedModeTurnedOn());

        sleep(TuneTestConstants.ENDPOINTTEST_SLEEP);

        // Assert that manager saw connected as true
        assertTrue(connectedModeManager.isInConnectedMode());
        // Assert that a connect call was made
        assertEquals(1, mockApi.getConnectCount());
        // Assert that a sync call was made
        assertEquals(1, mockApi.getSyncCount());
    }

// TODO: REVISIT.  Timing on this is too weird to fix.
// Jennifer checked this test Dec 2017 (in case some of John's IMv2 fixes had improved stability in running it.)
// It's still inconsistent failing with no obvious pattern as to why, so remains commented out.
//    public void testConnectedCallsEvent() {
//        // Spoof connected mode being turned on
//        TuneEventBus.post(new TuneConnectedModeTurnedOn());
//
//        // Start sending custom events
//        TuneEventBus.post(new TuneAppForegrounded("session1", 1L));
//
//        sleep(TuneTestConstants.ENDPOINTTEST_SLEEP);
//
//        // Measure an event
//        tune.measureEvent("connectedEvent");
//
//        assertTrue(waitForTuneNotification(TuneTestConstants.ENDPOINTTEST_SLEEP));
//
//        // Analytics event should go directly through the connected port
//        assertEquals(2, mockApi.getConnectedAnalyticsPostCount());
//        // Assert that the event name sent over connected port is the same one we just measured
//        assertEquals("connectedEvent", mockApi.getPostedConnectedEvent().optJSONObject("event").optString("action"));
//    }

    public void testDisconnect() {
        // Spoof connected mode being turned on
        TuneEventBus.post(new TuneConnectedModeTurnedOn());

        // Spoof connected mode being turned off via app background
        TuneEventBus.post(new TuneAppBackgrounded());

        sleep(TuneTestConstants.ENDPOINTTEST_SLEEP);

        // Assert that connected mode manager set connected to false
        assertFalse(connectedModeManager.isInConnectedMode());
        // Assert that a disconnect call was made on app background when connected mode was on
        assertEquals(1, mockApi.getDisconnectCount());
    }
}
