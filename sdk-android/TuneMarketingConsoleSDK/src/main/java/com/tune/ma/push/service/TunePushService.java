package com.tune.ma.push.service;

import android.content.Context;
import android.os.Bundle;

import com.google.android.gms.gcm.GcmListenerService;
import com.tune.TuneConstants;
import com.tune.ma.TuneManager;
import com.tune.ma.configuration.TuneConfigurationConstants;
import com.tune.ma.push.TunePushManager;
import com.tune.ma.push.model.TunePushMessage;
import com.tune.ma.push.settings.TunePushListener;
import com.tune.ma.utils.TuneDebugLog;
import com.tune.ma.utils.TuneSharedPrefsDelegate;
import com.tune.ma.utils.TuneStringUtils;

import java.util.Set;

public class TunePushService extends GcmListenerService {

    @Override
    public void onMessageReceived(String from, Bundle data) {
        TuneDebugLog.d("PushService received data");

        handleMessage(getApplicationContext(), data);
    }

    private static void handleMessage(Context context, Bundle extras) {
        TuneSharedPrefsDelegate prefs = new TuneSharedPrefsDelegate(context, TuneConstants.PREFS_TUNE);

        if (prefs.getBooleanFromSharedPreferences(TuneConfigurationConstants.TUNE_TMA_DISABLED) ||
                prefs.getBooleanFromSharedPreferences(TuneConfigurationConstants.TUNE_TMA_PERMANENTLY_DISABLED)) {
            TuneDebugLog.d("Not creating push message because IAM is disabled");
            return;
        }

        if (extras == null || extras.isEmpty()) {
            TuneDebugLog.w("The received message did not have any data, so there is nothing to process.");
            return;
        }

        try {
            tryEchoPush(extras);
            buildAndSendMessage(context, extras);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    protected static boolean notifyListener(TunePushMessage message) {
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

    private static void buildAndSendMessage(Context context, Bundle extras) {
        String appName = context.getApplicationInfo().loadLabel(context.getPackageManager()).toString();
        try {
            TunePushMessage message = new TunePushMessage(extras, appName);
            boolean displayNotification = notifyListener(message);
            if (!displayNotification || message.isSilentPush()) {
                TuneDebugLog.i("Tune push message aborted");
                return;
            }
            TuneDebugLog.i("Tune pushing notification w/ msg: " + message.getAlertMessage());
            TuneNotificationManagerDelegate notificationManager = new TuneNotificationManagerDelegate(context);
            notificationManager.postPushNotification(message);
        } catch (Exception e) {
            TuneDebugLog.e("Failed to build push message: " + e);
        }
    }

    private static void tryEchoPush(Bundle extras) {
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