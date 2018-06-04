package com.tune.ma.session;

import android.content.Context;
import android.support.test.runner.AndroidJUnit4;

import com.tune.TuneUnitTest;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.TuneAnalyticsListener;
import com.tune.ma.application.TuneActivity;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneActivityConnected;
import com.tune.ma.eventbus.event.TuneActivityDisconnected;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.profile.TuneUserProfile;

import org.greenrobot.eventbus.Subscribe;
import org.json.JSONArray;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;

import java.util.concurrent.CountDownLatch;

import static android.support.test.InstrumentationRegistry.getContext;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

/**
 * Created by kristine on 1/13/16.
 */
@RunWith(AndroidJUnit4.class)
public class TuneSessionTests extends TuneUnitTest {

    @Mock
    TuneActivity activity;

    private int foregroundedCount;
    private int backgroundedCount;
    private int dispatchCount;

    private int activityConnectedCount;
    private Context context;
    private TuneSessionManager sessionManager;
    private TuneUserProfile userProfile;

    private CountDownLatch backgroundLock;

    @Before
    public void setUp() throws Exception {
        super.setUp();
        context = getContext();

        sessionManager = TuneManager.getInstance().getSessionManager();
        assertNotNull(sessionManager);
        userProfile = TuneManager.getInstance().getProfileManager();
        assertNotNull(userProfile);

        TuneSessionManager.clearTimer();
        TuneSessionManager.clearActivities();
        
        foregroundedCount = 0;
        backgroundedCount = 0;
        dispatchCount = 0;
        activityConnectedCount = 0;
    }

    @After
    public void tearDown() throws Exception {
        TuneEventBus.post(new TuneAppBackgrounded());
        sleep(TuneSessionManager.SESSION_TIMEOUT + 500);
        TuneSessionManager.clearInstance();

        super.tearDown();
    }

//    public void freshSessionProfile() {
//        TuneManager.destroy();
//        TuneManager.init(context, null);
//
//        sessionManager = TuneManager.getInstance().getSessionManager();
//        userProfile = TuneManager.getInstance().getProfileManager();
//    }
//
//    public void checkProfileMemAndPrefsDoesntExist(String key) {
//        assertNull(userProfile.getProfileVariable(key));
//        assertNull(userProfile.getProfileVariableFromPrefs(key));
//    }
//
//    public void checkProfileMemAndPrefsValueNull(String key) {
//        assertNotNull("Profile variable for " + key + " was null", userProfile.getProfileVariable(key));
//        assertNull(userProfile.getProfileVariable(key).getValue());
//        assertNull(userProfile.getProfileVariableFromPrefs(key).getValue());
//    }
//
//    public void checkProfileMemAndPrefs(String key, String against) {
//        assertTrue(userProfile.getProfileVariable(key).getValue() + " does not equal expected " + against, against.equalsIgnoreCase(userProfile.getProfileVariable(key).getValue()));
//        assertTrue(userProfile.getProfileVariableFromPrefs(key).getValue() + " from prefs does not equal expected " + against, against.equalsIgnoreCase(userProfile.getProfileVariableFromPrefs(key).getValue()));
//    }

    @Test
    public void testSessionStart() {
        assertNull(sessionManager.getSession());
        assertEquals(0, sessionManager.getConnectedActivities().size());

        TuneEventBus.post(new TuneActivityConnected(activity));
        sleep(500);

        assertNotNull(sessionManager.getSession());
        assertEquals(1, sessionManager.getConnectedActivities().size());
        assertNotNull(sessionManager.getSession());
        assertEquals(0, sessionManager.getSession().getSessionLength());
    }

    @Test
    public void testSessionEnd() throws InterruptedException {
        TuneEventBus.register(this);

        assertNull(sessionManager.getSession());
        assertEquals(0, sessionManager.getConnectedActivities().size());

        TuneEventBus.post(new TuneActivityConnected(activity));

        assertEquals(1, sessionManager.getConnectedActivities().size());
        assertNotNull(sessionManager.getSession());

        // Wait a little so session length doesn't possibly get set to zero and fail our test
        sleep(500);

        TuneEventBus.post(new TuneActivityDisconnected(activity));

        // Wait for background event to post
        backgroundLock = new CountDownLatch(1);
        backgroundLock.await();

        assertEquals(0, sessionManager.getConnectedActivities().size());
        assertNotNull(sessionManager.getSession());
        assertTrue("session length was zero", sessionManager.getSession().getSessionLength() > 0);

        TuneEventBus.unregister(this);
    }

//    public void testFirstSession() {
//        checkProfileMemAndPrefsDoesntExist(TuneProfileKeys.IS_FIRST_SESSION);
//
//        // First Session
//        TuneEventBus.post(new TuneActivityConnected(activity));
//        checkProfileMemAndPrefs(TuneProfileKeys.IS_FIRST_SESSION, "1");
//        TuneEventBus.post(new TuneActivityDisconnected(activity));
//        checkProfileMemAndPrefs(TuneProfileKeys.IS_FIRST_SESSION, "1");
//
//        sleep(1250);
//
//        // Second Session
//        TuneEventBus.post(new TuneActivityConnected(activity));
//        checkProfileMemAndPrefs(TuneProfileKeys.IS_FIRST_SESSION, "0");
//        TuneEventBus.post(new TuneActivityDisconnected(activity));
//        checkProfileMemAndPrefs(TuneProfileKeys.IS_FIRST_SESSION, "0");
//
//        sleep(1250);
//
//        // Third Session
//        TuneEventBus.post(new TuneActivityConnected(activity));
//        checkProfileMemAndPrefs(TuneProfileKeys.IS_FIRST_SESSION, "0");
//        TuneEventBus.post(new TuneActivityDisconnected(activity));
//        checkProfileMemAndPrefs(TuneProfileKeys.IS_FIRST_SESSION, "0");
//
//        sleep(1250);
//
//        // Fourth Session w/ new SessionManager + UserProfile
//        freshSessionProfile();
//        TuneEventBus.post(new TuneActivityConnected(activity));
//        checkProfileMemAndPrefs(TuneProfileKeys.IS_FIRST_SESSION, "0");
//        TuneEventBus.post(new TuneActivityDisconnected(activity));
//        checkProfileMemAndPrefs(TuneProfileKeys.IS_FIRST_SESSION, "0");
//    }

// TODO: REVISIT.  Timing on this is too weird to fix.
//    public void testSessionCount() throws InterruptedException {
//        TuneEventBus.register(this);
//
//        checkProfileMemAndPrefsDoesntExist(TuneProfileKeys.SESSION_COUNT);
//
//        // First Session
//        TuneEventBus.post(new TuneActivityConnected(activity));
//        // Short sleep to let profile write to SharedPreferences
//        sleep(500);
//
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_COUNT, "1");
//        TuneEventBus.post(new TuneActivityDisconnected(activity));
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_COUNT, "1");
//
//        // Wait for background event to post
//        backgroundLock = new CountDownLatch(1);
//        backgroundLock.await();
//
//        // Second Session
//        TuneEventBus.post(new TuneActivityConnected(activity));
//        sleep(500);
//
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_COUNT, "2");
//        TuneEventBus.post(new TuneActivityDisconnected(activity));
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_COUNT, "2");
//
//        // Wait for background event to post
//        backgroundLock = new CountDownLatch(1);
//        backgroundLock.await();
//
//        // Third Session
//        TuneEventBus.post(new TuneActivityConnected(activity));
//        sleep(500);
//
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_COUNT, "3");
//        TuneEventBus.post(new TuneActivityDisconnected(activity));
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_COUNT, "3");
//
//        // Wait for background event to post
//        backgroundLock = new CountDownLatch(1);
//        backgroundLock.await();
//
//        // Fourth Session w/ new SessionManager + UserProfile
//        freshSessionProfile();
//        TuneEventBus.post(new TuneActivityConnected(activity));
//        sleep(500);
//
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_COUNT, "4");
//        TuneEventBus.post(new TuneActivityDisconnected(activity));
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_COUNT, "4");
//
//        TuneEventBus.unregister(this);
//    }

// TODO: REVISIT.  Timing on this is too weird to fix.
//    public void testLastCurrentSessionDate() throws InterruptedException {
//        TuneEventBus.register(this);
//
//        checkProfileMemAndPrefsDoesntExist(TuneProfileKeys.SESSION_LAST_DATE);
//        checkProfileMemAndPrefsDoesntExist(TuneProfileKeys.SESSION_CURRENT_DATE);
//
//        // First Session
//        TuneEventBus.post(new TuneActivityConnected(activity));
//        // Short sleep to let profile write to SharedPreferences
//        sleep(500);
//
//        assertEquals(1, activityConnectedCount);
//        assertEquals(1, foregroundedCount);
//        assertNotNull("Session is null", sessionManager.getSession());
//        String firstSessionStart = TuneAnalyticsVariable.dateToString(new Date(sessionManager.getSession().getCreatedDate()));
//        checkProfileMemAndPrefsValueNull(TuneProfileKeys.SESSION_LAST_DATE);
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_CURRENT_DATE, firstSessionStart);
//
//        TuneEventBus.post(new TuneActivityDisconnected(activity));
//        assertEquals(0, activityConnectedCount);
//        checkProfileMemAndPrefsValueNull(TuneProfileKeys.SESSION_LAST_DATE);
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_CURRENT_DATE, firstSessionStart);
//
//        // Wait for background event to post
//        backgroundLock = new CountDownLatch(1);
//        backgroundLock.await();
//        // We only track session starts to seconds, so we need to wait long enough to ensure the dates are different
//        sleep(2000);
//        assertEquals(1, backgroundedCount);
//
//        // Second Session
//        TuneEventBus.post(new TuneActivityConnected(activity));
//        sleep(500);
//        assertEquals(1, activityConnectedCount);
//
//        String secondSessionStart = TuneAnalyticsVariable.dateToString(new Date(sessionManager.getSession().getCreatedDate()));
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_LAST_DATE, firstSessionStart);
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_CURRENT_DATE, secondSessionStart);
//
//        TuneEventBus.post(new TuneActivityDisconnected(activity));
//        assertEquals(0, activityConnectedCount);
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_LAST_DATE, firstSessionStart);
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_CURRENT_DATE, secondSessionStart);
//
//        // Wait for background event to post
//        backgroundLock = new CountDownLatch(1);
//        backgroundLock.await();
//        sleep(2000);
//        assertEquals(2, backgroundedCount);
//
//        // Third Session
//        TuneEventBus.post(new TuneActivityConnected(activity));
//        sleep(500);
//        assertEquals(1, activityConnectedCount);
//
//        String thirdSessionStart = TuneAnalyticsVariable.dateToString(new Date(sessionManager.getSession().getCreatedDate()));
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_LAST_DATE, secondSessionStart);
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_CURRENT_DATE, thirdSessionStart);
//
//        TuneEventBus.post(new TuneActivityDisconnected(activity));
//        assertEquals(0, activityConnectedCount);
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_LAST_DATE, secondSessionStart);
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_CURRENT_DATE, thirdSessionStart);
//
//        // Wait for background event to post
//        backgroundLock = new CountDownLatch(1);
//        backgroundLock.await();
//        sleep(2000);
//        assertEquals(3, backgroundedCount);
//
//        // Fourth Session w/ new SessionManager + UserProfile
//        freshSessionProfile();
//        TuneEventBus.post(new TuneActivityConnected(activity));
//        sleep(500);
//        assertEquals(1, activityConnectedCount);
//
//        String fourthSessionStart = TuneAnalyticsVariable.dateToString(new Date(sessionManager.getSession().getCreatedDate()));
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_LAST_DATE, thirdSessionStart);
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_CURRENT_DATE, fourthSessionStart);
//
//        TuneEventBus.post(new TuneActivityDisconnected(activity));
//        assertEquals(0, activityConnectedCount);
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_LAST_DATE, thirdSessionStart);
//        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_CURRENT_DATE, fourthSessionStart);
//
//        // Wait for background event to post
//        backgroundLock = new CountDownLatch(1);
//        backgroundLock.await();
//        sleep(2000);
//        assertEquals(4, backgroundedCount);
//
//        TuneEventBus.unregister(this);
//    }

    @Test
    public void testSessionDoesNotEndBeforeSessionTimeout() {
        TuneEventBus.register(this);
        // Register analytics manager to receive session events
        TuneManager.getInstance().getAnalyticsManager().setListener(new TuneAnalyticsListener() {
            @Override
            public void dispatchingRequest(JSONArray events) {
                dispatchCount++;
            }

            @Override
            public void didCompleteRequest(int responseCode) {
            }
        });

        // Screen rotation causes an immediate onStop/onDestroy before onCreate, simulate this with bus events
        // This takes less time than TuneSessionManager.SESSION_TIMEOUT so new session should not be sent
        TuneEventBus.post(new TuneActivityConnected(activity));
        TuneEventBus.post(new TuneActivityDisconnected(activity));
        TuneEventBus.post(new TuneActivityConnected(activity));

        // Give dispatcher some time to start sending
        sleep(500);

        // Assert that analytics manager only dispatched once, for session start
        assertEquals(1, dispatchCount);
        // Assert that TuneAppForegrounded event got sent once over the bus
        assertEquals(1, foregroundedCount);
        // Assert that TuneAppBackgrounded event never got sent over the bus
        assertEquals(0, backgroundedCount);

        TuneEventBus.unregister(this);
    }

    @Test
    public void testSessionEndsAfterSessionTimeout() {
        TuneEventBus.register(this);
        // Register analytics manager to receive session events
        TuneManager.getInstance().getAnalyticsManager().setListener(new TuneAnalyticsListener() {
            @Override
            public void dispatchingRequest(JSONArray events) {
                dispatchCount++;
            }

            @Override
            public void didCompleteRequest(int responseCode) {
            }
        });

        // Simulate session start -> end -> start with bus events
        TuneEventBus.post(new TuneActivityConnected(activity));
        TuneEventBus.post(new TuneActivityDisconnected(activity));
        // Wait SESSION_TIMEOUT (plus some leeway for tests) so that we can trigger a new session
        sleep(TuneSessionManager.SESSION_TIMEOUT + 500);
        TuneEventBus.post(new TuneActivityConnected(activity));

        // Give dispatcher some time to start sending
        sleep(2000);

        // Assert that analytics manager dispatched 2 times, 1 for session start/end and 1 for another session start
        assertEquals(3, dispatchCount);
        // Assert that TuneAppForegrounded event got sent twice over the bus
        assertEquals(2, foregroundedCount);
        // Assert that TuneAppBackgrounded event got sent once over the bus
        assertEquals(1, backgroundedCount);

        TuneEventBus.unregister(this);
    }

    @Subscribe
    public synchronized void onEvent(TuneAppForegrounded event) {
        foregroundedCount++;
    }

    @Subscribe
    public synchronized void onEvent(TuneActivityConnected event) {
        activityConnectedCount++;
    }

    @Subscribe
    public synchronized void onEvent(TuneActivityDisconnected event) {
        activityConnectedCount--;
    }

    @Subscribe
    public synchronized void onEvent(TuneAppBackgrounded event) {
        backgroundedCount++;
        if (backgroundLock != null) {
            backgroundLock.countDown();
        }
    }
}
