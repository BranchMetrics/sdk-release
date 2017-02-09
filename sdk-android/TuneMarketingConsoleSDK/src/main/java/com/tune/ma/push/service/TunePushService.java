package com.tune.ma.push.service;

import android.app.IntentService;
import android.content.Intent;
import android.os.Bundle;

import com.tune.TuneConstants;
import com.tune.ma.TuneManager;
import com.tune.ma.configuration.TuneConfigurationConstants;
import com.tune.ma.push.TuneGooglePlayServicesDelegate;
import com.tune.ma.push.TunePushManager;
import com.tune.ma.push.model.TunePushMessage;
import com.tune.ma.push.settings.TunePushListener;
import com.tune.ma.utils.TuneDebugLog;
import com.tune.ma.utils.TuneSharedPrefsDelegate;
import com.tune.ma.utils.TuneStringUtils;

import java.util.Set;

public class TunePushService extends IntentService {

    public TunePushService() {
        super("TunePushService");
    }

    @Override
    protected void onHandleIntent(Intent intent) {
        TuneDebugLog.d("PushService received intent");

        handleIntent(intent);

        // Release the wake lock provided by the WakefulBroadcastReceiver.
        TunePushReceiver.completeWakefulIntent(intent);
    }

    private void handleIntent(Intent intent) {
        if (intent == null) {
            TuneDebugLog.w("PushService received null intent.");
            return;
        }

        Bundle extras = intent.getExtras();
        TuneSharedPrefsDelegate prefs = new TuneSharedPrefsDelegate(getApplicationContext(), TuneConstants.PREFS_TUNE);

        if (prefs.getBooleanFromSharedPreferences(TuneConfigurationConstants.TUNE_TMA_DISABLED) ||
                prefs.getBooleanFromSharedPreferences(TuneConfigurationConstants.TUNE_TMA_PERMANENTLY_DISABLED)) {
            TuneDebugLog.d("Not creating push message because IAM is disabled");
            return;
        }

        if (extras.isEmpty()) {
            TuneDebugLog.w("The received intent did not have any extras, so there is nothing to process.");
            return;
        }

        try {
            Object gcm = TuneGooglePlayServicesDelegate.getGCMInstance(this);

            String gcmMessageType = TuneGooglePlayServicesDelegate.getMessageType(gcm, intent);

            String messageType = TuneGooglePlayServicesDelegate.getGoogleCloudMessagingMessageTypeMessageField();

            if (gcmMessageType != null && gcmMessageType.equals(messageType)) {
                tryEchoPush(extras);
                buildAndSendMessage(extras);
            } else {
                TuneDebugLog.w(TuneStringUtils.format("Tune doesn't handle messageType \"%s\" expected \"%s\"", gcmMessageType, messageType));
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    protected boolean notifyListener(TunePushMessage message) {
        boolean displayNotification = true;
        if (TuneManager.getInstance() != null) {
            TunePushManager pushManager = TuneManager.getInstance().getPushManager();
            if (pushManager != null) {
                TunePushListener listener = pushManager.getTunePushListener();
                if (listener != null) {
                    displayNotification = listener.onReceive(message.isSilentPush(), message.getPayload().getUserExtraPayloadParams());
                }
            }
        }
        return displayNotification;
    }

    private void buildAndSendMessage(Bundle extras) {
        String appName = this.getApplicationInfo().loadLabel(this.getPackageManager()).toString();
        try {
            TunePushMessage message = new TunePushMessage(extras, appName);
            boolean displayNotification = notifyListener(message);
            if (!displayNotification || message.isSilentPush()) {
                TuneDebugLog.i("Tune push message aborted");
                return;
            }
            TuneDebugLog.i("Tune pushing notification w/ msg: " + message.getAlertMessage());
            TuneNotificationManagerDelegate notificationManager = new TuneNotificationManagerDelegate(this);
            notificationManager.postPushNotification(message);
        } catch (Exception e) {
            TuneDebugLog.e("Failed to build push message: " + e);
        }
    }

    private void tryEchoPush(Bundle extras) {
        try {
            if (TuneManager.getInstance() != null && TuneManager.getInstance().getConfigurationManager().echoPushes()) {
                Set<String> keys = extras.keySet();
                StringBuilder result = new StringBuilder();
                result.append("Received push message:\n");
                for (String key : keys) {
                    Object value = extras.get(key);
                    result.append(TuneStringUtils.format("  \"%s\" => %s\n", key, value instanceof String ? TuneStringUtils.format("\"%s\"", value) : value));
                }
                TuneDebugLog.alwaysLog(result.toString());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}