package com.tune.ma.push;

import android.content.Context;

import com.tune.TuneUnitTest;
import com.tune.TuneUrlKeys;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.userprofile.TuneUpdateUserProfile;
import com.tune.ma.profile.TuneProfileKeys;
import com.tune.ma.profile.TuneUserProfile;

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

        // For these tests we never want this method to fire
        @Override
        protected void registerInBackground(final boolean unregisterFirst) {
            return;
        }
    }

    public void testPushShouldBeDisabledIfPreferredEvenIfServicesAreInstalled() throws Exception {
        pushManager.sharedPrefs.clearSharedPreferences();
        pushManager = new TunePushManagerTesterBase(getContext()) {
            /*@Override
            public boolean isGooglePlayServicesAvailable() {
                return true;
            }*/
        };

        pushManager.setOptedOutOfPush(true);
        pushManager.ensureDeviceIsRegistered();

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
    }
/*
    // These tests currently does not apply because we are not currently checking against google play services
    public void testPushShouldBeDisabledIfNoPreferenceSetAndPlayServicesIsNotAvailable() throws Exception {
        pushManager = new TunePushManagerTesterBase(getContext()) {
            @Override
            public boolean isGooglePlayServicesAvailable() {
                return false;
            }
        };

        // no preference set
        pushManager.initializePush();

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
    }

    public void testPushShouldBeDisabled() throws Exception {
        pushManager = new TunePushManagerTesterBase(getContext()) {
            @Override
            public boolean isGooglePlayServicesAvailable() {
                return false;
            }
        };

        pushManager.storePushEnabledPreference(false);
        pushManager.initializePush();

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
    }
    */

    public void testPushShouldBeEnabled() throws Exception {
        pushManager.sharedPrefs.clearSharedPreferences();
        pushManager = new TunePushManagerTesterBase(getContext()) {
            /*@Override
            public boolean isGooglePlayServicesAvailable() {
                return true;
            }*/
        };

        pushManager.setOptedOutOfPush(false);
        pushManager.ensureDeviceIsRegistered();

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_TRUE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
    }

    public void testPushShouldBeEnabledIfNoPreferenceSetAndPlayServicesIsAvailable() throws Exception {
        pushManager.sharedPrefs.clearSharedPreferences();
        pushManager = new TunePushManagerTesterBase(getContext()) {
            /*@Override
            public boolean isGooglePlayServicesAvailable() {
                return true;
            }*/
        };

        // no preference set
        pushManager.setPushNotificationSenderId("foobar");

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_TRUE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
    }

    public void testPushEnabledWhenUserSetsItAsEnabled() throws Exception {
        pushManager.sharedPrefs.clearSharedPreferences();
        pushManager = new TunePushManagerTesterBase(getContext()) {
            /*@Override
            public boolean isGooglePlayServicesAvailable() {
                return true;
            }*/
        };

        // Start out without a preference
        assertNull(userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.setPushNotificationSenderId("sender_id");

        // When we register the preference defaults to true
        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_TRUE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.updatePushEnabled(TunePushManager.PROPERTY_END_USER_PUSH_ENABLED, true);

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_TRUE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.updatePushEnabled(TunePushManager.PROPERTY_END_USER_PUSH_ENABLED, false);

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.setOptedOutOfPush(false);

        // The user preference trumps when it is false
        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
    }

    public void testPushEnabledWhenDeveloperOpsOut() throws Exception {
        pushManager.sharedPrefs.clearSharedPreferences();
        pushManager = new TunePushManagerTesterBase(getContext()) {
            /*@Override
            public boolean isGooglePlayServicesAvailable() {
                return true;
            }*/
        };

        // Start out without a preference
        assertNull(userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.setPushNotificationSenderId("sender_id");

        // When we register the preference defaults to true
        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_TRUE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.setOptedOutOfPush(false);

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_TRUE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.setOptedOutOfPush(true);

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.updatePushEnabled(TunePushManager.PROPERTY_END_USER_PUSH_ENABLED, true);

        // The developer preference trumps when it is false
        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
    }

    public void testSettingEnabledBeforeSenderIdIsOkay() throws Exception {
        pushManager.sharedPrefs.clearSharedPreferences();
        pushManager = new TunePushManagerTesterBase(getContext()) {
            /*@Override
            public boolean isGooglePlayServicesAvailable() {
                return true;
            }*/
        };

        // Start out without a preference
        assertNull(userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.setOptedOutOfPush(true);

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.setPushNotificationSenderId("sender_id");

        // Don't update the enabled status in registerPushSenderId if it is already set
        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
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
        tune.setOptedOutOfPush(true);
        assertFalse(TuneManager.getInstance().getPushManager().isPushEnabled());

        tune.setOptedOutOfPush(false);
        assertTrue(TuneManager.getInstance().getPushManager().isPushEnabled());
    }

    public void testTooYoungOverridesAllOther() throws Exception {
        pushManager.sharedPrefs.clearSharedPreferences();
        pushManager = new TunePushManagerTesterBase(getContext()) {
            /*@Override
            public boolean isGooglePlayServicesAvailable() {
                return true;
            }*/
        };

        // Start out without a preference
        assertNull(userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.setPushNotificationSenderId("sender_id");

        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.AGE, 12)));

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.setOptedOutOfPush(false);

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.setOptedOutOfPush(true);

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.updatePushEnabled(TunePushManager.PROPERTY_END_USER_PUSH_ENABLED, true);

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_FALSE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));

        pushManager.setOptedOutOfPush(false);
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.AGE, 14)));

        assertEquals(TuneAnalyticsVariable.IOS_BOOLEAN_TRUE, userProfile.getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED));
    }

    public void testSetRegistrationId() throws Exception {
        pushManager.setPushNotificationRegistrationId("FAKE_REGISTRATION_ID");

        assertNotNull(userProfile.getProfileVariableValue(TuneProfileKeys.DEVICE_TOKEN));
        assertEquals("FAKE_REGISTRATION_ID", userProfile.getProfileVariableValue(TuneProfileKeys.DEVICE_TOKEN));
    }
}
