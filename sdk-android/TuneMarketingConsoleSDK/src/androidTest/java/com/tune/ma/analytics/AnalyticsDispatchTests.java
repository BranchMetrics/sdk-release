package com.tune.ma.analytics;

import com.tune.TuneEvent;
import com.tune.TuneTestConstants;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.event.session.TuneSessionEvent;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneActivityResumed;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.TuneDeeplinkOpened;
import com.tune.ma.eventbus.event.TuneEventOccurred;
import com.tune.ma.eventbus.event.inapp.TuneInAppMessageActionTaken;
import com.tune.ma.eventbus.event.inapp.TuneInAppMessageShown;
import com.tune.ma.eventbus.event.push.TunePushOpened;
import com.tune.ma.inapp.TestInAppMessage;
import com.tune.ma.inapp.model.TuneTriggerEvent;
import com.tune.ma.push.TunePushManager;
import com.tune.ma.push.model.TunePushMessage;
import com.tune.ma.utils.TuneSharedPrefsDelegate;
import com.tune.mocks.MockApi;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import static com.tune.ma.analytics.model.event.inapp.TuneInAppMessageEvent.ANALYTICS_ACTION_SHOWN;
import static com.tune.ma.analytics.model.event.inapp.TuneInAppMessageEvent.ANALYTICS_CAMPAIGN_STEP_ID_KEY;
import static com.tune.ma.analytics.model.event.inapp.TuneInAppMessageEvent.ANALYTICS_MESSAGE_CLOSED;
import static com.tune.ma.analytics.model.event.inapp.TuneInAppMessageEvent.ANALYTICS_MESSAGE_DISMISSED_AUTOMATICALLY;
import static com.tune.ma.analytics.model.event.inapp.TuneInAppMessageEvent.ANALYTICS_SECONDS_DISPLAYED_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.LIFETIME_MAXIMUM_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.LIMIT_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_VALUE_INSTALL;

/**
 * Created by johng on 1/11/16.
 */
public class AnalyticsDispatchTests extends TuneAnalyticsTest {

    private static final int WAIT_TIME = TuneTestConstants.PARAMTEST_SLEEP;
    private MockApi mockApi;

    @Override
    public void setUp() throws Exception {
        super.setUp();
        // Unregister configuration manager so it doesn't get config from server and overwrite dispatch period
        TuneEventBus.unregister(TuneManager.getInstance().getConfigurationManager());

        mockApi = new MockApi();
        TuneManager.getInstance().setApi(mockApi);

        TuneSharedPrefsDelegate sharedPrefs = new TuneSharedPrefsDelegate(context, TunePushManager.PREFS_TMA_PUSH);
        sharedPrefs.clearSharedPreferences();
    }

    @Override
    public void tearDown() throws Exception {
        TuneManager.getInstance().setApi(null);
        mockApi = null;

        super.tearDown();
    }


    /**
     * Test that events get dispatched after DEFAULT_DISPATCH_PERIOD
     */
    public void testBasicDispatch() throws InterruptedException {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for first tracer to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }
        sleep(WAIT_TIME);

        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("event1")));
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("event2")));

        while (mockApi.getAnalyticsPostCount() <= 1) {
            sleep(WAIT_TIME);
        }
        sleep(WAIT_TIME);

        // Check that 2 requests were made, one initial tracer and one event
        assertEquals(2, mockApi.getAnalyticsPostCount());
    }

    /**
     * Test that events get continually dispatched after two cycles of DEFAULT_DISPATCH_PERIOD
     */
    public void testRepeatedDispatch() throws InterruptedException {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for first tracer to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }
        sleep(WAIT_TIME);

        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("event1")));

        // Wait for request to be dispatched (~10s)
        while (mockApi.getAnalyticsPostCount() <= 1) {
            sleep(WAIT_TIME);
        }
        sleep(WAIT_TIME);

        /*** Event #2 for dispatch #2 ***/
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("event2")));

        // Wait for second request to be dispatched (~10s)
        while (mockApi.getAnalyticsPostCount() <= 2) {
            sleep(WAIT_TIME);
        }
        sleep(WAIT_TIME);

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
        sleep(WAIT_TIME);

        // Check that a tracer event was sent
        assertTrue(mockApi.getPostedEvents().toString().contains("\"type\":\"TRACER\""));
    }

    public void testAppForegroundDispatch() throws JSONException {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for foreground to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }
        sleep(WAIT_TIME);

        JSONArray eventJson = mockApi.getPostedEvents().getJSONArray("events");
        String eventString = eventJson.toString();

        // Check that a foreground event was sent
        assertTrue("eventJson does not contain foregrounded event, was " + eventJson.toString(), eventJson.toString().contains("\"type\":\"SESSION\"") && eventJson.toString().contains("\"action\":\"" + TuneSessionEvent.FOREGROUNDED + "\""));
        // Check that a tracer event was sent
        assertTrue(eventJson.toString().contains("\"type\":\"TRACER\""));
        // Check that at least 2 events were sent - one foreground, one tracer, and possibly one push enabled
        assertTrue("eventJson length not 2, was " + eventJson.length(), eventJson.length() >= 2);
        assertTrue(2 == eventJson.length() || (3 == eventJson.length() && eventString.contains("\"type\":\"EVENT\"") && eventString.contains("\"action\":\"Push Enabled\"")));

    }

    public void testAppBackgroundDispatch() throws JSONException {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for foreground to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }
        sleep(WAIT_TIME);

        JSONArray eventJson = mockApi.getPostedEvents().getJSONArray("events");
        String eventString = eventJson.toString();
        int totalEventCount = eventJson.length();

        boolean foundPushEnabled = hasPushEnabled(eventString);

        TuneEventBus.post(new TuneAppBackgrounded());

        // Wait for first tracer to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 1) {
            sleep(WAIT_TIME);
        }
        sleep(WAIT_TIME);

        eventJson = mockApi.getPostedEvents().getJSONArray("events");
        eventString = eventJson.toString();

        totalEventCount += eventJson.length();

        foundPushEnabled = foundPushEnabled || hasPushEnabled(eventString);

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
        sleep(WAIT_TIME);

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
        sleep(WAIT_TIME);

        eventJson = mockApi.getPostedEvents().getJSONArray("events");
        eventString = eventJson.toString();

        totalEventCount += eventJson.length();

        foundPushEnabled = foundPushEnabled || hasPushEnabled(eventString);

        // Check that a screen view event was sent
        assertTrue(eventString.contains("\"type\":\"PAGEVIEW\"") && eventString.contains("\"category\":\"MockActivity\""));
        // Check that a background event was sent
        assertTrue(eventString.contains("\"type\":\"SESSION\"") && eventString.contains("\"action\":\"" + TuneSessionEvent.BACKGROUNDED + "\""));
        // Check that a tracer event was sent
        assertTrue(eventString.contains("\"type\":\"TRACER\""));
        // Check that at least 3 events were sent - one background, one tracer, one screen view
        assertTrue("events length was " + eventJson.length(), eventJson.length() >= 3);

        // Check that 6 events were sent - foregrounded, tracer, one push enabled, one push opened, one push action, background, one tracer
        assertEquals(6, totalEventCount);

        // Check that a push enabled event was sent
        assertTrue(foundPushEnabled);
    }

    /**
     * Test that all push opened events are sent when a TunePushOpened event is received
     */
    public void testPushEventsDispatch() throws InterruptedException, JSONException {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for foreground to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }
        sleep(WAIT_TIME);

        JSONArray eventJson = mockApi.getPostedEvents().getJSONArray("events");
        String eventString = eventJson.toString();

        int totalEventCount = eventJson.length();

        boolean foundPushEnabled = hasPushEnabled(eventString);

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
        sleep(WAIT_TIME);

        eventJson = mockApi.getPostedEvents().getJSONArray("events");
        eventString += eventJson.toString();

        totalEventCount += eventJson.length();

        foundPushEnabled = foundPushEnabled || hasPushEnabled(eventString);

        // Check that at least 4 events were sent - one push opened, one push action, background, one tracer
        assertTrue("events length was " + eventJson.length(), eventJson.length() >= 4);
        // Check that a NotificationOpened event was sent
        assertTrue(eventString.contains("\"type\":\"PUSH_NOTIFICATION\"") && eventString.contains("\"action\":\"NotificationOpened\""));
        // Check that a push action event was sent
        assertTrue(eventString.contains("\"type\":\"PUSH_NOTIFICATION\"") && eventString.contains("\"action\":\"INAPP_OPEN_URL\""));
        // Check that a background event was sent
        assertTrue(eventString.contains("\"type\":\"SESSION\"") && eventString.contains("\"action\":\"" + TuneSessionEvent.BACKGROUNDED + "\""));
        // Check that a tracer event was sent
        assertTrue(eventString.contains("\"type\":\"TRACER\""));

        // Check that 7 events were sent - foregrounded, tracer, one push enabled, one push opened, one push action, background, one tracer
//        assertEquals(7, totalEventCount);

        // Check that a push enabled event was sent
        assertTrue(foundPushEnabled);
    }

    private boolean hasPushEnabled(String eventString) {
//        TuneUtils.log("*** Push Enabled Check: " + eventString);
        return eventString.contains("\"type\":\"EVENT\"") && eventString.contains("\"action\":\"Push Enabled\"");
    }

    // Test that a DeeplinkOpened event with the deeplink url is sent when a deeplink open is detected
    public void testDeeplinkOpenedDispatch() throws JSONException {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for foreground to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }

        TuneEventBus.post(new TuneDeeplinkOpened("myapp://deeplink/path?dog=maru&user=john"));

        // Trigger an event dispatch
        TuneEventBus.post(new TuneAppBackgrounded());

        // Wait for first tracer to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 1) {
            sleep(WAIT_TIME);
        }

        JSONArray eventJson = mockApi.getPostedEvents().getJSONArray("events");
        String eventString = eventJson.toString();

        // Check that at least 3 events were sent - one deeplink opened, background, tracer
        assertTrue("events length was " + eventJson.length(), eventJson.length() >= 3);
        // Check that a deeplink opened event was sent
        assertTrue(eventString.contains("\"type\":\"APP_OPENED_BY_URL\"") && eventString.contains("\"action\":\"DeeplinkOpened\"") && eventString.contains("\"category\":\"myapp:\\/\\/deeplink\\/path\""));
        // Check that the url query param tags are sent
        assertTrue(eventString.contains("{\"name\":\"dog\",\"value\":\"maru\",\"type\":\"string\"}") && eventString.contains("{\"name\":\"user\",\"value\":\"john\",\"type\":\"string\"}"));
        // Check that a background event was sent
        assertTrue(eventString.contains("\"type\":\"SESSION\"") && eventString.contains("\"action\":\"" + TuneSessionEvent.BACKGROUNDED + "\""));
        // Check that a tracer event was sent
        assertTrue(eventString.contains("\"type\":\"TRACER\""));
    }

    public void testInAppMessageShownDispatch() throws JSONException {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for foreground to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }

        // Build a dummy message with frequency limit
        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 0);
        frequencyJson.put(LIMIT_KEY, 0);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_INSTALL);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent("bd283b48a9290740ff92abb432571b80", frequencyJson);
        TestInAppMessage message = new TestInAppMessage("123", "abcdefg", triggerEvent);

        // Notify that a message was shown
        TuneEventBus.post(new TuneInAppMessageShown(message));

        // Trigger an event dispatch
        TuneEventBus.post(new TuneAppBackgrounded());

        // Wait for first tracer to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 1) {
            sleep(WAIT_TIME);
        }

        JSONArray eventJson = mockApi.getPostedEvents().getJSONArray("events");
        String eventString = eventJson.toString();

        // Check that at least 3 events were sent - one message shown, background, tracer
        assertTrue("events length was " + eventJson.length(), eventJson.length() >= 3);
        // Check that a message shown event was sent
        assertTrue(eventString.contains("\"type\":\"IN_APP_MESSAGE\"") && eventString.contains("\"action\":\"" + ANALYTICS_ACTION_SHOWN + "\""));
        // Check that the url query param tags are sent
        assertTrue(eventString.contains("{\"name\":\"" + ANALYTICS_CAMPAIGN_STEP_ID_KEY + "\",\"value\":\"abcdefg\",\"type\":\"string\"}"));
        // Check that a background event was sent
        assertTrue(eventString.contains("\"type\":\"SESSION\"") && eventString.contains("\"action\":\"" + TuneSessionEvent.BACKGROUNDED + "\""));
        // Check that a tracer event was sent
        assertTrue(eventString.contains("\"type\":\"TRACER\""));
    }

    public void testInAppMessageDismissedDispatch() throws JSONException {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for foreground to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }

        // Build a dummy message with frequency limit
        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 0);
        frequencyJson.put(LIMIT_KEY, 0);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_INSTALL);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent("bd283b48a9290740ff92abb432571b80", frequencyJson);
        TestInAppMessage message = new TestInAppMessage("123", "abcdefg", triggerEvent);

        // Notify that message was closed
        TuneEventBus.post(new TuneInAppMessageActionTaken(message, ANALYTICS_MESSAGE_CLOSED, 5));

        // Trigger an event dispatch
        TuneEventBus.post(new TuneAppBackgrounded());

        // Wait for first tracer to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 1) {
            sleep(WAIT_TIME);
        }

        JSONArray eventJson = mockApi.getPostedEvents().getJSONArray("events");
        String eventString = eventJson.toString();

        // Check that at least 3 events were sent - one message dismissed, background, tracer
        assertTrue("events length was " + eventJson.length(), eventJson.length() >= 3);
        // Check that a message shown event was sent
        assertTrue(eventString.contains("\"type\":\"IN_APP_MESSAGE\"") && eventString.contains("\"action\":\"" + ANALYTICS_MESSAGE_CLOSED + "\""));
        // Check that the url query param tags are sent
        assertTrue(eventString.contains("{\"name\":\"" + ANALYTICS_CAMPAIGN_STEP_ID_KEY + "\",\"value\":\"abcdefg\",\"type\":\"string\"}") && eventString.contains("{\"name\":\"" + ANALYTICS_SECONDS_DISPLAYED_KEY + "\",\"value\":\"5\",\"type\":\"float\"}"));
        // Check that a background event was sent
        assertTrue(eventString.contains("\"type\":\"SESSION\"") && eventString.contains("\"action\":\"" + TuneSessionEvent.BACKGROUNDED + "\""));
        // Check that a tracer event was sent
        assertTrue(eventString.contains("\"type\":\"TRACER\""));
    }

    public void testInAppMessageDismissedAutomaticallyDispatch() throws JSONException {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for foreground to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }

        // Build a dummy message with frequency limit
        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 0);
        frequencyJson.put(LIMIT_KEY, 0);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_INSTALL);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent("bd283b48a9290740ff92abb432571b80", frequencyJson);
        TestInAppMessage message = new TestInAppMessage("123", "abcdefg", triggerEvent);

        // Notify that a message (banner) was dismissed automatically after duration
        TuneEventBus.post(new TuneInAppMessageActionTaken(message, ANALYTICS_MESSAGE_DISMISSED_AUTOMATICALLY, 5));

        // Trigger an event dispatch
        TuneEventBus.post(new TuneAppBackgrounded());

        // Wait for first tracer to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 1) {
            sleep(WAIT_TIME);
        }

        JSONArray eventJson = mockApi.getPostedEvents().getJSONArray("events");
        String eventString = eventJson.toString();

        // Check that at least 3 events were sent - one message dismissed, background, tracer
        assertTrue("events length was " + eventJson.length(), eventJson.length() >= 3);
        // Check that a message shown event was sent
        assertTrue(eventString.contains("\"type\":\"IN_APP_MESSAGE\"") && eventString.contains("\"action\":\"" + ANALYTICS_MESSAGE_DISMISSED_AUTOMATICALLY + "\""));
        // Check that the url query param tags are sent
        assertTrue(eventString.contains("{\"name\":\"" + ANALYTICS_CAMPAIGN_STEP_ID_KEY + "\",\"value\":\"abcdefg\",\"type\":\"string\"}") && eventString.contains("{\"name\":\"" + ANALYTICS_SECONDS_DISPLAYED_KEY + "\",\"value\":\"5\",\"type\":\"float\"}"));
        // Check that a background event was sent
        assertTrue(eventString.contains("\"type\":\"SESSION\"") && eventString.contains("\"action\":\"" + TuneSessionEvent.BACKGROUNDED + "\""));
        // Check that a tracer event was sent
        assertTrue(eventString.contains("\"type\":\"TRACER\""));
    }

    public void testInAppMessageTuneActionDispatch() throws JSONException {
        TuneEventBus.post(new TuneAppForegrounded("foo", 1111L));

        // Wait for foreground to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 0) {
            sleep(WAIT_TIME);
        }

        // Build a dummy message with frequency limit
        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 0);
        frequencyJson.put(LIMIT_KEY, 0);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_INSTALL);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent("bd283b48a9290740ff92abb432571b80", frequencyJson);
        TestInAppMessage message = new TestInAppMessage("123", "abcdefg", triggerEvent);

        // Notify that a Tune Action click occurred
        TuneEventBus.post(new TuneInAppMessageActionTaken(message, "someTuneActionName", 5));

        // Let the action event write to disk in background
        sleep(WAIT_TIME);

        // Trigger an event dispatch
        TuneEventBus.post(new TuneAppBackgrounded());

        // Wait for first tracer to be dispatched
        while (mockApi.getAnalyticsPostCount() <= 1) {
            sleep(WAIT_TIME);
        }

        JSONArray eventJson = mockApi.getPostedEvents().getJSONArray("events");
        String eventString = eventJson.toString();

        // Check that at least 3 events were sent - one message dismissed, background, tracer
        assertTrue("events length was " + eventJson.length() + " with events " + eventString, eventJson.length() >= 3);
        // Check that a message shown event was sent
        assertTrue("events string did not contain Tune Action, was " + eventString, eventString.contains("\"type\":\"IN_APP_MESSAGE\"") && eventString.contains("\"action\":\"someTuneActionName\""));
        // Check that the url query param tags are sent
        assertTrue("events string did not contain campaign info, was " + eventString, eventString.contains("{\"name\":\"" + ANALYTICS_CAMPAIGN_STEP_ID_KEY + "\",\"value\":\"abcdefg\",\"type\":\"string\"}") && eventString.contains("{\"name\":\"" + ANALYTICS_SECONDS_DISPLAYED_KEY + "\",\"value\":\"5\",\"type\":\"float\"}"));
        // Check that a background event was sent
        assertTrue("events string did not contain session, was " + eventString, eventString.contains("\"type\":\"SESSION\"") && eventString.contains("\"action\":\"" + TuneSessionEvent.BACKGROUNDED + "\""));
        // Check that a tracer event was sent
        assertTrue("events string did not contain tracer, was " + eventString, eventString.contains("\"type\":\"TRACER\""));
    }
}
