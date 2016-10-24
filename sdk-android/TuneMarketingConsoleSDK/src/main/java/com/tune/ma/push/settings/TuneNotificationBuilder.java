package com.tune.ma.push.settings;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.support.v4.app.NotificationCompat;
import android.support.v4.app.NotificationCompat.Builder;

import com.tune.ma.utils.TuneDebugLog;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Use this class to provide Tune with notification settings to use when building a notification for an Tune Push Message.
 *
 * Behind the scenes we depend on NotificationCompat, which will handle backwards compatibility for older versions of the Android OS.
 *
 */
public class TuneNotificationBuilder {
    private int smallIconId;
    private int largeIconId;
    private String sortKey;
    private String groupKey;
    private int colorARGB;
    private int visibility;
    private Uri sound;
    private long[] vibratePattern;
    private boolean onlyAlertOnce;
    private boolean isSmallIconSet;
    private boolean isLargeIconSet;
    private boolean isSortKeySet;
    private boolean isGroupKeySet;
    private boolean isColorSet;
    private boolean isVisibilitySet;
    private boolean isSoundSet;
    private boolean isVibrateSet;
    private boolean isOnlyAlertOnceSet;
    private boolean isNoSoundSet;
    private boolean isNoVibrateSet;

    /**
     * Creates a new TuneNotificationBuilder to pass into {@link com.tune.Tune#setPushNotificationBuilder(com.tune.ma.push.settings.TuneNotificationBuilder)}. <br>
     * <br>
     * Important: If you do not provide a small icon for your notifications via the builder we will default to using your app icon. This may look odd if your app is targeting API 21+ because the OS will take only the alpha of the icon and display that on a gray background. If your app is set to target API 21+ we strongly recommend that you take advantage of the {@link TuneNotificationBuilder} API.
     * <br/>
     * If you support versions before and after API 21, you might want to use different icons depending on the version. In such a case you can do:
     * {@code
     * int smallIcon;
     * if (Build.VERSION.SDK_INT >= 21) {
     *      smallIcon = R.drawable.your_icon;
     * } else {
     *     smallIcon = R.drawable.your_other_icon;
     * }
     * TuneNotificationBuilder builder = new TuneNotificationBuilder(smallIcon);
     * }
     * @param smallIconId Android resource Id for the small notification icon.
     */
    public TuneNotificationBuilder(int smallIconId) {
        this.isSmallIconSet = true;
        this.smallIconId = smallIconId;
    }


    /**
     * Set the large icon that is shown in Tune Push Notifications.
     *
     * NOTE: This will only be visible when the user expands the tray and will replace the small icon. However, on APIs before 21 the small icon will still be shown on the far right of the notification
     * and on later APIs the small icon will be super imposed at the bottom right of the large icon.
     * <br/>
     *
     * @param largeIconId Android resource Id for the large notification icon.
     */
    public TuneNotificationBuilder setLargeIcon(int largeIconId) {
        isLargeIconSet = true;
        this.largeIconId = largeIconId;
        return this;
    }

    /**
     * Set a sort key that orders this notification among other notifications from the same package. <br>
     * <br>
     * Note: Grouping is only supported on devices running Android API 20+.
     *
     * @param sortKey sort key for Notifications from Tune Push.
     */
    public TuneNotificationBuilder setSortKey(String sortKey) {
        isSortKeySet = true;
        this.sortKey = sortKey;
        return this;
    }

    /**
     * Set this notification to be part of a group of notifications sharing the same key. <br>
     * <br>
     * Note: Grouping is only supported on devices running Android API 20+.
     *
     * @param groupKey group key if you would like to group Tune Push Notifications together.
     */
    public TuneNotificationBuilder setGroup(String groupKey) {
        isGroupKeySet = true;
        this.groupKey = groupKey;
        return this;
    }

    /**
     * Set the accent color for Tune Push Notifications. <br>
     * <br>
     * Note: Color will only be displayed on devices running Lollipop (API 21+).
     * <br>
     * Accent color (an ARGB integer like the constants in Color) to be applied by the standard Style templates when presenting this notification. The current template design constructs a colorful header image by overlaying the icon image (stenciled in white) atop a field of this color. Alpha components are ignored. <br>
     *
     * @param argb set the accent color
     */
    public TuneNotificationBuilder setColor(int argb) {
        isColorSet = true;
        this.colorARGB = argb;
        return this;
    }

    /**
     * Set the visibility level for Tune Push Notifications. <br>
     * <br>
     * Sphere of visibility of this notification, which affects how and when the SystemUI reveals the notification's presence and contents in untrusted situations (namely, on the secure lockscreen). <br>
     * <br>
     * Note: Visibility is only supported on devices running Lollipop (API 21+).
     *
     * @param visibility visibility level, One of NotificationCompat.VISIBILITY_PRIVATE (the default), NotificationCompat.VISIBILITY_SECRET, or NotificationCompat.VISIBILITY_PUBLIC.
     */
    public TuneNotificationBuilder setVisibility(int visibility) {
        isVisibilitySet = true;
        this.visibility = visibility;
        return this;
    }

    /**
     * Sets the sound to use for Tune Push Notifications. <br>
     * <br>
     * @param sound Uri to a sound to play for the notification.
     * @return TuneNotificationBuilder with sound set.
     */
    public TuneNotificationBuilder setSound(Uri sound) {
        isSoundSet = true;
        isNoSoundSet = false;
        this.sound = sound;
        return this;
    }

    /**
     * Sets the vibration pattern for Tune Push Notifications. <br>
     * <br>
     * Pass in an array of ints that are the durations for which to turn on or off the vibrator in milliseconds. The first value indicates the number of milliseconds to wait before turning the vibrator on.
     * The next value indicates the number of milliseconds for which to keep the vibrator on before turning it off.
     * Subsequent values alternate between durations in milliseconds to turn the vibrator off or to turn the vibrator on.
     * <br>
     * Note: This method requires the caller to hold the permission VIBRATE.
     *
     * @param pattern vibration pattern to use when Tune push notification is received.
     * @return TuneNotificationBuilder with vibration pattern set.
     */
    public TuneNotificationBuilder setVibrate(long[] pattern) {
        isVibrateSet = true;
        isNoVibrateSet = false;
        this.vibratePattern = pattern;
        return this;
    }

    /**
     * Sets the only alert once setting for Tune Push Notifications. <br>
     * <br>
     * If set to true, then the sound and vibration will not play again while one notification is already showing and another is received.
     * <br>
     *
     * @param onlyAlertOnce Whether sound and vibrate should be played only if the notification is not already showing.
     * @return TuneNotificationBuilder with alert only once set.
     */
    public TuneNotificationBuilder setOnlyAlertOnce(boolean onlyAlertOnce) {
        isOnlyAlertOnceSet = true;
        this.onlyAlertOnce = onlyAlertOnce;
        return this;
    }

    /**
     * Sets that no sound should be played for Tune Push Notifications. <br>
     * <br>
     * If set, notifications will not be accompanied with any sound, not even default system sounds.
     * <br>
     * @return TuneNotificationBuilder with no sound set.
     */
    public TuneNotificationBuilder setNoSound() {
        isNoSoundSet = true;
        isSoundSet = false;
        this.sound = null;
        return this;
    }

    /**
     * Sets that no vibrate pattern should be played for Tune Push Notifications. <br>
     * br>
     * If set, notifications will not be accompanied with any vibration, not even default system vibration.
     * <br>
     * @return TuneNotificationBuilder with no vibrate pattern set.
     */
    public TuneNotificationBuilder setNoVibrate() {
        isNoVibrateSet = true;
        isVibrateSet = false;
        this.vibratePattern = null;
        return this;
    }

    /**
     * Builds a NotificationCompat.Builder from the provided push notification settings.
     */
    public NotificationCompat.Builder build(Context context) {
        Builder builder = new NotificationCompat.Builder(context.getApplicationContext());

        if (isSmallIconSet) {
            builder.setSmallIcon(smallIconId);
        }

        if (isLargeIconSet) {
            Bitmap bm = BitmapFactory.decodeResource(context.getResources(), largeIconId);
            builder.setLargeIcon(bm);
        }

        if (isSortKeySet) {
            builder.setSortKey(sortKey);
        }

        if (isGroupKeySet) {
            builder.setGroup(groupKey);
        }

        if (isColorSet) {
            try {
                builder.setColor(colorARGB);
            } catch (Exception e) {
                TuneDebugLog.e("Cannot set color on notification builder. Make sure you have the latest revision of the Android Support Library v4 (22.+)", e);
            }
        }

        if (isVisibilitySet) {
            try {
                builder.setVisibility(visibility);
            } catch (Exception e) {
                TuneDebugLog.e("Cannot set visibility on notification builder. Make sure you have the latest revision of the Android Support Library v4 (22.+)", e);
            }
        }

        if (isSoundSet) {
            builder.setSound(sound);
        }

        if (isVibrateSet) {
            builder.setVibrate(vibratePattern);
        }

        if (isOnlyAlertOnceSet) {
            builder.setOnlyAlertOnce(onlyAlertOnce);
        }

        return builder;
    }

    /**
     * Returns whether the TuneNotificationBuilder has any customized fields.
     * @return whether TuneNotificationBuilder has any customized fields
     */
    public boolean hasCustomization() {
        return isColorSet || isGroupKeySet || isLargeIconSet || isSmallIconSet || isSortKeySet || isVisibilitySet || isSoundSet || isVibrateSet || isOnlyAlertOnceSet || isNoSoundSet || isNoVibrateSet;
    }

    /**
     * Returns whether the TuneNotificationBuilder has a custom sound set
     * @return whether TuneNotificationBuilder has a custom sound set
     */
    public boolean isSoundSet() {
        return isSoundSet;
    }

    /**
     * Returns whether the TuneNotificationBuilder has a custom vibrate pattern set
     * @return whether TuneNotificationBuilder has a custom vibrate pattern set
     */
    public boolean isVibrateSet() {
        return isVibrateSet;
    }

    /**
     * Returns whether the TuneNotificationBuilder should explicitly not play any sounds
     * @return whether TuneNotificationBuilder has "no-sound" set
     */
    public boolean isNoSoundSet() {
        return isNoSoundSet;
    }

    /**
     * Returns whether the TuneNotificationBuilder should explicitly not play any vibration
     * @return whether TuneNotificationBuilder has "no-vibrate" set
     */
    public boolean isNoVibrateSet() {
        return isNoVibrateSet;
    }

    private static final String JSON_SMALL_ICON_ID = "smallIconId";
    private static final String JSON_LARGE_ICON_ID = "largeIconId";
    private static final String JSON_AUTO_CANCEL = "autoCancel";
    private static final String JSON_SORT_KEY = "sortKey";
    private static final String JSON_GROUP_KEY = "groupKey";
    private static final String JSON_COLOR_ARGB = "colorARGB";
    private static final String JSON_VISIBILITY = "visibility";
    private static final String JSON_SOUND = "sound";
    private static final String JSON_VIBRATE = "vibrate";
    private static final String JSON_NO_SOUND = "noSound";
    private static final String JSON_NO_VIBRATE = "noVibrate";
    private static final String JSON_ONLY_ALERT_ONCE = "onlyAlertOnce";

    // TODO: These two methods should not be exposed to the end user.
    public JSONObject toJson() throws JSONException {
        JSONObject result = new JSONObject();

        if (isSmallIconSet) {
            result.put(JSON_SMALL_ICON_ID, smallIconId);
        }

        if (isLargeIconSet) {
            result.put(JSON_LARGE_ICON_ID, largeIconId);
        }

        if (isSortKeySet) {
            result.put(JSON_SORT_KEY, sortKey);
        }

        if (isGroupKeySet) {
            result.put(JSON_GROUP_KEY, groupKey);
        }

        if (isColorSet) {
            result.put(JSON_COLOR_ARGB, colorARGB);
        }

        if (isVisibilitySet) {
            result.put(JSON_VISIBILITY, visibility);
        }

        if (isSoundSet) {
            result.put(JSON_SOUND, sound.toString());
        }

        if (isVibrateSet) {
            result.put(JSON_VIBRATE, new JSONArray(vibratePattern));
        }

        if (isOnlyAlertOnceSet) {
            result.put(JSON_ONLY_ALERT_ONCE, onlyAlertOnce);
        }

        if (isNoSoundSet) {
            result.put(JSON_NO_SOUND, isNoSoundSet);
        }

        if (isNoVibrateSet) {
            result.put(JSON_NO_VIBRATE, isNoVibrateSet);
        }

        return result;
    }

    public static TuneNotificationBuilder fromJson(String json) throws JSONException {
        JSONObject j = new JSONObject(json);
        TuneNotificationBuilder result = new TuneNotificationBuilder(j.getInt(JSON_SMALL_ICON_ID));

        // NOTE: When we serialize if the appropriate 'isFooBarSet' variable is false we won't serialize
        //        This means that if the key doesn't appear in the json when we deserialize, it wasn't set
        if (j.has(JSON_LARGE_ICON_ID)) {
            result.setLargeIcon(j.getInt(JSON_LARGE_ICON_ID));
        }

        if (j.has(JSON_SORT_KEY)) {
            result.setSortKey(j.getString(JSON_SORT_KEY));
        }

        if (j.has(JSON_GROUP_KEY)) {
            result.setGroup(j.getString(JSON_GROUP_KEY));
        }

        if (j.has(JSON_COLOR_ARGB)) {
            result.setColor(j.getInt(JSON_COLOR_ARGB));
        }

        if (j.has(JSON_VISIBILITY)) {
            result.setVisibility(j.getInt(JSON_VISIBILITY));
        }

        if (j.has(JSON_SOUND)) {
            result.setSound(Uri.parse(j.getString(JSON_SOUND)));
        }

        if (j.has(JSON_VIBRATE)) {
            // Convert JSONArray to long[]
            JSONArray patternJson = j.getJSONArray(JSON_VIBRATE);
            long[] pattern = new long[patternJson.length()];
            for (int i = 0; i < patternJson.length(); i++) {
                pattern[i] = patternJson.getLong(i);
            }
            result.setVibrate(pattern);
        }

        if (j.has(JSON_ONLY_ALERT_ONCE)) {
            result.setOnlyAlertOnce(j.getBoolean(JSON_ONLY_ALERT_ONCE));
        }

        if (j.has(JSON_NO_SOUND)) {
            result.setNoSound();
        }

        if (j.has(JSON_NO_VIBRATE)) {
            result.setNoVibrate();
        }

        return result;
    }
}
