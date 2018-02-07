package com.tune.ma.push;

import android.provider.Settings;

import com.tune.ma.push.settings.TuneNotificationBuilder;

import junit.framework.TestCase;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by johng on 9/22/16.
 */

public class TuneNotificationBuilderTests extends TestCase {
    private TuneNotificationBuilder builder;

    @Override
    protected void setUp() {
        builder = new TuneNotificationBuilder(1, "test_channel_01");
    }

    @Override
    protected void tearDown() {
        builder = null;
    }

    public void testNoSoundOverridesSound() {
        builder.setSound(Settings.System.DEFAULT_NOTIFICATION_URI);

        assertTrue(builder.isSoundSet());
        assertFalse(builder.isNoSoundSet());

        builder.setNoSound();

        assertFalse(builder.isSoundSet());
        assertTrue(builder.isNoSoundSet());
    }

    public void testSoundOverridesNoSound() {
        builder.setNoSound();

        assertTrue(builder.isNoSoundSet());
        assertFalse(builder.isSoundSet());

        builder.setSound(Settings.System.DEFAULT_NOTIFICATION_URI);

        assertFalse(builder.isNoSoundSet());
        assertTrue(builder.isSoundSet());
    }

    public void testNoVibrateOverridesVibrate() {
        builder.setVibrate(new long[]{0, 1000, 1000});

        assertTrue(builder.isVibrateSet());
        assertFalse(builder.isNoVibrateSet());

        builder.setNoVibrate();

        assertFalse(builder.isVibrateSet());
        assertTrue(builder.isNoVibrateSet());
    }

    public void testVibrateOverridesNoVibrate() {
        builder.setNoVibrate();

        assertTrue(builder.isNoVibrateSet());
        assertFalse(builder.isVibrateSet());

        builder.setVibrate(new long[]{0, 1000, 1000});

        assertFalse(builder.isNoVibrateSet());
        assertTrue(builder.isVibrateSet());
    }

    public void testChannelIdGetsInitialized() throws JSONException {
        JSONObject notificationBuilderJson = builder.toJson();
        assertTrue(notificationBuilderJson.has("channelId"));
        assertEquals("test_channel_01", notificationBuilderJson.getString("channelId"));
    }

    public void testVibrateInJson() throws JSONException {
        builder.setVibrate(new long[]{0, 1000, 1000});

        assertTrue(builder.isVibrateSet());

        JSONObject notificationBuilderJson = builder.toJson();
        JSONArray vibrateJsonArray = notificationBuilderJson.getJSONArray("vibrate");
        assertNotNull(vibrateJsonArray);

        assertEquals(3, vibrateJsonArray.length());
    }
}
