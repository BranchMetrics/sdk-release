package com.tune.ma.push.service;

import android.os.Bundle;

import com.tune.TuneUnitTest;
import com.tune.ma.TuneManager;
import com.tune.ma.push.model.TunePushMessage;
import com.tune.ma.push.settings.TunePushListener;

import org.json.JSONObject;
import org.junit.Test;


/**
 * Created by kristine on 1/30/17.
 */
public class TunePushServiceTests extends TuneUnitTest {

    private TunePushService tunePushService;
    private Bundle pushMessageExtras;

    @Override
    protected void setUp() throws Exception {
        super.setUp();

        tunePushService = new TunePushService();
        pushMessageExtras = new Bundle();
        pushMessageExtras.putString("alert", "");
        pushMessageExtras.putString("app_id", "fakeAppId");
        pushMessageExtras.putString("ARTPID", "fakeARTPID");
        pushMessageExtras.putString("CAMPAIGN_ID", "fakeCampaignId");
        pushMessageExtras.putString("LENGTH_TO_REPORT", "1");
        pushMessageExtras.putString("payload", "{}");
    }

    @Test
    public void testNotifyListenerWithValidListenerSilent() throws Exception {
        TestPushListener testPushListener = new TestPushListener();
        tune.setPushListener(testPushListener);
        pushMessageExtras.putString("silent_push", "true");

        TunePushMessage message = new TunePushMessage(pushMessageExtras, "appName");
        assertFalse(tunePushService.notifyListener(message));
    }

    @Test
    public void testNotifyListenerWithListenerNotSilent() throws Exception {
        TestPushListener testPushListener = new TestPushListener();
        tune.setPushListener(testPushListener);
        pushMessageExtras.putString("silent_push", "false");
        TunePushMessage message = new TunePushMessage(pushMessageExtras, "appName");
        assertTrue(tunePushService.notifyListener(message));
    }

    @Test
    public void testNotifyListenerWithoutListener() throws Exception {
        TunePushMessage message = new TunePushMessage(pushMessageExtras, "appName");
        assertNotNull(TuneManager.getInstance());
        assertNotNull(TuneManager.getInstance().getPushManager());
        assertNull(TuneManager.getInstance().getPushManager().getTunePushListener());
        assertTrue(tunePushService.notifyListener(message));
    }

    @Test
    public void testNotifyListenerWithoutTuneManager() throws Exception {
        TunePushMessage message = new TunePushMessage(pushMessageExtras, "appName");
        TuneManager.destroy();
        assertNull(TuneManager.getInstance());
        assertTrue(tunePushService.notifyListener(message));
    }


    private class TestPushListener implements TunePushListener {

        @Override
        public boolean onReceive(boolean isSilentPush, JSONObject extraPushPayload) {
            return !isSilentPush;
        }
    }
}
