package com.tune.ma.inapp.model;

import android.app.Activity;

import com.tune.TuneUnitTest;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.inapp.TuneInAppMessageActionTaken;
import com.tune.ma.eventbus.event.inapp.TuneInAppMessageUnspecifiedActionTaken;
import com.tune.ma.inapp.TestInAppMessage;
import com.tune.ma.inapp.model.action.TuneInAppAction;
import com.tune.ma.playlist.model.TunePlaylist;
import com.tune.ma.utils.TuneFileUtils;
import com.tune.ma.utils.TuneJsonUtils;

import org.greenrobot.eventbus.Subscribe;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import static com.tune.ma.inapp.TuneInAppMessageConstants.LIFETIME_MAXIMUM_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.LIMIT_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_VALUE_DAYS;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_VALUE_EVENTS;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_VALUE_INSTALL;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_VALUE_SESSION;

/**
 * Created by johng on 2/28/17.
 */

public class TuneInAppMessageTests extends TuneUnitTest {
    private TunePlaylist playlist;
    private TuneInAppMessage message;

    public void setUp() throws Exception {
        super.setUp();
        JSONObject playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_2.0_single_fullscreen_message.json");
        playlist = new TunePlaylist(playlistJson);
    }

    public void testConstructor() {
        JSONObject inAppMessagesJson = playlist.getInAppMessages();

        // Iterate through in-app messages and create map of messages
        Iterator<String> inAppMessagesIter = inAppMessagesJson.keys();
        String triggerRuleId;
        while (inAppMessagesIter.hasNext()) {
            triggerRuleId = inAppMessagesIter.next();

            JSONObject inAppMessage = TuneJsonUtils.getJSONObject(inAppMessagesJson, triggerRuleId);

            message = new TuneInAppMessage(inAppMessage) {
                @Override
                public void display() {
                    return;
                }

                @Override
                public void dismiss() {
                    return;
                }

                @Override
                public void load(Activity activity) {
                    return;
                }
            };
        }

        assertEquals("57e3ff4200312d812800001f", message.getId());
        assertEquals("<html>\n" +
                "<body>\n" +
                "<a href=\"tune-action://onRedButton\">\n" +
                "<img style=\"width: 100%; height: 100%; max-width: 100%; max-height: 100%\" src=\"http://docs.appsfire.com/sdk/ios/integration-reference/img/doc/monetization-sushi-example.jpg\"/>\n" +
                "</a>\n" +
                "</body>\n" +
                "</html>", message.getHtml());
        assertEquals("57e3ff4200312d812800001c", message.getCampaign().getCampaignId());
        assertEquals("57e3ff4200312d812800001f", message.getCampaign().getVariationId());
        assertTrue(604800 == message.getCampaign().getNumberOfSecondsToReportAnalytics());

        ArrayList<TuneTriggerEvent> expectedTriggers = new ArrayList<TuneTriggerEvent>();
        JSONObject frequencyJson = new JSONObject();
        try {
            frequencyJson.put(LIFETIME_MAXIMUM_KEY, 0);
            frequencyJson.put(LIMIT_KEY, 0);
            frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_INSTALL);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        expectedTriggers.add(new TuneTriggerEvent("bd283b48a9290740ff92abb432571b80", frequencyJson));
        assertEquals(expectedTriggers.toString(), message.getTriggerEvents().toString());

        assertEquals(TuneInAppMessage.Transition.FADE_IN, message.getTransition());

        Map<String, TuneInAppAction> expectedActions = new HashMap<String, TuneInAppAction>();

        try {
            JSONObject deeplinkActionJson = new JSONObject("{\"type\":\"deeplink\",\"link\":\"inappdemo://activity2\"}");
            TuneInAppAction deeplinkAction = new TuneInAppAction("onBlueButton", deeplinkActionJson);
            expectedActions.put("onBlueButton", deeplinkAction);

            JSONObject deepActionActionJson = new JSONObject("{\"type\":\"deepAction\",\"id\":\"applyCoupon\",\"data\":{\"discount\":\"30\",\"code\":\"U4FXZ\"}}");
            TuneInAppAction deepActionAction = new TuneInAppAction("onRedButton", deepActionActionJson);
            expectedActions.put("onRedButton", deepActionAction);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        assertEquals(expectedActions.get("onBlueButton"), message.getActions().get("onBlueButton"));
        assertEquals(expectedActions.get("onRedButton"), message.getActions().get("onRedButton"));
    }

    /* Tests for shouldDisplay */

    // Test default frequency case (no limits)
    public void testShouldDisplayDefaultFrequency() throws JSONException {
        // Build a dummy message with the frequency limit we want to test
        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 0);
        frequencyJson.put(LIMIT_KEY, 0);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_INSTALL);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent("bd283b48a9290740ff92abb432571b80", frequencyJson);

        List<TuneTriggerEvent> triggerEvents = new ArrayList<TuneTriggerEvent>();
        triggerEvents.add(triggerEvent);
        message = new TestInAppMessage(triggerEvents);

        TuneMessageDisplayCount displayCount = new TuneMessageDisplayCount(message.getCampaign().getCampaignId(), message.getTriggerEvents().get(0).getEventMd5());

        assertTrue(message.shouldDisplay(displayCount));
    }

    // For limit "Only Once", test being under and over the limit
    public void testShouldDisplayWithOnlyOnceLimit() throws JSONException {
        // Build a dummy message with the frequency limit we want to test
        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 1);
        frequencyJson.put(LIMIT_KEY, 1);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_INSTALL);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent("bd283b48a9290740ff92abb432571b80", frequencyJson);

        List<TuneTriggerEvent> triggerEvents = new ArrayList<TuneTriggerEvent>();
        triggerEvents.add(triggerEvent);
        message = new TestInAppMessage(triggerEvents);

        TuneMessageDisplayCount displayCount = new TuneMessageDisplayCount(message.getCampaign().getCampaignId(), message.getTriggerEvents().get(0).getEventMd5());

        assertTrue(message.shouldDisplay(displayCount));

        displayCount.setLifetimeShownCount(1);

        assertFalse(message.shouldDisplay(displayCount));
    }

    // For limit "X per Session", test being under and over the limit
    public void testShouldDisplayWithPerSessionLimit() throws JSONException {
        // Build a dummy message with the frequency limit we want to test
        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 0);
        frequencyJson.put(LIMIT_KEY, 5);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_SESSION);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent("bd283b48a9290740ff92abb432571b80", frequencyJson);

        List<TuneTriggerEvent> triggerEvents = new ArrayList<TuneTriggerEvent>();
        triggerEvents.add(triggerEvent);
        message = new TestInAppMessage(triggerEvents);

        TuneMessageDisplayCount displayCount = new TuneMessageDisplayCount(message.getCampaign().getCampaignId(), message.getTriggerEvents().get(0).getEventMd5());
        displayCount.setNumberOfTimesShownThisSession(4);

        assertTrue(message.shouldDisplay(displayCount));

        displayCount.setNumberOfTimesShownThisSession(5);

        assertFalse(message.shouldDisplay(displayCount));
    }

    // For limit "once every X days", test being under and over the limit
    public void testShouldDisplayWithOncePerXDaysLimit() throws JSONException {
        // Build a dummy message with the frequency limit we want to test
        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 0);
        frequencyJson.put(LIMIT_KEY, 2);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_DAYS);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent("bd283b48a9290740ff92abb432571b80", frequencyJson);

        List<TuneTriggerEvent> triggerEvents = new ArrayList<TuneTriggerEvent>();
        triggerEvents.add(triggerEvent);
        message = new TestInAppMessage(triggerEvents);

        TuneMessageDisplayCount displayCount = new TuneMessageDisplayCount(message.getCampaign().getCampaignId(), message.getTriggerEvents().get(0).getEventMd5());
        displayCount.setLastShownDate(new Date());

        assertFalse(message.shouldDisplay(displayCount));

        // Create Date 2 days ago
        Calendar cdate = Calendar.getInstance();
        cdate.add(Calendar.DATE, -2);
        Date twoDaysAgo = cdate.getTime();
        // Set last shown date to 2 days ago
        displayCount.setLastShownDate(twoDaysAgo);

        assertTrue(message.shouldDisplay(displayCount));
    }

    // For limit "every X times an event occurs", test being under and over the limit
    public void testShouldDisplayWithPerXEventsLimit() throws JSONException {
        // Build a dummy message with the frequency limit we want to test
        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 0);
        frequencyJson.put(LIMIT_KEY, 10);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_EVENTS);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent("bd283b48a9290740ff92abb432571b80", frequencyJson);

        List<TuneTriggerEvent> triggerEvents = new ArrayList<TuneTriggerEvent>();
        triggerEvents.add(triggerEvent);
        message = new TestInAppMessage(triggerEvents);

        TuneMessageDisplayCount displayCount = new TuneMessageDisplayCount(message.getCampaign().getCampaignId(), message.getTriggerEvents().get(0).getEventMd5());
        displayCount.setEventsSeenSinceShown(9);

        assertFalse(message.shouldDisplay(displayCount));

        displayCount.setEventsSeenSinceShown(10);

        assertTrue(message.shouldDisplay(displayCount));
    }

    // Test that when there are multiple frequencies, they get OR'd so message displays if at least one passes
    public void testShouldDisplayIfOneFrequencyPasses() throws JSONException {
        // Build a dummy message with the frequency limits we want to test
        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 1);
        frequencyJson.put(LIMIT_KEY, 1);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_INSTALL);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent("bd283b48a9290740ff92abb432571b80", frequencyJson);

        JSONObject frequencyJson2 = new JSONObject();
        frequencyJson2.put(LIFETIME_MAXIMUM_KEY, 0);
        frequencyJson2.put(LIMIT_KEY, 0);
        frequencyJson2.put(SCOPE_KEY, SCOPE_VALUE_INSTALL);
        TuneTriggerEvent triggerEvent2 = new TuneTriggerEvent("bd283b48a9290740ff92abb432571b80", frequencyJson2);

        List<TuneTriggerEvent> triggerEvents = new ArrayList<TuneTriggerEvent>();
        triggerEvents.add(triggerEvent);
        triggerEvents.add(triggerEvent2);
        message = new TestInAppMessage(triggerEvents);

        TuneMessageDisplayCount displayCount = new TuneMessageDisplayCount(message.getCampaign().getCampaignId(), message.getTriggerEvents().get(0).getEventMd5());
        displayCount.setLifetimeShownCount(5);

        assertTrue(message.shouldDisplay(displayCount));
    }

    // Test that we process actions that are just urls as unspecified actions
    public void testUnspecifiedActionWithUrlGetsSent() throws JSONException {
        TuneEventBusListener eventBusListener = new TuneEventBusListener();
        TuneEventBus.register(eventBusListener);

        JSONObject inAppMessagesJson = playlist.getInAppMessages();

        // Iterate through in-app messages and create map of messages
        Iterator<String> inAppMessagesIter = inAppMessagesJson.keys();
        String triggerRuleId;
        while (inAppMessagesIter.hasNext()) {
            triggerRuleId = inAppMessagesIter.next();

            JSONObject inAppMessage = TuneJsonUtils.getJSONObject(inAppMessagesJson, triggerRuleId);

            message = new TuneInAppMessage(inAppMessage) {
                @Override
                public void display() {
                    return;
                }

                @Override
                public void dismiss() {
                    return;
                }

                @Override
                public void load(Activity activity) {
                    return;
                }
            };
        }

        String ACTION_URL = "https://www.tune.com";

        message.processAction(ACTION_URL);

        assertEquals(1, eventBusListener.unspecifiedActionCount);
        assertEquals(ACTION_URL, eventBusListener.unspecifiedActionName);
        assertEquals(0, eventBusListener.actionCount);
    }

    // Test that we process action names that aren't in the actions map as unspecified actions
    public void testUnspecifiedActionWithNameGetsSent() throws JSONException {
        TuneEventBusListener eventBusListener = new TuneEventBusListener();
        TuneEventBus.register(eventBusListener);

        JSONObject inAppMessagesJson = playlist.getInAppMessages();

        // Iterate through in-app messages and create map of messages
        Iterator<String> inAppMessagesIter = inAppMessagesJson.keys();
        String triggerRuleId;
        while (inAppMessagesIter.hasNext()) {
            triggerRuleId = inAppMessagesIter.next();

            JSONObject inAppMessage = TuneJsonUtils.getJSONObject(inAppMessagesJson, triggerRuleId);

            message = new TuneInAppMessage(inAppMessage) {
                @Override
                public void display() {
                    return;
                }

                @Override
                public void dismiss() {
                    return;
                }

                @Override
                public void load(Activity activity) {
                    return;
                }
            };
        }

        String ACTION_NAME = "tune-action://thisNameDoesntExist";
        String EXPECTED_ACTION_NAME = "thisNameDoesntExist";

        message.processAction(ACTION_NAME);

        assertEquals(1, eventBusListener.unspecifiedActionCount);
        assertEquals(EXPECTED_ACTION_NAME, eventBusListener.unspecifiedActionName);
        assertEquals(0, eventBusListener.actionCount);
    }

    // Test that we process action names that are in the actions map as Tune actions
    public void testTuneActionWithNameGetsSent() throws JSONException {
        TuneEventBusListener eventBusListener = new TuneEventBusListener();
        TuneEventBus.register(eventBusListener);

        JSONObject inAppMessagesJson = playlist.getInAppMessages();

        // Iterate through in-app messages and create map of messages
        Iterator<String> inAppMessagesIter = inAppMessagesJson.keys();
        String triggerRuleId;
        while (inAppMessagesIter.hasNext()) {
            triggerRuleId = inAppMessagesIter.next();

            JSONObject inAppMessage = TuneJsonUtils.getJSONObject(inAppMessagesJson, triggerRuleId);

            message = new TuneInAppMessage(inAppMessage) {
                @Override
                public void display() {
                    return;
                }

                @Override
                public void dismiss() {
                    return;
                }

                @Override
                public void load(Activity activity) {
                    return;
                }
            };
        }

        String ACTION_NAME = "tune-action://onBlueButton";
        String EXPECTED_ACTION_NAME = "onBlueButton";

        message.processAction(ACTION_NAME);

        assertEquals(0, eventBusListener.unspecifiedActionCount);
        assertEquals(EXPECTED_ACTION_NAME, eventBusListener.actionName);
        assertEquals(1, eventBusListener.actionCount);
    }

    public class TuneEventBusListener {
        public int actionCount = 0;
        public String actionName;
        public int unspecifiedActionCount = 0;
        public String unspecifiedActionName;

        @Subscribe
        public void onEvent(TuneInAppMessageActionTaken event) {
            actionCount++;
            actionName = event.getAction();
        }

        @Subscribe
        public void onEvent(TuneInAppMessageUnspecifiedActionTaken event) {
            unspecifiedActionCount++;
            unspecifiedActionName = event.getUnspecifiedActionName();
        }
    }
}
