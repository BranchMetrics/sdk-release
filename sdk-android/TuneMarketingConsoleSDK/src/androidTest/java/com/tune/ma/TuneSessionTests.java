package com.tune.ma;

import android.content.Context;

import com.tune.TuneUnitTest;
import com.tune.ma.analytics.model.TuneAnalyticsListener;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.application.TuneActivity;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneActivityConnected;
import com.tune.ma.eventbus.event.TuneActivityDisconnected;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.profile.TuneProfileKeys;
import com.tune.ma.profile.TuneUserProfile;
import com.tune.ma.session.TuneSessionManager;

import org.json.JSONArray;
import org.mockito.Mock;

import java.util.Date;

/**
 * Created by kristine on 1/13/16.
 */
public class TuneSessionTests extends TuneUnitTest {

    @Mock
    TuneActivity activity;

    private int foregroundedCount;
    private int backgroundedCount;
    private int dispatchCount;
    private Context context;
    private TuneSessionManager sessionManager;
    private TuneUserProfile userProfile;

    @Override
    protected void setUp() throws Exception {
        super.setUp();
        context = getContext();

        sessionManager = TuneManager.getInstance().getSessionManager();
        assertNotNull(sessionManager);
        userProfile = TuneManager.getInstance().getProfileManager();
        assertNotNull(userProfile);
        
        foregroundedCount = 0;
        backgroundedCount = 0;
        dispatchCount = 0;
    }

    @Override
    protected void tearDown() throws Exception {
        TuneEventBus.post(new TuneAppBackgrounded());
        sleep(TuneSessionManager.SESSION_TIMEOUT + 500);
        TuneSessionManager.clearInstance();

        super.tearDown();
    }

    public void freshSessionProfile() {
        TuneManager.destroy();
        TuneManager.init(context, null);

        sessionManager = TuneManager.getInstance().getSessionManager();
        userProfile = TuneManager.getInstance().getProfileManager();
    }

    public void checkProfileMemAndPrefsDoesntExist(String key) {
        assertNull(userProfile.getProfileVariable(key));
        assertNull(userProfile.getProfileVariableFromPrefs(key));
    }

    public void checkProfileMemAndPrefsValueNull(String key) {
        assertNull(userProfile.getProfileVariable(key).getValue());
        assertNull(userProfile.getProfileVariableFromPrefs(key).getValue());
    }

    public void checkProfileMemAndPrefs(String key, String against) {
        assertTrue(against.equalsIgnoreCase(userProfile.getProfileVariable(key).getValue()));
        assertTrue(against.equalsIgnoreCase(userProfile.getProfileVariableFromPrefs(key).getValue()));
    }

    public void testSessionStart() {
        assertNull(sessionManager.getSession());
        assertEquals(sessionManager.getConnectedActivities().size(), 0);

        TuneEventBus.post(new TuneActivityConnected(activity));

        assertNotNull(sessionManager.getSession());
        assertEquals(sessionManager.getConnectedActivities().size(), 1);
        assertNotNull(sessionManager.getSession().getCreatedDate());
        assertEquals(sessionManager.getSession().getSessionLength(), 0);
    }

    public void testSessionEnd() {
        assertNull(sessionManager.getSession());
        assertEquals(sessionManager.getConnectedActivities().size(), 0);

        TuneEventBus.post(new TuneActivityConnected(activity));

        assertEquals(sessionManager.getConnectedActivities().size(), 1);
        assertNotNull(sessionManager.getSession());

        // Wait a little so session length doesn't possibly get set to zero and fail our test
        sleep(100);

        TuneEventBus.post(new TuneActivityDisconnected(activity));
        sleep(TuneSessionManager.SESSION_TIMEOUT + 500);

        assertEquals(sessionManager.getConnectedActivities().size(), 0);
        assertNotNull(sessionManager.getSession());
        assertTrue(sessionManager.getSession().getSessionLength() > 0);
    }

    public void testFirstSession() {
        checkProfileMemAndPrefsDoesntExist(TuneProfileKeys.IS_FIRST_SESSION);

        // First Session
        TuneEventBus.post(new TuneActivityConnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.IS_FIRST_SESSION, "1");
        TuneEventBus.post(new TuneActivityDisconnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.IS_FIRST_SESSION, "1");

        sleep(1250);

        // Second Session
        TuneEventBus.post(new TuneActivityConnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.IS_FIRST_SESSION, "0");
        TuneEventBus.post(new TuneActivityDisconnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.IS_FIRST_SESSION, "0");

        sleep(1250);

        // Third Session
        TuneEventBus.post(new TuneActivityConnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.IS_FIRST_SESSION, "0");
        TuneEventBus.post(new TuneActivityDisconnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.IS_FIRST_SESSION, "0");

        sleep(1250);

        // Fourth Session w/ new SessionManager + UserProfile
        freshSessionProfile();
        TuneEventBus.post(new TuneActivityConnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.IS_FIRST_SESSION, "0");
        TuneEventBus.post(new TuneActivityDisconnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.IS_FIRST_SESSION, "0");
    }

    public void testSessionCount() {
        checkProfileMemAndPrefsDoesntExist(TuneProfileKeys.SESSION_COUNT);

        // First Session
        TuneEventBus.post(new TuneActivityConnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_COUNT, "1");
        TuneEventBus.post(new TuneActivityDisconnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_COUNT, "1");

        sleep(1250);

        // Second Session
        TuneEventBus.post(new TuneActivityConnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_COUNT, "2");
        TuneEventBus.post(new TuneActivityDisconnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_COUNT, "2");

        sleep(1250);

        // Third Session
        TuneEventBus.post(new TuneActivityConnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_COUNT, "3");
        TuneEventBus.post(new TuneActivityDisconnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_COUNT, "3");

        sleep(1250);

        // Fourth Session w/ new SessionManager + UserProfile
        freshSessionProfile();
        TuneEventBus.post(new TuneActivityConnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_COUNT, "4");
        TuneEventBus.post(new TuneActivityDisconnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_COUNT, "4");
    }

    public void testLastCurrentSessionDate() {
        checkProfileMemAndPrefsDoesntExist(TuneProfileKeys.SESSION_LAST_DATE);
        checkProfileMemAndPrefsDoesntExist(TuneProfileKeys.SESSION_CURRENT_DATE);

        // First Session
        TuneEventBus.post(new TuneActivityConnected(activity));
        String firstSessionStart = TuneAnalyticsVariable.dateToString(new Date(sessionManager.getSession().getCreatedDate()));
        checkProfileMemAndPrefsValueNull(TuneProfileKeys.SESSION_LAST_DATE);
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_CURRENT_DATE, firstSessionStart);
        TuneEventBus.post(new TuneActivityDisconnected(activity));
        checkProfileMemAndPrefsValueNull(TuneProfileKeys.SESSION_LAST_DATE);
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_CURRENT_DATE, firstSessionStart);

        // We only track session starts to seconds, so we need to wait long enough to ensure the dates are different
        sleep(2000);

        // Second Session
        TuneEventBus.post(new TuneActivityConnected(activity));
        String secondSessionStart = TuneAnalyticsVariable.dateToString(new Date(sessionManager.getSession().getCreatedDate()));
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_LAST_DATE, firstSessionStart);
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_CURRENT_DATE, secondSessionStart);
        TuneEventBus.post(new TuneActivityDisconnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_LAST_DATE, firstSessionStart);
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_CURRENT_DATE, secondSessionStart);

        sleep(2000);

        // Third Session
        TuneEventBus.post(new TuneActivityConnected(activity));
        String thirdSessionStart = TuneAnalyticsVariable.dateToString(new Date(sessionManager.getSession().getCreatedDate()));
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_LAST_DATE, secondSessionStart);
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_CURRENT_DATE, thirdSessionStart);
        TuneEventBus.post(new TuneActivityDisconnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_LAST_DATE, secondSessionStart);
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_CURRENT_DATE, thirdSessionStart);

        sleep(2000);

        // Fourth Session w/ new SessionManager + UserProfile
        freshSessionProfile();
        TuneEventBus.post(new TuneActivityConnected(activity));
        String fourthSessionStart = TuneAnalyticsVariable.dateToString(new Date(sessionManager.getSession().getCreatedDate()));
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_LAST_DATE, thirdSessionStart);
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_CURRENT_DATE, fourthSessionStart);
        TuneEventBus.post(new TuneActivityDisconnected(activity));
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_LAST_DATE, thirdSessionStart);
        checkProfileMemAndPrefs(TuneProfileKeys.SESSION_CURRENT_DATE, fourthSessionStart);
    }

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

        // Assert that analytics manager dispatched 3 times, 2 for session starts and 1 for session end
        assertEquals(3, dispatchCount);
        // Assert that TuneAppForegrounded event got sent twice over the bus
        assertEquals(2, foregroundedCount);
        // Assert that TuneAppBackgrounded event got sent once over the bus
        assertEquals(1, backgroundedCount);

        TuneEventBus.unregister(this);
    }

    public void onEvent(TuneAppForegrounded event) {
        foregroundedCount++;
    }

    public void onEvent(TuneAppBackgrounded event) {
        backgroundedCount++;
    }
}
