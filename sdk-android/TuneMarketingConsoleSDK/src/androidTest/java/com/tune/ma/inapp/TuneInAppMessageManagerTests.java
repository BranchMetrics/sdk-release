package com.tune.ma.inapp;

import android.support.test.runner.AndroidJUnit4;

import com.tune.TuneEvent;
import com.tune.TuneTestConstants;
import com.tune.TuneUnitTest;
import com.tune.TuneUtils;
import com.tune.ma.TuneManager;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.TuneDeeplinkOpened;
import com.tune.ma.eventbus.event.TuneEventOccurred;
import com.tune.ma.eventbus.event.TunePlaylistManagerCurrentPlaylistChanged;
import com.tune.ma.eventbus.event.TunePlaylistManagerFirstPlaylistDownloaded;
import com.tune.ma.eventbus.event.push.TunePushEnabled;
import com.tune.ma.eventbus.event.push.TunePushOpened;
import com.tune.ma.inapp.model.TuneInAppMessage;
import com.tune.ma.inapp.model.TuneMessageDisplayCount;
import com.tune.ma.inapp.model.TuneTriggerEvent;
import com.tune.ma.playlist.model.TunePlaylist;
import com.tune.ma.push.model.TunePushMessage;
import com.tune.ma.utils.TuneFileUtils;

import org.json.JSONException;
import org.json.JSONObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static android.support.test.InstrumentationRegistry.getContext;
import static com.tune.ma.inapp.TuneInAppMessageConstants.LIFETIME_MAXIMUM_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.LIMIT_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_VALUE_EVENTS;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_VALUE_INSTALL;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

/**
 * Created by johng on 2/28/17.
 */
@RunWith(AndroidJUnit4.class)
public class TuneInAppMessageManagerTests extends TuneUnitTest {
    private static final int DISPLAY_WAIT = 5000;

    private TuneInAppMessageManager messageManager;

    @Before
    public void setUp() throws Exception {
        super.setUp();

        messageManager = TuneManager.getInstance().getInAppMessageManager();
    }

    @After
    public void tearDown() throws Exception {
        messageManager.clearCountMap();
        sleep(500);
        messageManager = null;

        super.tearDown();
    }

    @Test
    public void testSingleMessageIsLoadedFromPlaylistCorrectly() throws Exception {
        JSONObject playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_2.0_single_fullscreen_message.json");
        TunePlaylist playlist = new TunePlaylist(playlistJson);
        messageManager.onEvent(new TunePlaylistManagerCurrentPlaylistChanged(playlist));

        Map<String, TuneInAppMessage> messages = messageManager.getMessagesByIds();

        assertEquals(1, messages.size());

        // Get a specific message and verify its fields were parsed correctly
        TuneInAppMessage message = messages.get("57e3ff4200312d812800001f");
        assertEquals("57e3ff4200312d812800001f", message.getId());
    }

    @Test
    public void testMultipleMessagesAreLoadedFromPlaylistCorrectly() throws Exception {
        JSONObject playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_2.0_multiple_messages.json");
        TunePlaylist playlist = new TunePlaylist(playlistJson);
        messageManager.onEvent(new TunePlaylistManagerCurrentPlaylistChanged(playlist));

        Map<String, TuneInAppMessage> messages = messageManager.getMessagesByIds();

        assertEquals(2, messages.size());

        // Check a specific message and verify its fields were parsed correctly
        TuneInAppMessage message = messages.get("57e3ff4200312d812800001f");
        assertEquals("57e3ff4200312d812800001f", message.getId());

        // Check a second message and verify its fields as well
        TuneInAppMessage message2 = messages.get("57e3ff4200312d812800001a");
        assertEquals("57e3ff4200312d812800001a", message2.getId());
    }

    @Test
    public void testMessageGetsTriggeredByCustomEvent() throws InterruptedException {
        // Create a custom TuneInAppMessage with a custom event as trigger and set it for the message manager
        CountDownLatch displayLatch = new CountDownLatch(1);
        String customEventFiveline = "Custom|||goodbye|EVENT";
        String customEventMd5 = TuneUtils.md5(customEventFiveline);
        TestInAppMessage testMessage = new TestInAppMessage(customEventMd5, displayLatch);

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(customEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        // Send a custom event
        TuneEvent tuneEvent = new TuneEvent("goodbye");
        TuneEventBus.post(new TuneEventOccurred(tuneEvent));

        // Check that message is eventually triggered
        displayLatch.await();

        assertEquals(1, testMessage.getDisplayCount());
    }

    @Test
    public void testMessageGetsTriggeredByDeeplinkOpenedEvent() throws InterruptedException {
        // Create a custom TuneInAppMessage with a deeplink opened event as trigger and set it for the message manager
        CountDownLatch displayLatch = new CountDownLatch(1);
        String deeplinkEventFiveline = "myapp://test/path|||DeeplinkOpened|APP_OPENED_BY_URL";
        String deeplinkEventMd5 = TuneUtils.md5(deeplinkEventFiveline);
        TestInAppMessage testMessage = new TestInAppMessage(deeplinkEventMd5, displayLatch);

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(deeplinkEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        // Send a deeplink opened event
        TuneEventBus.post(new TuneDeeplinkOpened("myapp://test/path?query=value"));

        // Check that message is eventually triggered
        displayLatch.await();

        assertEquals(1, testMessage.getDisplayCount());
    }

    @Test
    public void testMessageGetsTriggeredByFirstPlaylistDownloadedEvent() throws InterruptedException {
        // Create a custom TuneInAppMessage with a first playlist download (Starts App) as trigger and set it for the message manager
        CountDownLatch displayLatch = new CountDownLatch(1);
        String firstPlaylistDownloadEventFiveline = "Application|||FirstPlaylistDownloaded|SESSION";
        String firstPlaylistDownloadEventMd5 = TuneUtils.md5(firstPlaylistDownloadEventFiveline);
        TestInAppMessage testMessage = new TestInAppMessage(firstPlaylistDownloadEventMd5, displayLatch);

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(firstPlaylistDownloadEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        // Send a first playlist download event
        TuneEventBus.post(new TunePlaylistManagerFirstPlaylistDownloaded());

        // Check that message is eventually triggered
        displayLatch.await();

        assertEquals(1, testMessage.getDisplayCount());
    }

    @Test
    public void testMessageGetsTriggeredByStartsAppEvent() throws InterruptedException {
        // Create a custom TuneInAppMessage with a first playlist download (Starts App) as trigger and set it for the message manager
        CountDownLatch displayLatch = new CountDownLatch(1);
        String firstPlaylistDownloadEventFiveline = "Application|||FirstPlaylistDownloaded|SESSION";
        String firstPlaylistDownloadEventMd5 = TuneUtils.md5(firstPlaylistDownloadEventFiveline);
        TestInAppMessage testMessage = new TestInAppMessage(firstPlaylistDownloadEventMd5, displayLatch);

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(firstPlaylistDownloadEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        // Send an app foreground event, this should trigger the FirstPlaylistDownloaded message
        TuneEventBus.post(new TuneAppForegrounded("123", System.currentTimeMillis()));

        // Check that message is eventually triggered
        displayLatch.await();

        assertEquals(1, testMessage.getDisplayCount());
    }

    @Test
    public void testMessageThatWasTriggeredByStartsAppEventDoesntShowAgainOnFirstPlaylistDownload() throws InterruptedException {
        // Create a custom TuneInAppMessage with a first playlist download (Starts App) as trigger and set it for the message manager
        CountDownLatch displayLatch = new CountDownLatch(1);
        String firstPlaylistDownloadEventFiveline = "Application|||FirstPlaylistDownloaded|SESSION";
        String firstPlaylistDownloadEventMd5 = TuneUtils.md5(firstPlaylistDownloadEventFiveline);
        TestInAppMessage testMessage = new TestInAppMessage(firstPlaylistDownloadEventMd5, displayLatch);

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(firstPlaylistDownloadEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        // Send an app foreground event, this should trigger the FirstPlaylistDownloaded message
        TuneEventBus.post(new TuneAppForegrounded("123", System.currentTimeMillis()));

        // Check that message is eventually triggered
        displayLatch.await();

        assertEquals(1, testMessage.getDisplayCount());

        // Send an app foreground event, this should not trigger the FirstPlaylistDownloaded message
        // since it was already shown this session
        TuneEventBus.post(new TunePlaylistManagerFirstPlaylistDownloaded());

        // Check that message is not triggered since it was already shown this session
        displayLatch.await(DISPLAY_WAIT, TimeUnit.MILLISECONDS);

        assertEquals(1, testMessage.getDisplayCount());
    }

    @Test
    public void testMessageGetsTriggeredByPushOpenedEvent() throws InterruptedException, JSONException {
        // Create a custom TuneInAppMessage with a push opened as trigger and set it for the message manager
        CountDownLatch displayLatch = new CountDownLatch(1);
        String pushOpenedEventFiveline = "5786809a00312de20f01a111|||NotificationOpened|PUSH_NOTIFICATION";
        String pushOpenedEventMd5 = TuneUtils.md5(pushOpenedEventFiveline);
        TestInAppMessage testMessage = new TestInAppMessage(pushOpenedEventMd5, displayLatch);

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(pushOpenedEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        // Send a push opened event
        JSONObject pushMessageJson = new JSONObject();
        pushMessageJson.put("appName", "message trigger test");
        pushMessageJson.put("app_id", "12345");
        pushMessageJson.put("alert", "Buy coins!");
        pushMessageJson.put("CAMPAIGN_ID", "123");
        pushMessageJson.put("ARTPID", "5786809a00312de20f01a111");
        pushMessageJson.put("LENGTH_TO_REPORT", 9000);
        pushMessageJson.put("local_message_id", "abcd");

        TunePushMessage pushMessage = new TunePushMessage(pushMessageJson.toString());
        TuneEventBus.post(new TunePushOpened(pushMessage));

        // Check that message is eventually triggered
        displayLatch.await();

        assertEquals(1, testMessage.getDisplayCount());
    }

    @Test
    public void testMessageGetsTriggeredByPushEnabledEvent() throws InterruptedException {
        // Create a custom TuneInAppMessage with a push enabled as trigger and set it for the message manager
        CountDownLatch displayLatch = new CountDownLatch(1);
        String pushEnabledEventFiveline = "Application|||Push Enabled|EVENT";
        String pushEnabledEventMd5 = TuneUtils.md5(pushEnabledEventFiveline);
        TestInAppMessage testMessage = new TestInAppMessage(pushEnabledEventMd5, displayLatch);

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(pushEnabledEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        TuneEventBus.post(new TunePushEnabled(true));

        // Check that message is eventually triggered
        displayLatch.await();

        assertEquals(1, testMessage.getDisplayCount());
    }

    @Test
    public void testMessageDoesntShowBeforeStartDate() throws InterruptedException {
        // Create a custom TuneInAppMessage with a trigger and set it for the message manager
        CountDownLatch displayLatch = new CountDownLatch(1);
        String pushEnabledEventFiveline = "Application|||Push Enabled|EVENT";
        String pushEnabledEventMd5 = TuneUtils.md5(pushEnabledEventFiveline);
        TestInAppMessage testMessage = new TestInAppMessage(pushEnabledEventMd5, displayLatch);

        // Set start date to tomorrow
        Calendar c = Calendar.getInstance();
        c.add(Calendar.DATE, 1);
        testMessage.setStartDate(c.getTime());

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(pushEnabledEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        TuneEventBus.post(new TunePushEnabled(true));

        // Check that message does not trigger before start date
        displayLatch.await(DISPLAY_WAIT, TimeUnit.MILLISECONDS);

        assertEquals(0, testMessage.getDisplayCount());
    }

    @Test
    public void testMessageShowsAfterStartDate() throws InterruptedException {
        // Create a custom TuneInAppMessage with a trigger and set it for the message manager
        CountDownLatch displayLatch = new CountDownLatch(1);
        String pushEnabledEventFiveline = "Application|||Push Enabled|EVENT";
        String pushEnabledEventMd5 = TuneUtils.md5(pushEnabledEventFiveline);
        TestInAppMessage testMessage = new TestInAppMessage(pushEnabledEventMd5, displayLatch);

        // Set start date to yesterday
        Calendar c = Calendar.getInstance();
        c.add(Calendar.DATE, -1);
        testMessage.setStartDate(c.getTime());

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(pushEnabledEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        TuneEventBus.post(new TunePushEnabled(true));

        // Check that message triggers after start date
        displayLatch.await();

        assertEquals(1, testMessage.getDisplayCount());
    }

    @Test
    public void testMessageDoesntShowAfterEndDate() throws InterruptedException {
        // Create a custom TuneInAppMessage with a trigger and set it for the message manager
        CountDownLatch displayLatch = new CountDownLatch(1);
        String pushEnabledEventFiveline = "Application|||Push Enabled|EVENT";
        String pushEnabledEventMd5 = TuneUtils.md5(pushEnabledEventFiveline);
        TestInAppMessage testMessage = new TestInAppMessage(pushEnabledEventMd5, displayLatch);

        // Set end date to yesterday
        Calendar c = Calendar.getInstance();
        c.add(Calendar.DATE, -1);
        testMessage.setEndDate(c.getTime());

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(pushEnabledEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        TuneEventBus.post(new TunePushEnabled(true));

        // Check that message does not trigger after end date
        displayLatch.await(DISPLAY_WAIT, TimeUnit.MILLISECONDS);

        assertEquals(0, testMessage.getDisplayCount());
    }

    @Test
    public void testMessageShowsBeforeEndDate() throws InterruptedException {
        // Create a custom TuneInAppMessage with a trigger and set it for the message manager
        CountDownLatch displayLatch = new CountDownLatch(1);
        String pushEnabledEventFiveline = "Application|||Push Enabled|EVENT";
        String pushEnabledEventMd5 = TuneUtils.md5(pushEnabledEventFiveline);
        TestInAppMessage testMessage = new TestInAppMessage(pushEnabledEventMd5, displayLatch);

        // Set end date to tomorrow
        Calendar c = Calendar.getInstance();
        c.add(Calendar.DATE, 1);
        testMessage.setEndDate(c.getTime());

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(pushEnabledEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        TuneEventBus.post(new TunePushEnabled(true));

        // Check that message triggers before end date
        displayLatch.await();

        assertEquals(1, testMessage.getDisplayCount());
    }

    @Test
    public void testMessageShowsBetweenStartAndEndDate() throws InterruptedException {
        // Create a custom TuneInAppMessage with a trigger and set it for the message manager
        CountDownLatch displayLatch = new CountDownLatch(1);
        String pushEnabledEventFiveline = "Application|||Push Enabled|EVENT";
        String pushEnabledEventMd5 = TuneUtils.md5(pushEnabledEventFiveline);
        TestInAppMessage testMessage = new TestInAppMessage(pushEnabledEventMd5, displayLatch);

        // Set start date to yesterday
        Calendar c = Calendar.getInstance();
        c.add(Calendar.DATE, -1);
        testMessage.setStartDate(c.getTime());

        // Set end date to tomorrow
        c = Calendar.getInstance();
        c.add(Calendar.DATE, 2);
        testMessage.setEndDate(c.getTime());

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(pushEnabledEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        TuneEventBus.post(new TunePushEnabled(true));

        // Check that message triggers when between start and end date
        displayLatch.await();

        assertEquals(1, testMessage.getDisplayCount());
    }

    @Test
    public void testMessageGetterByTriggerEvents() throws Exception {
        Map<String, List<TuneInAppMessage>> messages = messageManager.getMessagesByTriggerEvents();
        assertEquals(0, messages.size());

        JSONObject playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_2.0_multiple_messages.json");
        TunePlaylist playlist = new TunePlaylist(playlistJson);
        messageManager.onEvent(new TunePlaylistManagerCurrentPlaylistChanged(playlist));

        messages = messageManager.getMessagesByTriggerEvents();
        assertEquals(2, messages.size());

        assertTrue(messages.containsKey("bd283b48a9290740ff92abb432571b80"));
        assertTrue(messages.containsKey("ccec952ff93be984a7698a7a6ea0b88f"));
    }

    @Test
    public void testMessageGetterForCustomEvents() throws Exception {
        List<TuneInAppMessage> messages = messageManager.getMessagesForCustomEvent(null);
        assertEquals(0, messages.size());

        messages = messageManager.getMessagesForCustomEvent("");
        assertEquals(0, messages.size());

        messages = messageManager.getMessagesForCustomEvent("hello");
        assertEquals(0, messages.size());

        JSONObject playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_2.0_multiple_messages.json");
        TunePlaylist playlist = new TunePlaylist(playlistJson);
        messageManager.onEvent(new TunePlaylistManagerCurrentPlaylistChanged(playlist));

        messages = messageManager.getMessagesForCustomEvent("hello");
        assertEquals(1, messages.size());

        TuneInAppMessage message = messages.get(0);
        assertEquals("57e3ff4200312d812800001f", message.getId());

        messages = messageManager.getMessagesForCustomEvent("goodbye");

        assertEquals(1, messages.size());

        message = messages.get(0);
        assertEquals("57e3ff4200312d812800001a", message.getId());
    }

    @Test
    public void testMessageGetterForStartsApp() throws Exception {
        List<TuneInAppMessage> messages = messageManager.getMessagesForStartsApp();
        assertEquals(0, messages.size());

        JSONObject playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_2.0_single_banner_message_with_starts_app_trigger.json");
        TunePlaylist playlist = new TunePlaylist(playlistJson);
        messageManager.onEvent(new TunePlaylistManagerCurrentPlaylistChanged(playlist));

        messages = messageManager.getMessagesForStartsApp();
        assertEquals(1, messages.size());

        TuneInAppMessage message = messages.get(0);
        assertEquals("57e3ff4200312d812800001a", message.getId());
    }

    @Test
    public void testMessageGetterForPushOpened() throws Exception {
        List<TuneInAppMessage> messages = messageManager.getMessagesForPushOpened(null);
        assertEquals(0, messages.size());

        messages = messageManager.getMessagesForPushOpened("");
        assertEquals(0, messages.size());

        messages = messageManager.getMessagesForPushOpened("123");
        assertEquals(0, messages.size());

        JSONObject playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_2.0_single_banner_message_with_push_opened_trigger.json");
        TunePlaylist playlist = new TunePlaylist(playlistJson);
        messageManager.onEvent(new TunePlaylistManagerCurrentPlaylistChanged(playlist));

        messages = messageManager.getMessagesForPushOpened("123");
        assertEquals(1, messages.size());

        TuneInAppMessage message = messages.get(0);
        assertEquals("57e3ff4200312d812800001a", message.getId());

        messages = messageManager.getMessagesForPushOpened("456");

        assertEquals(0, messages.size());
    }

    @Test
    public void testMessageGetterForPushEnabled() throws Exception {
        List<TuneInAppMessage> messages = messageManager.getMessagesForPushEnabled(true);
        assertEquals(0, messages.size());

        JSONObject playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_2.0_single_banner_message_with_push_enabled_trigger.json");
        TunePlaylist playlist = new TunePlaylist(playlistJson);
        messageManager.onEvent(new TunePlaylistManagerCurrentPlaylistChanged(playlist));

        messages = messageManager.getMessagesForPushEnabled(true);
        assertEquals(1, messages.size());

        TuneInAppMessage message = messages.get(0);
        assertEquals("57e3ff4200312d812800001a", message.getId());

        messages = messageManager.getMessagesForPushEnabled(false);

        assertEquals(0, messages.size());
    }

    @Test
    public void testMessageGetterForViewedScreen() throws Exception {
        List<TuneInAppMessage> messages = messageManager.getMessagesForScreenViewed(null);
        assertEquals(0, messages.size());

        messages = messageManager.getMessagesForScreenViewed("");
        assertEquals(0, messages.size());

        messages = messageManager.getMessagesForScreenViewed("someScreen");
        assertEquals(0, messages.size());

        JSONObject playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_2.0_single_banner_message_with_viewed_screen_trigger.json");
        TunePlaylist playlist = new TunePlaylist(playlistJson);
        messageManager.onEvent(new TunePlaylistManagerCurrentPlaylistChanged(playlist));

        messages = messageManager.getMessagesForScreenViewed("someScreen");
        assertEquals(1, messages.size());

        TuneInAppMessage message = messages.get(0);
        assertEquals("57e3ff4200312d812800001a", message.getId());
    }

    // Test that message display counts map is updated correctly after message is shown
    @Test
    public void testMessageDisplayCountUpdatesWhenMessageIsShown() throws InterruptedException, JSONException {
        String triggerEventMd5 = "ccec952ff93be984a7698a7a6ea0b88f";
        String fakeCampaignId = "asdf";
        CountDownLatch displayLatch = new CountDownLatch(1);
        // Build a dummy message with the frequency limit we want to test
        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 0);
        frequencyJson.put(LIMIT_KEY, 0);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_INSTALL);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent(triggerEventMd5, frequencyJson);
        TestInAppMessage testMessage = new TestInAppMessage(triggerEvent, fakeCampaignId, displayLatch);

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(triggerEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        // Send a custom event
        TuneEvent tuneEvent = new TuneEvent("goodbye");
        TuneEventBus.post(new TuneEventOccurred(tuneEvent));

        // Check that message is eventually triggered
        displayLatch.await();

        sleep(TuneTestConstants.MESSAGETEST_SLEEP);

        // Dismiss the message so it can be shown again
        testMessage.dismiss();

        assertEquals(1, testMessage.getDisplayCount());

        // Check that message display count updated correctly
        TuneMessageDisplayCount messageCount = messageManager.getCountForMessage(testMessage, triggerEventMd5);

        assertEquals(0, messageCount.getEventsSeenSinceShown());
        assertEquals(1, messageCount.getLifetimeShownCount());
        assertEquals(1, messageCount.getNumberOfTimesShownThisSession());

        // Check that the message display counts in SharedPreferences also updated
        Map<String, TuneMessageDisplayCount> countsMap = messageManager.loadOrCreateMessageCountMap();
        TuneMessageDisplayCount messageCountFromSharedPrefs = countsMap.get(fakeCampaignId);
        assertEquals(0, messageCountFromSharedPrefs.getEventsSeenSinceShown());
        assertEquals(1, messageCountFromSharedPrefs.getLifetimeShownCount());
        assertEquals(1, messageCountFromSharedPrefs.getNumberOfTimesShownThisSession());

        // Send another custom event
        testMessage.setDisplayLatch(new CountDownLatch(1));

        TuneEventBus.post(new TuneEventOccurred(tuneEvent));

        // Check that message is eventually triggered
        displayLatch.await();

        sleep(TuneTestConstants.MESSAGETEST_SLEEP);

        assertEquals(2, testMessage.getDisplayCount());

        // Check that message display count updated again
        messageCount = messageManager.getCountForMessage(testMessage, triggerEventMd5);
        assertEquals(0, messageCount.getEventsSeenSinceShown());
        assertEquals(2, messageCount.getLifetimeShownCount());
        assertEquals(2, messageCount.getNumberOfTimesShownThisSession());

        // Check that the message display counts in SharedPreferences also updated
        countsMap = messageManager.loadOrCreateMessageCountMap();
        messageCountFromSharedPrefs = countsMap.get(fakeCampaignId);
        assertEquals(0, messageCountFromSharedPrefs.getEventsSeenSinceShown());
        assertEquals(2, messageCountFromSharedPrefs.getLifetimeShownCount());
        assertEquals(2, messageCountFromSharedPrefs.getNumberOfTimesShownThisSession());
    }

    // Test that message display counts map resets session counts on app foreground
    @Test
    public void testMessageDisplayCountSessionCountGetsClearedBetweenSessions() throws InterruptedException, JSONException {
        String triggerEventMd5 = "ccec952ff93be984a7698a7a6ea0b88f";
        CountDownLatch displayLatch = new CountDownLatch(1);
        // Build a dummy message with the frequency limit we want to test
        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 0);
        frequencyJson.put(LIMIT_KEY, 0);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_INSTALL);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent(triggerEventMd5, frequencyJson);
        TestInAppMessage testMessage = new TestInAppMessage(triggerEvent, displayLatch);

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(triggerEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        // Send a custom event
        TuneEvent tuneEvent = new TuneEvent("goodbye");
        TuneEventBus.post(new TuneEventOccurred(tuneEvent));

        // Check that message is eventually triggered
        displayLatch.await();

        assertEquals(1, testMessage.getDisplayCount());

        // Check that message display count updated correctly
        TuneMessageDisplayCount messageCount = messageManager.getCountForMessage(testMessage, triggerEventMd5);
        assertEquals(0, messageCount.getEventsSeenSinceShown());
        assertEquals(1, messageCount.getLifetimeShownCount());
        assertEquals(1, messageCount.getNumberOfTimesShownThisSession());

        // Check that the message display counts in SharedPreferences also updated
        Map<String, TuneMessageDisplayCount> countsMap = messageManager.loadOrCreateMessageCountMap();
        TuneMessageDisplayCount messageCountFromSharedPrefs = countsMap.get("123");
        assertEquals(0, messageCountFromSharedPrefs.getEventsSeenSinceShown());
        assertEquals(1, messageCountFromSharedPrefs.getLifetimeShownCount());
        assertEquals(1, messageCountFromSharedPrefs.getNumberOfTimesShownThisSession());

        // App foreground should reset number of times shown this session
        TuneEventBus.post(new TuneAppForegrounded(UUID.randomUUID().toString(), System.currentTimeMillis()));

        // Check that session counts get reset to 0
        messageCount = messageManager.getCountForMessage(testMessage, triggerEventMd5);
        assertEquals(0, messageCount.getEventsSeenSinceShown());
        assertEquals(1, messageCount.getLifetimeShownCount());
        assertEquals(0, messageCount.getNumberOfTimesShownThisSession());

        // Check that the message display counts in SharedPreferences also updated
        countsMap = messageManager.loadOrCreateMessageCountMap();
        messageCountFromSharedPrefs = countsMap.get("123");
        assertEquals(0, messageCountFromSharedPrefs.getEventsSeenSinceShown());
        assertEquals(1, messageCountFromSharedPrefs.getLifetimeShownCount());
        assertEquals(0, messageCountFromSharedPrefs.getNumberOfTimesShownThisSession());
    }

    // Test that message counts increment events seen if message is only supposed to display every X events
    @Test
    public void testMessageDisplayCountEventCountGetsIncrementedWhenNotDisplayed() throws InterruptedException, JSONException {
        String triggerEventMd5 = "ccec952ff93be984a7698a7a6ea0b88f";
        String fakeCampaignId = "abc";
        CountDownLatch displayLatch = new CountDownLatch(1);
        // Build a dummy message with the frequency limit we want to test - once every 2 events
        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 0);
        frequencyJson.put(LIMIT_KEY, 2);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_EVENTS);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent(triggerEventMd5, frequencyJson);
        TestInAppMessage testMessage = new TestInAppMessage(triggerEvent, fakeCampaignId, displayLatch);

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(triggerEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        // Send a trigger event
        TuneEvent tuneEvent = new TuneEvent("goodbye");
        TuneEventBus.post(new TuneEventOccurred(tuneEvent));

        // Let message processing finish, especially for SharedPreferences
        sleep(TuneTestConstants.MESSAGETEST_SLEEP);

        TuneMessageDisplayCount displayCountForMessage = messageManager.getCountForMessage(testMessage, triggerEventMd5);
        assertFalse("Test message displayed when it shouldn't", testMessage.shouldDisplay(displayCountForMessage));

        // Check that event counts get incremented since not enough events have been seen
        TuneMessageDisplayCount messageCount = messageManager.getCountForMessage(testMessage, triggerEventMd5);

        assertEquals(1, messageCount.getEventsSeenSinceShown());
        assertEquals(0, messageCount.getLifetimeShownCount());
        assertEquals(0, messageCount.getNumberOfTimesShownThisSession());

        // Check that the message display counts in SharedPreferences also updated
        Map<String, TuneMessageDisplayCount> countsMap = messageManager.loadOrCreateMessageCountMap();
        TuneMessageDisplayCount messageCountFromSharedPrefs = countsMap.get(fakeCampaignId);
        assertEquals(1, messageCountFromSharedPrefs.getEventsSeenSinceShown());
        assertEquals(0, messageCountFromSharedPrefs.getLifetimeShownCount());
        assertEquals(0, messageCountFromSharedPrefs.getNumberOfTimesShownThisSession());

        // Send a trigger event
        TuneEventBus.post(new TuneEventOccurred(tuneEvent));

        // Check that message is eventually triggered
        displayLatch.await();

        assertEquals(1, testMessage.getDisplayCount());

        // Check that message was displayed and events seen was reset
        messageCount = messageManager.getCountForMessage(testMessage, triggerEventMd5);
        assertEquals(0, messageCount.getEventsSeenSinceShown());
        assertEquals(1, messageCount.getLifetimeShownCount());
        assertEquals(1, messageCount.getNumberOfTimesShownThisSession());

        // Check that the message display counts in SharedPreferences also updated
        countsMap = messageManager.loadOrCreateMessageCountMap();
        messageCountFromSharedPrefs = countsMap.get(fakeCampaignId);
        assertEquals(0, messageCountFromSharedPrefs.getEventsSeenSinceShown());
        assertEquals(1, messageCountFromSharedPrefs.getLifetimeShownCount());
        assertEquals(1, messageCountFromSharedPrefs.getNumberOfTimesShownThisSession());
    }

    // Test that the message display count map only retains the counts of messages that were found in the playlist
    @Test
    public void testMessageDisplayCountMapGetsFilteredByCampaignIdsInPlaylist() throws JSONException {
        String triggerEventMd5 = "ccec952ff93be984a7698a7a6ea0b88f";
        String fakeCampaignId = "123";
        String realCampaignId = "57e3ff4200312d812800001c";

        // Create message count with nonexistant campaign id
        TuneMessageDisplayCount fakeCount = new TuneMessageDisplayCount(fakeCampaignId, triggerEventMd5);

        // Create message count with real campaign id from playlist
        TuneMessageDisplayCount realCount = new TuneMessageDisplayCount(realCampaignId, triggerEventMd5);

        // Set these as the message count map
        Map<String, TuneMessageDisplayCount> messageCounts = new HashMap<>();
        messageCounts.put(fakeCampaignId, fakeCount);
        messageCounts.put(realCampaignId, realCount);
        messageManager.setMessageCountsByCampaignIds(messageCounts);

        assertEquals(2, messageManager.getMessageCountsByCampaignIds().size());

        // Spoof a playlist download
        JSONObject playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_2.0_single_fullscreen_message.json");
        TunePlaylist playlist = new TunePlaylist(playlistJson);
        messageManager.onEvent(new TunePlaylistManagerCurrentPlaylistChanged(playlist));

        // Check that message count map is updated to only contain the playlist message campaign id
        assertEquals(1, messageManager.getMessageCountsByCampaignIds().size());

        TuneMessageDisplayCount remainingMessageDisplayCount = messageManager.getMessageCountsByCampaignIds().get("57e3ff4200312d812800001c");
        assertNotNull(remainingMessageDisplayCount);
        assertEquals("57e3ff4200312d812800001c", remainingMessageDisplayCount.getCampaignId());
    }

    @Test
    public void testFullscreensCanBeTriggeredForSameDeeplinkBetweenSessions() throws InterruptedException {
        // Create a custom TuneInAppMessage with a deeplink opened trigger and set it for the message manager
        CountDownLatch displayLatch = new CountDownLatch(1);
        String deeplinkOpenedEventFiveline = "test://deeplink|||DeeplinkOpened|APP_OPENED_BY_URL";
        String deeplinkOpenedEventMd5 = TuneUtils.md5(deeplinkOpenedEventFiveline);
        TestInAppMessage testMessage = new TestInAppMessage(deeplinkOpenedEventMd5, displayLatch);

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(deeplinkOpenedEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        // Mock a deeplink opened event to trigger the message
        TuneEventBus.post(new TuneDeeplinkOpened("test://deeplink"));

        // Check that message triggers the first time
        displayLatch.await();
        assertEquals(1, testMessage.getDisplayCount());

        // Mock an app background
        TuneEventBus.post(new TuneAppBackgrounded());

        // Dismiss the message
        testMessage.dismiss();

        // Mock an app foreground
        TuneEventBus.post(new TuneAppForegrounded(UUID.randomUUID().toString(), System.currentTimeMillis()));

        // Mock a deeplink opened, this should trigger the fullscreen message again since this is a new session
        displayLatch = new CountDownLatch(1);
        testMessage.setDisplayLatch(displayLatch);
        TuneEventBus.post(new TuneDeeplinkOpened("test://deeplink"));

        // Check that message triggers a second time
        displayLatch.await();
        assertEquals(2, testMessage.getDisplayCount());

        // Dismiss the message so it can be shown again
        testMessage.dismiss();
    }

    @Test
    public void testFullscreensCanBeTriggeredFromDifferentTriggerEvents() throws InterruptedException, JSONException {
        // Create a custom TuneInAppMessage with a deeplink opened trigger and a custom event trigger and set it for the message manager
        CountDownLatch displayLatch = new CountDownLatch(1);
        String deeplinkOpenedEventFiveline = "test://deeplink|||DeeplinkOpened|APP_OPENED_BY_URL";
        String deeplinkOpenedEventMd5 = TuneUtils.md5(deeplinkOpenedEventFiveline);

        String customEventFiveline = "Custom|||someEvent|EVENT";
        String customEventMd5 = TuneUtils.md5(customEventFiveline);

        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 0);
        frequencyJson.put(LIMIT_KEY, 0);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_INSTALL);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent(deeplinkOpenedEventMd5, frequencyJson);

        TuneTriggerEvent triggerEvent2 = new TuneTriggerEvent(customEventMd5, frequencyJson);

        List<TuneTriggerEvent> triggerEvents = new ArrayList<>();
        triggerEvents.add(triggerEvent);
        triggerEvents.add(triggerEvent2);

        TestInAppMessage testMessage = new TestInAppMessage(triggerEvents, displayLatch);

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList = new ArrayList<>();
        messageList.add(testMessage);
        messages.put(deeplinkOpenedEventMd5, messageList);
        messages.put(customEventMd5, messageList);
        messageManager.setMessagesByTriggerEvents(messages);

        // Mock a deeplink opened event to trigger the message
        TuneEventBus.post(new TuneDeeplinkOpened("test://deeplink"));

        // Check that message triggers the first time
        displayLatch.await();
        assertEquals(1, testMessage.getDisplayCount());

        // Dismiss the message so it can be shown again
        testMessage.dismiss();

        // Mock a custom event to trigger the message
        displayLatch = new CountDownLatch(1);
        testMessage.setDisplayLatch(displayLatch);
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("someEvent")));

        // Check that message triggers a second time
        displayLatch.await();
        assertEquals(2, testMessage.getDisplayCount());

        // Dismiss the message so it can be shown again
        testMessage.dismiss();

        // Mock a deeplink opened event to trigger the message again
        displayLatch = new CountDownLatch(1);
        testMessage.setDisplayLatch(displayLatch);
        TuneEventBus.post(new TuneDeeplinkOpened("test://deeplink"));

        // Check that message triggers a third time
        displayLatch.await();
        assertEquals(3, testMessage.getDisplayCount());

        // Dismiss the message so it can be shown again
        testMessage.dismiss();
    }

    @Test
    public void testFrequencyCountsAreClearedWhenMessageFrequencyChanges() throws Exception {
        String mockCampaignId = "57e3ff4200312d812800001c";
        String mockMessageId = "57e3ff4200312d812800001f";
        String mockTriggerEvent = "bd283b48a9290740ff92abb432571b80";

        // Populate message manager with mock message and a different frequency than in the json
        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 10);
        frequencyJson.put(LIMIT_KEY, 10);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_INSTALL);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent(mockTriggerEvent, frequencyJson);
        TestInAppMessage testMessage = new TestInAppMessage(mockCampaignId, "123", mockMessageId, triggerEvent);

        Map<String, TuneInAppMessage> messages = new HashMap<>();
        messages.put(mockMessageId, testMessage);
        messageManager.setMessagesByIds(messages);

        // Put an existing count in the display count map as if the message has been displayed before
        TuneMessageDisplayCount count = new TuneMessageDisplayCount(mockCampaignId, mockTriggerEvent);
        count.setLifetimeShownCount(5);
        count.setNumberOfTimesShownThisSession(10);
        count.setEventsSeenSinceShown(15);
        messageManager.updateCount(count);

        assertEquals(5, messageManager.getMessageCountsByCampaignIds().get(mockCampaignId).getLifetimeShownCount());
        assertEquals(10, messageManager.getMessageCountsByCampaignIds().get(mockCampaignId).getNumberOfTimesShownThisSession());
        assertEquals(15, messageManager.getMessageCountsByCampaignIds().get(mockCampaignId).getEventsSeenSinceShown());

        // Do a playlist download with the same message, but different frequency
        JSONObject playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_2.0_single_fullscreen_message.json");
        TunePlaylist playlist = new TunePlaylist(playlistJson);
        messageManager.onEvent(new TunePlaylistManagerCurrentPlaylistChanged(playlist));

        // Check that message count was reset
        TuneMessageDisplayCount updatedCount = messageManager.getMessageCountsByCampaignIds().get(mockCampaignId);
        assertNull(updatedCount);

        updatedCount = messageManager.getCountForMessage(testMessage, mockTriggerEvent);
        assertEquals(0, updatedCount.getLifetimeShownCount());
        assertEquals(0, updatedCount.getNumberOfTimesShownThisSession());
        assertEquals(0, updatedCount.getEventsSeenSinceShown());
    }

    @Test
    public void testFrequencyCountsAreClearedWhenMessageTriggerChanges() throws Exception {
        String mockCampaignId = "57e3ff4200312d812800001c";
        String mockMessageId = "57e3ff4200312d812800001f";
        String mockTriggerEvent = "asdfasdf";

        // Populate message manager with mock message and a different trigger than in the json
        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 0);
        frequencyJson.put(LIMIT_KEY, 0);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_INSTALL);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent(mockTriggerEvent, frequencyJson);
        TestInAppMessage testMessage = new TestInAppMessage(mockCampaignId, "123", mockMessageId, triggerEvent);

        Map<String, TuneInAppMessage> messages = new HashMap<>();
        messages.put(mockMessageId, testMessage);
        messageManager.setMessagesByIds(messages);

        // Put an existing count in the display count map as if the message has been displayed before
        TuneMessageDisplayCount count = new TuneMessageDisplayCount(mockCampaignId, mockTriggerEvent);
        count.setLifetimeShownCount(5);
        count.setNumberOfTimesShownThisSession(10);
        count.setEventsSeenSinceShown(15);
        messageManager.updateCount(count);

        assertEquals(5, messageManager.getMessageCountsByCampaignIds().get(mockCampaignId).getLifetimeShownCount());
        assertEquals(10, messageManager.getMessageCountsByCampaignIds().get(mockCampaignId).getNumberOfTimesShownThisSession());
        assertEquals(15, messageManager.getMessageCountsByCampaignIds().get(mockCampaignId).getEventsSeenSinceShown());

        // Do a playlist download with the same message, but different frequency
        JSONObject playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_2.0_single_fullscreen_message.json");
        TunePlaylist playlist = new TunePlaylist(playlistJson);
        messageManager.onEvent(new TunePlaylistManagerCurrentPlaylistChanged(playlist));

        // Check that message count was reset
        TuneMessageDisplayCount updatedCount = messageManager.getMessageCountsByCampaignIds().get(mockCampaignId);
        assertNull(updatedCount);

        updatedCount = messageManager.getCountForMessage(testMessage, mockTriggerEvent);
        assertEquals(0, updatedCount.getLifetimeShownCount());

        updatedCount = messageManager.getCountForMessage(testMessage, "bd283b48a9290740ff92abb432571b80");
        assertEquals(0, updatedCount.getLifetimeShownCount());
        assertEquals(0, updatedCount.getNumberOfTimesShownThisSession());
        assertEquals(0, updatedCount.getEventsSeenSinceShown());
    }

    @Test
    public void testFrequencyCountsAreNotClearedWhenMessageTriggerDoesntChange() throws Exception {
        String mockCampaignId = "57e3ff4200312d812800001c";
        String mockMessageId = "57e3ff4200312d812800001f";
        String mockTriggerEvent = "bd283b48a9290740ff92abb432571b80";

        // Populate message manager with mock message and a different trigger than in the json
        JSONObject frequencyJson = new JSONObject();
        frequencyJson.put(LIFETIME_MAXIMUM_KEY, 0);
        frequencyJson.put(LIMIT_KEY, 0);
        frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_INSTALL);
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent(mockTriggerEvent, frequencyJson);
        TestInAppMessage testMessage = new TestInAppMessage(mockCampaignId, "123", mockMessageId, triggerEvent);

        Map<String, TuneInAppMessage> messages = new HashMap<>();
        messages.put(mockMessageId, testMessage);
        messageManager.setMessagesByIds(messages);

        // Put an existing count in the display count map as if the message has been displayed before
        TuneMessageDisplayCount count = new TuneMessageDisplayCount(mockCampaignId, mockTriggerEvent);
        count.setLifetimeShownCount(5);
        count.setNumberOfTimesShownThisSession(10);
        count.setEventsSeenSinceShown(15);
        messageManager.updateCount(count);

        assertEquals(5, messageManager.getMessageCountsByCampaignIds().get(mockCampaignId).getLifetimeShownCount());
        assertEquals(10, messageManager.getMessageCountsByCampaignIds().get(mockCampaignId).getNumberOfTimesShownThisSession());
        assertEquals(15, messageManager.getMessageCountsByCampaignIds().get(mockCampaignId).getEventsSeenSinceShown());

        // Do a playlist download with the same message, but different frequency
        JSONObject playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_2.0_single_fullscreen_message.json");
        TunePlaylist playlist = new TunePlaylist(playlistJson);
        messageManager.onEvent(new TunePlaylistManagerCurrentPlaylistChanged(playlist));

        // Check that message count was not
        TuneMessageDisplayCount updatedCount = messageManager.getMessageCountsByCampaignIds().get(mockCampaignId);
        assertNotNull(updatedCount);

        updatedCount = messageManager.getCountForMessage(testMessage, mockTriggerEvent);
        assertEquals(5, updatedCount.getLifetimeShownCount());
        assertEquals(10, updatedCount.getNumberOfTimesShownThisSession());
        assertEquals(15, updatedCount.getEventsSeenSinceShown());
    }

    @Test
    public void testOldMessageIsNotDismissedWhenNewMessageShouldBeShown() throws InterruptedException {
        String triggerEvent1 = "ccec952ff93be984a7698a7a6ea0b88f";
        String triggerEvent2 = "bd283b48a9290740ff92abb432571b80";

        // Create a custom TuneInAppMessage with a trigger and add it to the message manager
        CountDownLatch displayLatch1 = new CountDownLatch(1);
        TestInAppMessage testMessage1 = new TestInAppMessage(triggerEvent1, "campaign123", displayLatch1);

        // Create another custom TuneInAppMessage with a trigger and add it to the message manager
        CountDownLatch displayLatch2 = new CountDownLatch(1);
        TestInAppMessage testMessage2 = new TestInAppMessage(triggerEvent2, "campaign456", displayLatch2);

        Map<String, List<TuneInAppMessage>> messages = new HashMap<>();
        List<TuneInAppMessage> messageList1 = new ArrayList<>();
        messageList1.add(testMessage1);
        messages.put(triggerEvent1, messageList1);

        List<TuneInAppMessage> messageList2 = new ArrayList<>();
        messageList2.add(testMessage2);
        messages.put(triggerEvent2, messageList2);

        messageManager.setMessagesByTriggerEvents(messages);

        // Send a trigger event to trigger message1
        TuneEvent tuneEvent = new TuneEvent("goodbye");
        TuneEventBus.post(new TuneEventOccurred(tuneEvent));

        // Check that message1 triggers
        displayLatch1.await();
        sleep(TuneTestConstants.MESSAGETEST_SLEEP);

        assertEquals(1, testMessage1.getDisplayCount());
        assertTrue(testMessage1.isVisible());
        assertFalse(testMessage2.isVisible());

        // Send a trigger event to trigger message2
        tuneEvent = new TuneEvent("hello");
        TuneEventBus.post(new TuneEventOccurred(tuneEvent));

        // Check that message2 does not trigger
        displayLatch2.await(DISPLAY_WAIT, TimeUnit.MILLISECONDS);
        sleep(TuneTestConstants.MESSAGETEST_SLEEP);

        assertEquals(0, testMessage2.getDisplayCount());
        assertTrue(testMessage1.isVisible());
        assertFalse(testMessage2.isVisible());
    }
}
