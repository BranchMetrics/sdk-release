package com.tune.ma.push.service;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.support.v4.app.NotificationCompat;
import android.text.TextUtils;

import com.tune.TuneDebugLog;
import com.tune.ma.push.TunePushManager;
import com.tune.ma.push.model.TunePushMessage;
import com.tune.ma.push.model.TunePushStyle;
import com.tune.ma.push.settings.TuneNotificationBuilder;
import com.tune.ma.utils.TuneSharedPrefsDelegate;

import org.json.JSONException;

public class TuneNotificationManagerDelegate {
    public static final int DEFAULT_ICON = android.R.drawable.presence_online;
    public static final String DEFAULT_CHANNEL_ID = "TUNE_CHANNEL";
    public static final String DEFAULT_CHANNEL_NAME = "IAM Engagement";

    private NotificationManager notificationManager;
    private Context context;
    private TuneSharedPrefsDelegate sharedPrefs;

    public TuneNotificationManagerDelegate(Context context) {
        this.context = context;
        sharedPrefs = new TuneSharedPrefsDelegate(context, TunePushManager.PREFS_TMA_PUSH);
        notificationManager = (NotificationManager)context.getSystemService(Context.NOTIFICATION_SERVICE);
    }

    public void postPushNotification(TunePushMessage message) {
        String messageJson = message.toJson();
        PendingIntent tapIntent = buildTapIntentForMessage(message, messageJson);

        // Default to the user's app icon, but if they don't have one then use android's presence_online icon.
        // It's important to have this as a backup as the notification will fail silently without an icon.
        int iconId = context.getApplicationInfo().icon;
        if (iconId == 0) {
            iconId = DEFAULT_ICON;
        }

        boolean autoCancel = message.isAutoCancelNotification();

        TuneNotificationBuilder ourBuilder = null;
        if (sharedPrefs.contains(TunePushManager.PROPERTY_NOTIFICATION_BUILDER)) {
            try {
                ourBuilder = TuneNotificationBuilder.fromJson(sharedPrefs.getStringFromSharedPreferences(TunePushManager.PROPERTY_NOTIFICATION_BUILDER));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        NotificationCompat.Builder builder;
        if (ourBuilder != null) {
            builder = ourBuilder.build(context);
        } else {
            builder = new NotificationCompat.Builder(context.getApplicationContext());
            builder.setSmallIcon(iconId);

            // Notification channels are required for Android-O and on
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Create default TUNE channel
                NotificationChannel tuneChannel = new NotificationChannel(DEFAULT_CHANNEL_ID, DEFAULT_CHANNEL_NAME, NotificationManager.IMPORTANCE_DEFAULT);
                notificationManager.createNotificationChannel(tuneChannel);
                builder.setChannelId(tuneChannel.getId());
            }
        }

        builder.setTicker(message.getTicker()); // Message when notif. first shows in tray
        builder.setContentTitle(message.getTitle());
        builder.setContentText(message.getAlertMessage());
        builder.setContentIntent(tapIntent);

        // Use server-passed channel ID if exists
        if (message.getChannelId() != null) {
            builder.setChannelId(message.getChannelId());
        }

        // Check if we should set a specific NotificationStyle
        setNotificationBuilderStyle(builder, message);

        Notification notification = builder.build();

        if (autoCancel) {
            notification.flags |= Notification.FLAG_AUTO_CANCEL;
        }
        notification.flags |= Notification.FLAG_SHOW_LIGHTS;
        notification.defaults |= Notification.DEFAULT_LIGHTS;

        if (ourBuilder != null) {
            // If custom sound wasn't set, and no-sound wasn't explicitly set in TuneNotificationBuilder, use default sound
            if (!ourBuilder.isSoundSet() && !ourBuilder.isNoSoundSet()) {
                notification.defaults |= Notification.DEFAULT_SOUND;
            }
            // If custom vibrate pattern wasn't set, and no-vibration wasn't explicitly set in TuneNotificationBuilder, use default pattern
            if (!ourBuilder.isVibrateSet() && !ourBuilder.isNoVibrateSet()) {
                notification.defaults |= Notification.DEFAULT_VIBRATE;
            }
        } else {
            // If TuneNotificationBuilder isn't used, use default sound and vibrate
            notification.defaults |= Notification.DEFAULT_SOUND;
            notification.defaults |= Notification.DEFAULT_VIBRATE;
        }

        TuneDebugLog.d("Posting push notification now");

        // Post the notification to the tray
        notificationManager.notify(message.getTunePushIdAsInt(), notification);
    }

    private PendingIntent buildTapIntentForMessage(TunePushMessage message, String messageJson) {
        // NOTE: we always open the app
        Intent intent;
        if (message.isOpenActionDeepLink()) {
            intent = new Intent(Intent.ACTION_VIEW, Uri.parse(message.getPayload().getOnOpenAction().getDeepLinkURL()));
        } else {
            String packageName = context.getPackageName();
            intent = context.getPackageManager().getLaunchIntentForPackage(packageName);
            // TODO: We should let it customized from the server whether to resume or start a new activity
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        }

        intent.putExtra(TunePushMessage.TUNE_EXTRA_MESSAGE, messageJson);
        return PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_CANCEL_CURRENT);
    }

    private void setNotificationBuilderStyle(NotificationCompat.Builder builder, TunePushMessage message) {
        String style = message.getStyle();
        if (!TextUtils.isEmpty(style)) {
            switch (style) {
                case TunePushStyle.IMAGE:
                    setPictureStyle(builder, message);
                    break;
                case TunePushStyle.BIG_TEXT:
                    setTextStyle(builder, message);
                    break;
                case TunePushStyle.REGULAR:
                default:
                    break;
            }
        }
    }

    private void setPictureStyle(NotificationCompat.Builder builder, TunePushMessage message) {
        // If we never downloaded image, exit and don't set style to BigPictureStyle
        if (message.getImage() == null) {
            return;
        }

        NotificationCompat.BigPictureStyle style = new NotificationCompat.BigPictureStyle();
        // Initialize BigPictureStyle text fields to same as regular notification
        style.setBigContentTitle(message.getTitle());
        style.setSummaryText(message.getAlertMessage());

        // Set image
        style.bigPicture(message.getImage());
        // Look for optional BigPictureStyle field overrides
        if (!TextUtils.isEmpty(message.getExpandedTitle())) {
            style.setBigContentTitle(message.getExpandedTitle());
        }
        if (!TextUtils.isEmpty(message.getSummary())) {
            style.setSummaryText(message.getSummary());
        }
        builder.setStyle(style);
    }

    private void setTextStyle(NotificationCompat.Builder builder, TunePushMessage message) {
        NotificationCompat.BigTextStyle style = new NotificationCompat.BigTextStyle();
        // Initialize BigPictureStyle text fields to same as regular notification
        style.setBigContentTitle(message.getTitle());
        style.setSummaryText(message.getAlertMessage());

        // Set expanded text
        style.bigText(message.getExpandedText());
        // Look for optional BigTextStyle field overrides
        if (!TextUtils.isEmpty(message.getExpandedTitle())) {
            style.setBigContentTitle(message.getExpandedTitle());
        }
        if (!TextUtils.isEmpty(message.getSummary())) {
            style.setSummaryText(message.getSummary());
        }
        builder.setStyle(style);
    }
}