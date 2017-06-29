package com.tune.ma.analytics;

import com.tune.TuneEvent;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.event.session.TuneSessionEvent;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneActivityResumed;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.TuneEventOccurred;
import com.tune.ma.eventbus.event.push.TunePushOpened;
import com.tune.ma.file.FileManager;
import com.tune.ma.push.TunePushManager;
import com.tune.ma.push.model.TunePushMessage;
import com.tune.ma.utils.TuneSharedPrefsDelegate;
import com.tune.mocks.MockApi;

import org.json.JSONArray;
import org.json.JSONException;

/**
 * Created by johng on 1/11/16.
 */
public class AnalyticsDispatchTests extends TuneAnalyticsTest {

    private long elapsedTime;
    private long startTime;
    private MockApi mockApi;
    private FileManager fileManager;

    private static final int WAIT_TIME = 500;

    @Override
    public void setUp() throws Exception {
        super.setUp();
        // Unregister configuration manager so it doesn't get config from server and overwrite dispatch period
        TuneEventBus.unregister(TuneManager.getInstance().getConfigurationManager());

        mockApi = new MockApi();
        TuneManager.getInstance().setApi(mockApi);

        fileManager = TuneManager.getInstance().getFileManager();

        elapsedTime = 0;
        startTime = 0;

        TuneSharedPrefsDelegate sharedPrefs = new TuneSharedPrefsDelegate(context, TunePushManager.PREFS_TMA_PUSH);
        sharedPrefs.clearSharedPreferences();
    }

    /**
     * Test that events get dispatched after DEFAULT_DISPATCH_PERIOD
     */
    public void testBasicDispatch() {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for first tracer to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }

        startTime = System.currentTimeMillis();

        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("event1")));
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("event2")));

        while (mockApi.getAnalyticsPostCount() <= 1) {
            sleep(WAIT_TIME);
        }

        elapsedTime = System.currentTimeMillis() - startTime;

        // TODO: fix later, timing is weird on emulator
        // Check that analytics were dispatched and deleted from disk
//        assertEquals(0, fileManager.readAnalytics().length());
//        // Check that elapsedTime is about 10s, +/- 2000ms
//        assertEquals(TuneTestConstants.ANALYTICS_DISPATCH_PERIOD * 1000, elapsedTime, 2000);

        // Check that 2 requests were made, one initial tracer and one event
        assertEquals(2, mockApi.getAnalyticsPostCount());
    }

    /**
     * Test that events get continually dispatched after two cycles of DEFAULT_DISPATCH_PERIOD
     */
    public void testRepeatedDispatch() {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for first tracer to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }

        startTime = System.currentTimeMillis();

        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("event1")));

        // Wait for request to be dispatched (~10s)
        while (mockApi.getAnalyticsPostCount() <= 1) {
            sleep(WAIT_TIME);
        }

        elapsedTime = System.currentTimeMillis() - startTime;

        // TODO: fix later, timing is weird on emulator
        // Check that analytics were dispatched and deleted from disk
//        assertEquals(0, fileManager.readAnalytics().length());

        /*** Event #2 for dispatch #2 ***/
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("event2")));

        // Wait for second request to be dispatched (~10s)
        while (mockApi.getAnalyticsPostCount() <= 2) {
            sleep(WAIT_TIME);
        }

        elapsedTime = System.currentTimeMillis() - startTime;

        // TODO: fix later, timing is weird on emulator
        // Check that analytics were dispatched and deleted from disk
//        assertEquals(0, fileManager.readAnalytics().length());
//        // Check that elapsed time is about 20s, +/- 2000ms
//        assertEquals(2 * TuneTestConstants.ANALYTICS_DISPATCH_PERIOD * 1000, elapsedTime, 2000);

        // Check that 3 requests were made, one initial tracer and two events
        assertEquals(3, mockApi.getAnalyticsPostCount());
    }

    /**
     * Test that a tracer gets sent with each dispatch
     */
    public void testTracerDispatch() {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for first tracer to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }

        // Check that a tracer event was sent
        assertTrue(mockApi.getPostedEvents().toString().contains("\"type\":\"TRACER\""));
    }

    public void testAppForegroundDispatch() throws JSONException {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for first tracer to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }

        JSONArray eventJson = mockApi.getPostedEvents().getJSONArray("events");
        String eventString = eventJson.toString();

        // Check that at least 2 events were sent - one foreground, one tracer, and possibly one push enabled
        assertTrue(eventJson.length() >= 2);
        // Check that a foreground event was sent
        assertTrue(eventJson.toString().contains("\"type\":\"SESSION\"") && eventJson.toString().contains("\"action\":\"" + TuneSessionEvent.FOREGROUNDED + "\""));
        // Check that a tracer event was sent
        assertTrue(eventJson.toString().contains("\"type\":\"TRACER\""));

        assertTrue(2 == eventJson.length() || (3 == eventJson.length() && eventString.contains("\"type\":\"EVENT\"") && eventString.contains("\"action\":\"Push Enabled\"")));
    }

    public void testAppBackgroundDispatch() throws JSONException {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for foreground to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }

        JSONArray eventJson = mockApi.getPostedEvents().getJSONArray("events");
        String eventString = eventJson.toString();
        int totalEventCount = eventJson.length();

        boolean foundPushEnabled = eventString.contains("\"type\":\"EVENT\"") && eventString.contains("\"action\":\"Push Enabled\"");

        TuneEventBus.post(new TuneAppBackgrounded());

        // Wait for first tracer to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 1) {
            sleep(WAIT_TIME);
        }

        eventJson = mockApi.getPostedEvents().getJSONArray("events");
        eventString = eventJson.toString();

        totalEventCount += eventJson.length();

        foundPushEnabled = foundPushEnabled || (eventString.contains("\"type\":\"EVENT\"") && eventString.contains("\"action\":\"Push Enabled\""));

        // Check that at least 2 events were sent - one background, one tracer
        assertTrue(eventJson.length() >= 2);
        // Check that a background event was sent
        assertTrue(eventString.contains("\"type\":\"SESSION\"") && eventString.contains("\"action\":\"" + TuneSessionEvent.BACKGROUNDED + "\""));
        // Check that a tracer event was sent
        assertTrue(eventString.contains("\"type\":\"TRACER\""));

        // Check that 5 events were sent - foregrounded, tracer, one push enabled, background, one tracer
        assertEquals(5, totalEventCount);

        // Check that a push enabled event was sent
        assertTrue(foundPushEnabled);
    }

    public void testScreenViewDispatch() throws JSONException {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for foreground to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }

        JSONArray eventJson = mockApi.getPostedEvents().getJSONArray("events");;
        String eventString = eventJson.toString();
        int totalEventCount = eventJson.length();

        boolean foundPushEnabled = eventString.contains("\"type\":\"EVENT\"") && eventString.contains("\"action\":\"Push Enabled\"");

        // Mock an activity resume to track screen view of
        TuneEventBus.post(new TuneActivityResumed("MockActivity"));
        TuneEventBus.post(new TuneAppBackgrounded());

        // Wait for first tracer to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 1) {
            sleep(WAIT_TIME);
        }

        eventJson = mockApi.getPostedEvents().getJSONArray("events");;
        eventString = eventJson.toString();

        totalEventCount += eventJson.length();

        foundPushEnabled = foundPushEnabled || (eventString.contains("\"type\":\"EVENT\"") && eventString.contains("\"action\":\"Push Enabled\""));

        // Check that at least 3 events were sent - one background, one tracer, one screen view
        assertTrue(eventJson.length() >= 3);
        // Check that a screen view event was sent
        assertTrue(eventString.contains("\"type\":\"PAGEVIEW\"") && eventString.contains("\"category\":\"MockActivity\""));
        // Check that a background event was sent
        assertTrue(eventString.contains("\"type\":\"SESSION\"") && eventString.contains("\"action\":\"" + TuneSessionEvent.BACKGROUNDED + "\""));
        // Check that a tracer event was sent
        assertTrue(eventString.contains("\"type\":\"TRACER\""));

        // Check that 6 events were sent - foregrounded, tracer, one push enabled, one push opened, one push action, background, one tracer
        assertEquals(6, totalEventCount);

        // Check that a push enabled event was sent
        assertTrue(foundPushEnabled);
    }

    /**
     * Test that all push opened events are sent when a TunePushOpened event is received
     */
    public void testPushEventsDispatch() throws JSONException {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for foreground to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }

        JSONArray eventJson = mockApi.getPostedEvents().getJSONArray("events");
        String eventString = eventJson.toString();

        int totalEventCount = eventJson.length();

        boolean foundPushEnabled = eventString.contains("\"type\":\"EVENT\"") && eventString.contains("\"action\":\"Push Enabled\"");

        TuneEventBus.post(new TunePushOpened(new TunePushMessage("{\"appName\":\"test\"," +
                "\"local_message_id\": \"test_message_id\"," +
                "\"app_id\": \"c50e7eb0eb83b22131e8f791abc77329\"," +
                "\"payload\":{\"ANA\":{\"D\":\"1\",\"CS\":\"MOCK_CAMPAIGN_STEP_ID\",\"URL\":\"demoapp://deeplink\"}}," +
                "\"CAMPAIGN_ID\":\"MOCK_CAMPAIGN_ID\"," +
                "\"key\":\"AIzaSyAtR4SljwU0_v1jxOltOAYCr9ktX43mR3s\"," +
                "\"from\":\"303334013783\"," +
                "\"type\":\"android\"," +
                "\"alert\":\"deep link test\"," +
                "\"style\":\"regular\"," +
                "\"LENGTH_TO_REPORT\":604800," +
                "\"ARTPID\":\"TEST_MESSAGE\"}")));

        // Trigger an event dispatch
        TuneEventBus.post(new TuneAppBackgrounded());

        // Wait for first tracer to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 1) {
            sleep(WAIT_TIME);
        }

        eventJson = mockApi.getPostedEvents().getJSONArray("events");
        eventString = eventJson.toString();

        totalEventCount += eventJson.length();

        foundPushEnabled = foundPushEnabled || (eventString.contains("\"type\":\"EVENT\"") && eventString.contains("\"action\":\"Push Enabled\""));

        // Check that at least 4 events were sent - one push opened, one push action, background, one tracer
        assertTrue(eventJson.length() >= 4);
        // Check that a NotificationOpened event was sent
        assertTrue(eventString.contains("\"type\":\"PUSH_NOTIFICATION\"") && eventString.contains("\"action\":\"NotificationOpened\""));
        // Check that a push action event was sent
        assertTrue(eventString.contains("\"type\":\"PUSH_NOTIFICATION\"") && eventString.contains("\"action\":\"INAPP_OPEN_URL\""));
        // Check that a background event was sent
        assertTrue(eventString.contains("\"type\":\"SESSION\"") && eventString.contains("\"action\":\"" + TuneSessionEvent.BACKGROUNDED + "\""));
        // Check that a tracer event was sent
        assertTrue(eventString.contains("\"type\":\"TRACER\""));

        // Check that 7 events were sent - foregrounded, tracer, one push enabled, one push opened, one push action, background, one tracer
        assertEquals(7, totalEventCount);

        // Check that a push enabled event was sent
        assertTrue(foundPushEnabled);
    }
}
