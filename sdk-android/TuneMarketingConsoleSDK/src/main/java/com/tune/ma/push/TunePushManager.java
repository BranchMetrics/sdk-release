package com.tune.ma.push;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;

import com.tune.TuneUrlKeys;
import com.tune.TuneUtils;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.constants.TuneVariableType;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.push.TunePushEnabled;
import com.tune.ma.eventbus.event.userprofile.TuneUpdateUserProfile;
import com.tune.ma.profile.TuneProfileKeys;
import com.tune.ma.push.model.TunePushMessage;
import com.tune.ma.push.settings.TuneNotificationBuilder;
import com.tune.ma.push.settings.TunePushListener;
import com.tune.ma.utils.TuneDebugLog;
import com.tune.ma.utils.TuneOptional;
import com.tune.ma.utils.TuneSharedPrefsDelegate;
import com.tune.ma.utils.TuneStringUtils;

import org.json.JSONException;

import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class TunePushManager {
    public static final String PREFS_TMA_PUSH = "com.tune.ma.push";

    public static final String PROPERTY_NOTIFICATION_BUILDER = "notificationBuilder";
    private static final String PROPERTY_REG_ID = "registrationId";
    private static final String PROPERTY_APP_VERSION = "appVersion";
    private static final String PROPERTY_GCM_SENDER = "gcmSenderId";
    static final String PROPERTY_DEVELOPER_PUSH_ENABLED = "developerPushEnabledPreference"; // has the developer turned off push?
    static final String PROPERTY_END_USER_PUSH_ENABLED = "userPushEnabledPreference"; // has the end user turned off push?
    static final String PROPERTY_IS_COPPA = "isCoppa";

    private Context context;
    TuneSharedPrefsDelegate sharedPrefs;
    protected String currentAppVersion;
    // Storing this as an object since we get it as the result of an invocation
    private Object gcm;
    private ExecutorService executorService;

    private String pushSenderId;

    private Set<String> processedMessages;

    private TunePushMessage lastOpenedPushMessage;

    private TunePushListener tunePushListener;

    public TunePushManager(Context context) {
        this(context, TuneManager.getInstance().getProfileManager().getProfileVariableValue(TuneProfileKeys.APP_BUILD));
    }

    public TunePushManager(Context context, String currentAppVersion) {
        this.context = context;
        this.sharedPrefs = new TuneSharedPrefsDelegate(context, PREFS_TMA_PUSH);
        this.currentAppVersion = currentAppVersion;
        // We clear out this key every time since if the user DOESN'T want to use the builder anymore, they can just remove the register call
        // If we don't clear this out then we will just use the builder last set by register
        // TODO: There may be a better way to handle this.
        sharedPrefs.remove(PROPERTY_NOTIFICATION_BUILDER);
        
        executorService = Executors.newSingleThreadExecutor();

        // This set does not need to be serialized because it exists to prevent push actions from triggering from the same activity twice
        //   EG Open push, perform deep action, background, foreground.
        processedMessages = new HashSet<String>();
    }

    public void onEvent(TuneAppForegrounded event) {
        if (Build.VERSION.SDK_INT >= 19) {
            executorService.execute(new Runnable() {
                @Override
                public void run() {
                    checkUserPushDisabledSetting();
                }
            });
        }
    }

    public synchronized void onEvent(TuneAppBackgrounded event) {
        lastOpenedPushMessage = null;
    }

    public void onEvent(TuneUpdateUserProfile event) {
        TuneAnalyticsVariable var = event.getVariable();
        if (TuneUrlKeys.AGE.equals(var.getName())) {
            int age = Integer.parseInt(var.getValue());
            if (age < 13) {
                updatePushEnabled(PROPERTY_IS_COPPA, true);
            } else {
                updatePushEnabled(PROPERTY_IS_COPPA, false);
            }
        }
    }

    private boolean checkUserPushDisabledSetting() {
        // WARNING: This is run on a background thread because it takes a long time to run due to all the reflection
        try {
            int notificationStatusCode = TuneGooglePlayServicesDelegate.isNotificationEnabled(context);
            int statusAllowed = TuneGooglePlayServicesDelegate.getAppOpsManagerModeAllowed();

            if (notificationStatusCode == statusAllowed) {
                updatePushEnabled(PROPERTY_END_USER_PUSH_ENABLED, true);
                return false;
            } else {
                updatePushEnabled(PROPERTY_END_USER_PUSH_ENABLED, false);
                return true;
            }
        } catch (Exception e) {
            TuneDebugLog.w("Failed to check push status", e);
            // if we fail assume the best (and most likely) case
            return false;
        }
    }

    /**
     * Check if this device is already registered (and if the registration is for this version of the app) this device.
     * If not then register in the background and store the result for later.
     *
     * @return true if the device was already registered and the device token is still valid. If false, this will automatically trigger a register/re-register
     */
    public boolean ensureDeviceIsRegistered() {
        String storedRegistrationId = sharedPrefs.getStringFromSharedPreferences(PROPERTY_REG_ID);

        boolean registeredAlready = false;
        // if this is a fresh install we need to unregister the push token so that we are sure each Tune device id has a unique push token
        boolean isNewAppVersion = !isAppVersionSameForStoredRegistrationId();
        boolean isNewGCMSender = !isGCMSenderSameForStoredRegistrationId();
        if ((storedRegistrationId != null && storedRegistrationId.isEmpty()) || isNewAppVersion || isNewGCMSender) {
            TuneDebugLog.d("Need to register device");
            // TODO: Verify that we want to send this with a null value
            TuneEventBus.post(new TuneUpdateUserProfile(
                    TuneAnalyticsVariable.Builder(TuneProfileKeys.DEVICE_TOKEN)
                        .withType(TuneVariableType.STRING)
                        .build()));
            storePushPrefs(null);
            boolean unregisterFirst = !storedRegistrationId.isEmpty() && isNewGCMSender;
            registerInBackground(unregisterFirst);
        } else {
            registeredAlready = true;
            setDeviceToken(storedRegistrationId);
        }

        return registeredAlready;
    }

    protected boolean isGooglePlayServicesAvailable() {
        // NOTE: we used to check for isGooglePlayServicesAvailable() when registering, but since push can still work if
        //        this check fails we decided to disable it for now. Since everything push related is try-catch'd
        //        due to the reflection we won't crash.
        //   Keeping this around in case we want to use it again in the future to pop up a dialog, etc.
        boolean playServicesInstalled = false;
        try {
            int resultCode = TuneGooglePlayServicesDelegate.isGooglePlayServicesAvailable(this.context);
            int connectionResultSuccess = TuneGooglePlayServicesDelegate.getConnectionResultSuccessField();
            if (resultCode == connectionResultSuccess) {
                playServicesInstalled = true;
                TuneDebugLog.i("Play Services are enabled");
            } else {
                if (TuneGooglePlayServicesDelegate.isUserRecoverable(resultCode)) {
                    // we don't invite the app user to download google play services. That will be up to the app developer to detect and set up as they like
                    TuneDebugLog.e("User needs to install Google Play Services.");
                } else {
                    TuneDebugLog.e("This device does not support Push Notifications.");
                }
            }
        } catch (Exception e) {
            TuneDebugLog.w("Failed to check if google play services is available: ", e);
        }
        return playServicesInstalled;
    }

    private boolean isAppVersionSameForStoredRegistrationId() {
        String registeredAppVersion = sharedPrefs.getStringFromSharedPreferences(PROPERTY_APP_VERSION);
        if (registeredAppVersion == null) {
            return currentAppVersion == null;
        } else {
            return registeredAppVersion.equals(currentAppVersion);
        }
    }

    private boolean isGCMSenderSameForStoredRegistrationId() {
        String registeredGCMSender = sharedPrefs.getStringFromSharedPreferences(PROPERTY_GCM_SENDER);
        if (registeredGCMSender == null) {
            return pushSenderId == null;
        } else {
            return registeredGCMSender.equals(pushSenderId);
        }
    }

    /**
     * Unregisters and Re-registers the application with GCM servers asynchronously.
     * <br>
     * Stores the registration ID, app versionCode, and Tune device id in the application's shared preferences.
     *
     * @param unregisterFirst True if the application should be unregistered first
     */
    protected void registerInBackground(final boolean unregisterFirst) {
        executorService.execute(new Runnable() {
            @Override
            public void run() {
                String msg = "";
                try {
                    if (gcm == null) {
                        gcm = TuneGooglePlayServicesDelegate.getGCMInstance(context);
                    }
                    if (unregisterFirst) {
                        TuneGooglePlayServicesDelegate.unregisterGCM(gcm);
                        msg = "Successfully unregistered device. Re-registering now... ";
                    }
                    if (pushSenderId != null) {
                        String registrationId = TuneGooglePlayServicesDelegate.registerGCM(gcm, pushSenderId);
                        msg += "Successful registration: " + registrationId;

                        setDeviceToken(registrationId);
                    }
                } catch (Exception ex) {
                    msg += "Error: " + ex;
                }
                TuneDebugLog.w(msg);
            }
        });
    }

    /**
     * Helper method to update the device token in SharedPreferences, UserProfile and set the push enabled status
     * @param deviceToken Device token for push notifications
     */
    protected void setDeviceToken(String deviceToken) {
        TuneDebugLog.alwaysLog("Tune Push Device Registration Id: " + deviceToken);

        storePushPrefs(deviceToken);
        TuneEventBus.post(new TuneUpdateUserProfile(
                TuneAnalyticsVariable.Builder(TuneProfileKeys.DEVICE_TOKEN)
                        .withValue(deviceToken)
                        .build()));

        // Update the push enabled status now that we have device token
        // Set push enabled status based on whether user opted out of push
        String pushEnabledStatus = TuneAnalyticsVariable.IOS_BOOLEAN_FALSE;
        if (isPushEnabled()) {
            pushEnabledStatus = TuneAnalyticsVariable.IOS_BOOLEAN_TRUE;
        }
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneProfileKeys.IS_PUSH_ENABLED, pushEnabledStatus)));
    }

    /**
     * Stores the registration ID and app versionCode in the application's {@code SharedPreferences}.
     *
     * @param regId registration ID
     */
    protected void storePushPrefs(String regId) {
        sharedPrefs.saveToSharedPreferences(PROPERTY_REG_ID, regId);
        sharedPrefs.saveToSharedPreferences(PROPERTY_APP_VERSION, currentAppVersion);
        sharedPrefs.saveToSharedPreferences(PROPERTY_GCM_SENDER, pushSenderId);
    }

    public synchronized TuneOptional<TunePushMessage> checkGetPushFromActivity(Activity activity) {
        Intent intent = activity.getIntent();
        if (intent == null) {
            return TuneOptional.empty();
        }

        Bundle extras = intent.getExtras();
        if (extras == null || !extras.containsKey(TunePushMessage.TUNE_EXTRA_MESSAGE)) {
            return TuneOptional.empty();
        }

        TunePushMessage message;
        try {
            message = new TunePushMessage(extras.getString(TunePushMessage.TUNE_EXTRA_MESSAGE));
        } catch (JSONException e) {
            TuneDebugLog.e("Error building push message in activity: ", e);
            return TuneOptional.empty();
        }

        // Since we can deeplink into other apps, we need to check if this push if for THIS app.
        // If not it isn't our message to process.
        if (!TuneManager.getInstance().getProfileManager().getAppId().equals(message.getAppId())) {
            return TuneOptional.empty();
        }


        if (processedMessages.contains(message.getMessageIdentifier())) {
            return TuneOptional.empty();
        } else {
            processedMessages.add(message.getMessageIdentifier());
        }

        lastOpenedPushMessage = message;
        return TuneOptional.of(message);
    }

    public boolean isPushEnabled() {
        boolean endUserPushEnabled = sharedPrefs.getBooleanFromSharedPreferences(PROPERTY_END_USER_PUSH_ENABLED, true);
        boolean developerPushEnabled = sharedPrefs.getBooleanFromSharedPreferences(PROPERTY_DEVELOPER_PUSH_ENABLED, true);
        boolean tooYoungForPush = sharedPrefs.getBooleanFromSharedPreferences(PROPERTY_IS_COPPA, false);

        if (tooYoungForPush) {
            // COPPA doesn't allow us to send push to people we know to be younger than 14
            return false;
        } else if (endUserPushEnabled && developerPushEnabled) {
            return true;
        } else {
            // if the app user OR developer has explicitly turned off push make sure we don't set it to enabled.
            return false;
        }
    }

    private boolean isPushStatusDetermined() {
        return sharedPrefs.contains(PROPERTY_DEVELOPER_PUSH_ENABLED) || sharedPrefs.contains(PROPERTY_END_USER_PUSH_ENABLED) || sharedPrefs.contains(PROPERTY_IS_COPPA);
    }

    synchronized void updatePushEnabled(String key, boolean newKeyValue) {
        boolean keyExisted = sharedPrefs.contains(key);
        boolean oldKeyValue = sharedPrefs.getBooleanFromSharedPreferences(key);

        boolean pushPreviouslyDetermined = isPushStatusDetermined();
        boolean oldPushEnabled = isPushEnabled();

        sharedPrefs.saveBooleanToSharedPreferences(key, newKeyValue);

        if (!keyExisted || oldKeyValue != newKeyValue) {
            boolean newPushEnabled = isPushEnabled();
            String varValue = newPushEnabled ? TuneAnalyticsVariable.IOS_BOOLEAN_TRUE : TuneAnalyticsVariable.IOS_BOOLEAN_FALSE;
            TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneProfileKeys.IS_PUSH_ENABLED, varValue)));

            // if push-enabled status has changed
            if (!pushPreviouslyDetermined || oldPushEnabled != newPushEnabled) {
                TuneEventBus.post(new TunePushEnabled(newPushEnabled));
            }
        }
    }

    // ****************************
    // Publicly Exposed Methods
    // ****************************

    public void setPushNotificationSenderId(String pushSenderId) {
        // IMPORTANT: 'checkPushSettings' can be a little flakey (giving false positives) until such a time that it stops giving false positives we shouldn't do it.
        //checkPushSettings("registerPushSenderId");
        if (pushSenderId == null) {
            TuneDebugLog.IAMConfigError("The push sender can not be null in 'setPushNotificationSenderId'");
        }

        // Initialize push enabled to false if it hasn't been set, until we get a device token
        if (TuneManager.getInstance().getProfileManager().getProfileVariableValue(TuneProfileKeys.IS_PUSH_ENABLED) == null) {
            TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneProfileKeys.IS_PUSH_ENABLED, TuneAnalyticsVariable.IOS_BOOLEAN_FALSE)));
        }

        this.pushSenderId = pushSenderId;
        ensureDeviceIsRegistered();
    }

    public void setPushNotificationRegistrationId(String registrationId) {
        // IMPORTANT: 'checkPushSettings' can be a little flakey (giving false positives) until such a time that it stops giving false positives we shouldn't do it.
        //checkPushSettings("setPushNotificationRegistrationId");
        if (registrationId == null) {
            TuneDebugLog.IAMConfigError("The device token can not be null in 'setPushNotificationRegistrationId'");
        }

        setDeviceToken(registrationId);
    }

    public void setTuneNotificationBuilder(TuneNotificationBuilder toStore) {
        // IMPORTANT: 'checkPushSettings' can be a little flakey (giving false positives) until such a time that it stops giving false positives we shouldn't do it.
        //checkPushSettings("setTuneNotificationBuilder");

        try {
            sharedPrefs.saveToSharedPreferences(PROPERTY_NOTIFICATION_BUILDER, toStore.toJson().toString());
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void setOptedOutOfPush(boolean optedOut) {
        // IMPORTANT: 'checkPushSettings' can be a little flakey (giving false positives) until such a time that it stops giving false positives we shouldn't do it.
        //checkPushSettings("setOptedOutOfPush");

        updatePushEnabled(PROPERTY_DEVELOPER_PUSH_ENABLED, !optedOut);
    }

    // returns the stored registration id (device token), otherwise null
    public String getDeviceToken() {
        return sharedPrefs.getStringFromSharedPreferences(PROPERTY_REG_ID, null);
    }

    public synchronized boolean didOpenFromTunePushThisSession() {
        return lastOpenedPushMessage != null;
    }

    public synchronized TunePushInfo getLastOpenedPushInfo() {
        if (lastOpenedPushMessage == null) {
            return null;
        }

        TunePushInfo info = new TunePushInfo();
        info.setCampaignId(lastOpenedPushMessage.getCampaign().getCampaignId());
        info.setPushId(lastOpenedPushMessage.getCampaign().getVariationId());
        info.setExtrasPayload(lastOpenedPushMessage.getPayload().getUserExtraPayloadParams());
        return info;
    }

    public boolean didUserManuallyDisablePush() {
        if (Build.VERSION.SDK_INT >= 19) {
            return checkUserPushDisabledSetting();
        } else {
            return false;
        }
    }

    private void checkPushSettings(String methodName) {
        checkPushPermissionsHelper("com.google.android.c2dm.permission.RECEIVE", methodName);
        checkPushPermissionsHelper(Manifest.permission.WAKE_LOCK, methodName);
        checkPushPermissionsHelper(context.getPackageName() + ".permission.C2D_MESSAGE", methodName);
        try {
            Object gcm = TuneGooglePlayServicesDelegate.getGCMInstance(context);
        } catch (Exception e) {
            TuneDebugLog.IAMConfigError("Could not find com.google.android.gms.gcm.GoogleCloudMessaging, make sure you are building with it.");
        }
    }

    private void checkPushPermissionsHelper(String permission, String methodName) {
        if (!TuneUtils.hasPermission(context, permission)) {
            TuneDebugLog.IAMConfigError(TuneStringUtils.format("You need the '%s' permission in your manifest to use push and '%s'", permission, methodName));
        }
    }

    public void setTunePushListener(TunePushListener tunePushListener) {
        this.tunePushListener = tunePushListener;
    }

    public TunePushListener getTunePushListener() {
        return tunePushListener;
    }
}
