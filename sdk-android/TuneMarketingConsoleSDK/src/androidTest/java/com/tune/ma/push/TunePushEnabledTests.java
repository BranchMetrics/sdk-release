package com.tune.ma.push;

import android.content.Context;

import com.tune.TuneUnitTest;
import com.tune.TuneUrlKeys;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.push.TunePushEnabled;
import com.tune.ma.eventbus.event.userprofile.TuneUpdateUserProfile;
import com.tune.ma.profile.TuneProfileKeys;
import com.tune.ma.profile.TuneUserProfile;
import com.tune.ma.utils.TuneSharedPrefsDelegate;

import org.greenrobot.eventbus.Subscribe;

import static com.tune.ma.push.TunePushManager.PREFS_TMA_PUSH;
import static com.tune.ma.push.TunePushManager.PROPERTY_DEVELOPER_PUSH_ENABLED;
import static com.tune.ma.push.TunePushManager.PROPERTY_END_USER_PUSH_ENABLED;

/**
 * Created by charlesgilliam on 2/11/16.
 */
public class TunePushEnabledTests extends TuneUnitTest {
    private TuneUserProfile userProfile;
    private TunePushManager pushManager;

    @Override
    protected void setUp() throws Exception {
        super.setUp();

        userProfile = TuneManager.getInstance().getProfileManager();
        pushManager = new TunePushManagerTesterBase(getContext());
    }

    @Override
    protected void tearDown() throws Exception {
        userProfile.deleteSharedPrefs();
        pushManager.sharedPrefs.clearSharedPreferences();
        super.tearDown();
    }

    // NOTE: These tests are a direct copy from the old SDK using extensions instead of mocks.
    private class TunePushManagerTesterBase extends TunePushManager {
        public TunePushManagerTesterBase(Context context) {
            super(context);
            this.currentAppVersion = "ABC000001";
        }

        public TunePushManagerTesterBase(Context context, String appName) {
            super(context, appName);
        }

        @Override
        // For these tests we never want this method to fire; suppressing lint warn
        @SuppressWarnings("UnnecessaryReturnStatement")
        protected void registerInBackground(final boolean unregisterFirst) {
            return;
        }
    }

    public void testPushShouldBeDisabledIfPreferredEvenIfServicesAreInstalled() throws Exception {
        pushManager.sharedPrefs.clearSharedPreferences();
        pushManager = new TunePushManagerTesterBase(getContext());

        PushEnabledReceiver enabledReceiver = new PushEnabledReceiver();
        TuneEventBus.register(enabledReceiver);
        enabledReceiver.setEnabled(true);
        enabledReceiver.setUpdated(false);

        pushManager.setOptedOutOfPush(true);
        pushManager.ensureDeviceIsRegistered();

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertFalse(enabledReceiver.isEnabled());
        assertTrue(enabledReceiver.isUpdated());
    }

    public void testPushShouldBeEnabled() throws Exception {
        pushManager.sharedPrefs.clearSharedPreferences();
        pushManager = new TunePushManagerTesterBase(getContext());

        PushEnabledReceiver enabledReceiver = new PushEnabledReceiver();
        TuneEventBus.register(enabledReceiver);
        enabledReceiver.setEnabled(false);
        enabledReceiver.setUpdated(false);

        pushManager.setOptedOutOfPush(false);
        pushManager.ensureDeviceIsRegistered();

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_TRUE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertTrue(enabledReceiver.isEnabled());
        assertTrue(enabledReceiver.isUpdated());
    }

    public void testPushShouldBeEnabledIfNoPreferenceSetAndPlayServicesIsAvailable() throws Exception {
        pushManager.sharedPrefs.clearSharedPreferences();
        pushManager = new TunePushManagerTesterBase(getContext());

        PushEnabledReceiver enabledReceiver = new PushEnabledReceiver();
        TuneEventBus.register(enabledReceiver);
        enabledReceiver.setEnabled(false);
        enabledReceiver.setUpdated(false);

        // no preference set
        pushManager.setPushNotificationSenderId("foobar");

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertFalse(enabledReceiver.isEnabled());
        assertFalse(enabledReceiver.isUpdated());
    }

    public void testPushEnabledWhenUserSetsItAsEnabled() throws Exception {
        pushManager.sharedPrefs.clearSharedPreferences();
        pushManager = new TunePushManagerTesterBase(getContext());

        PushEnabledReceiver enabledReceiver = new PushEnabledReceiver();
        TuneEventBus.register(enabledReceiver);
        enabledReceiver.setEnabled(false);
        enabledReceiver.setUpdated(false);

        // Start out without a preference
        assertNull(userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.setPushNotificationSenderId("sender_id");

        // When we register the preference defaults to false
        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertFalse(enabledReceiver.isUpdated());

        pushManager.updatePushEnabled(PROPERTY_END_USER_PUSH_ENABLED, true);

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_TRUE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertTrue(enabledReceiver.isEnabled());
        assertTrue(enabledReceiver.isUpdated());

        enabledReceiver.setUpdated(false);
        pushManager.updatePushEnabled(PROPERTY_END_USER_PUSH_ENABLED, false);

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertFalse(enabledReceiver.isEnabled());
        assertTrue(enabledReceiver.isUpdated());

        pushManager.setOptedOutOfPush(false);

        // The user preference trumps when it is false
        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
    }

    public void testPushEnabledWhenDeveloperOpsOut() throws Exception {
        pushManager.sharedPrefs.clearSharedPreferences();
        pushManager = new TunePushManagerTesterBase(getContext());

        PushEnabledReceiver enabledReceiver = new PushEnabledReceiver();
        TuneEventBus.register(enabledReceiver);
        enabledReceiver.setEnabled(false);
        enabledReceiver.setUpdated(false);

        // Start out without a preference
        assertNull(userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.setPushNotificationSenderId("sender_id");

        // When we register the preference defaults to false
        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertFalse(enabledReceiver.isEnabled());
        assertFalse(enabledReceiver.isUpdated());

        pushManager.setOptedOutOfPush(false);

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_TRUE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertTrue(enabledReceiver.isEnabled());
        assertTrue(enabledReceiver.isUpdated());

        pushManager.setOptedOutOfPush(true);

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertFalse(enabledReceiver.isEnabled());
        assertTrue(enabledReceiver.isUpdated());

        enabledReceiver.setUpdated(false);
        pushManager.updatePushEnabled(PROPERTY_END_USER_PUSH_ENABLED, true);

        // The developer preference trumps when it is false
        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertFalse(enabledReceiver.isEnabled());
        assertFalse(enabledReceiver.isUpdated());
    }

    public void testSettingEnabledBeforeSenderIdIsOkay() throws Exception {
        pushManager.sharedPrefs.clearSharedPreferences();
        pushManager = new TunePushManagerTesterBase(getContext());

        PushEnabledReceiver enabledReceiver = new PushEnabledReceiver();
        TuneEventBus.register(enabledReceiver);
        enabledReceiver.setEnabled(false);
        enabledReceiver.setUpdated(false);

        // Start out without a preference
        assertNull(userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.setOptedOutOfPush(true);

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertFalse(enabledReceiver.isEnabled());
        assertTrue(enabledReceiver.isUpdated());

        enabledReceiver.setEnabled(false);
        enabledReceiver.setUpdated(false);

        pushManager.setPushNotificationSenderId("sender_id");

        // Don't update the enabled status in registerPushSenderId if it is already set
        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertFalse(enabledReceiver.isEnabled());
        assertFalse(enabledReceiver.isUpdated());
    }

    public void testStoredRegistrationIdIsValidForSameAppVersions() throws Exception {
        pushManager.setPushNotificationSenderId("FAKEID");
        pushManager.storePushPrefs("FAKEID"); // pretend we have previously stored a device token

        assertTrue(pushManager.ensureDeviceIsRegistered());
        assertEquals("FAKEID", userProfile.getProfileVariableValue(TuneProfileKeys.DEVICE_TOKEN));
    }

    public void testStoredRegistrationIdIsNotValidForOldAppVersions() throws Exception {
        pushManager.storePushPrefs("FAKEID"); // pretend we have previously stored a device token

        pushManager = new TunePushManagerTesterBase(getContext(), "ABC000002");
        assertFalse(pushManager.ensureDeviceIsRegistered());
        assertNull(userProfile.getProfileVariableValue(TuneProfileKeys.DEVICE_TOKEN));
    }

    public void testStoredRegistrationIdIsNotValidForOldGCMSenderIds() throws Exception {
        pushManager.storePushPrefs("FAKEID"); // pretend we have previously stored a device token

        pushManager.setPushNotificationSenderId("new_gcm_sender_id");// there's a new sender id

        assertFalse(pushManager.ensureDeviceIsRegistered());
        assertNull(userProfile.getProfileVariableValue(TuneProfileKeys.DEVICE_TOKEN));
    }

    public void testSetOptOutOfPushOnProfileManagerSetsPreference() throws Exception {
        PushEnabledReceiver enabledReceiver = new PushEnabledReceiver();
        TuneEventBus.register(enabledReceiver);
        enabledReceiver.setEnabled(true);
        enabledReceiver.setUpdated(false);

        tune.setOptedOutOfPush(true);
        assertFalse(TuneManager.getInstance().getPushManager().isPushEnabled());
        assertFalse(enabledReceiver.isEnabled());
        assertTrue(enabledReceiver.isUpdated());

        enabledReceiver.setEnabled(false);
        enabledReceiver.setUpdated(false);
        tune.setOptedOutOfPush(false);
        assertTrue(TuneManager.getInstance().getPushManager().isPushEnabled());
        assertTrue(enabledReceiver.isEnabled());
        assertTrue(enabledReceiver.isUpdated());
    }

    public void testTooYoungOverridesAllOther() throws Exception {
        pushManager.sharedPrefs.clearSharedPreferences();
        pushManager = new TunePushManagerTesterBase(getContext());

        PushEnabledReceiver enabledReceiver = new PushEnabledReceiver();
        TuneEventBus.register(enabledReceiver);
        enabledReceiver.setEnabled(true);
        enabledReceiver.setUpdated(false);

        // Start out without a preference
        assertNull(userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.setPushNotificationSenderId("sender_id");

        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.AGE, 12)));

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertFalse(enabledReceiver.isEnabled());
        assertTrue(enabledReceiver.isUpdated());

        enabledReceiver.setEnabled(false);
        enabledReceiver.setUpdated(false);
        pushManager.setOptedOutOfPush(false);

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertFalse(enabledReceiver.isEnabled());
        assertFalse(enabledReceiver.isUpdated());

        pushManager.setOptedOutOfPush(true);

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertFalse(enabledReceiver.isEnabled());
        assertFalse(enabledReceiver.isUpdated());

        pushManager.updatePushEnabled(PROPERTY_END_USER_PUSH_ENABLED, true);

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertFalse(enabledReceiver.isEnabled());
        assertFalse(enabledReceiver.isUpdated());

        pushManager.setOptedOutOfPush(false);
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.AGE, 14)));

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_TRUE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertTrue(enabledReceiver.isEnabled());
        assertTrue(enabledReceiver.isUpdated());
    }

    public void testSetRegistrationId() throws Exception {
        PushEnabledReceiver enabledReceiver = new PushEnabledReceiver();
        TuneEventBus.register(enabledReceiver);
        enabledReceiver.setUpdated(false);

        pushManager.setPushNotificationRegistrationId("FAKE_REGISTRATION_ID");

        assertNotNull(userProfile.getProfileVariableValue(TuneProfileKeys.DEVICE_TOKEN));
        assertEquals("FAKE_REGISTRATION_ID", userProfile.getProfileVariableValue(TuneProfileKeys.DEVICE_TOKEN));
        assertFalse(enabledReceiver.isUpdated());
    }

    // Test that push enabled starts out as "NO" until we get a device token asynchronously
    public void testSetSenderIdPushEnabledFalseBeforeDeviceTokenIsRetrieved() {
        pushManager.setPushNotificationSenderId("sender_id");

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        // Since emulator doesn't have GCM, register in background never completes...
        // But we can mock it with setDeviceToken
        pushManager.setDeviceToken("token");

        // Push enabled should be true now that we finished getting a device token
        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_TRUE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertEquals("token", userProfile.getProfileVariableValue(TuneProfileKeys.DEVICE_TOKEN));
        assertEquals("token", pushManager.getDeviceToken());
    }

    // Test that push enabled is "YES" after we load an existing device token
    public void testSetSenderIdSetsPushEnabledAfterRetrievingExistingDeviceToken() {
        // Put some dummy values in SharedPreferences to represent an existing token
        TuneSharedPrefsDelegate sharedPrefs = new TuneSharedPrefsDelegate(getContext(), PREFS_TMA_PUSH);
        sharedPrefs.saveToSharedPreferences("registrationId", "token");
        sharedPrefs.saveToSharedPreferences("appVersion", "ABC000001");
        sharedPrefs.saveToSharedPreferences("gcmSenderId", "sender_id");

        pushManager.setPushNotificationSenderId("sender_id");

        // Push enabled should be true since we're reusing a stored device token
        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_TRUE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertEquals("token", userProfile.getProfileVariableValue(TuneProfileKeys.DEVICE_TOKEN));
        assertEquals("token", pushManager.getDeviceToken());
    }

    // Test that setDeviceToken sets push enabled to "YES" by default
    public void testSetDeviceTokenWithDefaultSettings() throws Exception {
        pushManager.setDeviceToken("token");

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_TRUE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertEquals("token", userProfile.getProfileVariableValue(TuneProfileKeys.DEVICE_TOKEN));
        assertEquals("token", pushManager.getDeviceToken());
    }

    // Test that setDeviceToken sets push enabled to "NO" when user has opted out of push
    public void testSetDeviceTokenWithPushOptedOut() throws Exception {
        pushManager.updatePushEnabled(PROPERTY_END_USER_PUSH_ENABLED, false);
        pushManager.updatePushEnabled(PROPERTY_DEVELOPER_PUSH_ENABLED, false);

        pushManager.setDeviceToken("token");

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertEquals("token", userProfile.getProfileVariableValue(TuneProfileKeys.DEVICE_TOKEN));
        assertEquals("token", pushManager.getDeviceToken());
    }

    // Test that setDeviceToken sets push enabled to "YES" if user has opted in
    public void testSetDeviceTokenWithPushOptedIn() throws Exception {
        pushManager.updatePushEnabled(PROPERTY_END_USER_PUSH_ENABLED, true);
        pushManager.updatePushEnabled(PROPERTY_DEVELOPER_PUSH_ENABLED, true);

        pushManager.setDeviceToken("token");

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_TRUE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
        assertEquals("token", userProfile.getProfileVariableValue(TuneProfileKeys.DEVICE_TOKEN));
        assertEquals("token", pushManager.getDeviceToken());
    }

    public void testPushEnabledOnlyGetsInitializedToFalseOnce() throws Exception {
        PushEnabledReceiver enabledReceiver = new PushEnabledReceiver();
        TuneEventBus.register(enabledReceiver);

        assertEquals(0, enabledReceiver.updatedEnabledCount);

        pushManager.setPushNotificationSenderId("sender_id");

        assertEquals(1, enabledReceiver.updatedEnabledCount);

        pushManager.setPushNotificationSenderId("sender_id");

        assertEquals(1, enabledReceiver.updatedEnabledCount);

        TuneEventBus.unregister(enabledReceiver);
    }

    // Helpers
    ///////////

    class PushEnabledReceiver {
        boolean enabled;
        boolean updated;
        int updatedEnabledCount = 0;

        public PushEnabledReceiver() {

        }

        @Subscribe
        public void onEvent(TunePushEnabled event) {
            enabled = event.isEnabled();
            updated = true;
        }

        @Subscribe
        public void onEvent(TuneUpdateUserProfile event) {
            // Increment count for push enabled event
            if (event.getVariable().getName().equals(TuneProfileKeys.IS_PUSH_ENABLED)) {
                updatedEnabledCount++;
            }
        }

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public boolean isUpdated() {
            return updated;
        }

        public void setUpdated(boolean updated) {
            this.updated = updated;
        }
    }
}
