package com.tune.ma.push;

import android.support.test.runner.AndroidJUnit4;

import com.tune.ma.push.model.TunePushPayload;

import junit.framework.TestCase;

import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;

/**
 * Created by charlesgilliam on 2/9/16.
 */
@RunWith(AndroidJUnit4.class)
public class TunePushPayloadTests extends TestCase {
    private TunePushPayload buildPowerHookPushPayload() throws Exception {
        String payloadString = "{\"ANA\":{\"DA\":\"deepActionName\",\"DAD\":{\"blockKey1\":\"blockValue1\", \"blockKey2\":\"blockValue2\"}}}";
        return new TunePushPayload(payloadString);
    }

    private TunePushPayload buildDeepLinkPushPayload() throws Exception {
        String payloadString = "{\"ANA\":{\"URL\":\"artisandemo://map\"}}";
        return new TunePushPayload(payloadString);

    }

    private TunePushPayload buildPowerHookPushPayloadWithNoParams() throws Exception {
        String payloadString = "{\"ANA\":{\"DA\":\"deepActionName\"}}";
        return new TunePushPayload(payloadString);
    }

    @Test
    public void testDeserializePowerHookPushPayload() throws Exception {
        TunePushPayload payload = buildPowerHookPushPayload();
        assertNotNull(payload.getOnOpenAction());
        assertEquals("deepActionName", payload.getOnOpenAction().getDeepActionId());
        assertEquals("blockValue1", payload.getOnOpenAction().getDeepActionParameters().get("blockKey1"));
    }

    @Test
    public void testDeserializeDeepLinkPayload() throws Exception {
        TunePushPayload payload = buildDeepLinkPushPayload();
        assertNotNull(payload.getOnOpenAction());
        assertEquals("artisandemo://map", payload.getOnOpenAction().getDeepLinkURL());
    }

    @Test
    public void testIsOpenActionDeepLinkIsTrueWithDeepLinkPayload() throws Exception {
        TunePushPayload payload = buildDeepLinkPushPayload();
        assertFalse(payload.isOpenActionDeepAction());
        assertTrue(payload.isOpenActionDeepLink());
    }

    @Test
    public void testIsOpenActionExecutePowerhookIsTrueWithPowerHookPayload() throws Exception {
        TunePushPayload payload = buildPowerHookPushPayload();
        assertFalse(payload.isOpenActionDeepLink());
        assertTrue(payload.isOpenActionDeepAction());
    }

    @Test
    public void testToStringForPowerHook() throws Exception {
        TunePushPayload payload = buildPowerHookPushPayload();

        JSONObject jsonObject = new JSONObject(payload.toString());
        assertTrue(jsonObject.has("ANA"));
        assertTrue(jsonObject.getJSONObject("ANA").has("DAD"));
        assertEquals(jsonObject.getJSONObject("ANA").getJSONObject("DAD").getString("blockKey1"), "blockValue1");
        assertEquals(jsonObject.getJSONObject("ANA").getJSONObject("DAD").getString("blockKey2"), "blockValue2");
        assertTrue(jsonObject.getJSONObject("ANA").has("DA"));
        assertEquals(jsonObject.getJSONObject("ANA").getString("DA"), "deepActionName");
    }

    @Test
    public void testToStringForPowerHookWithNoParams() throws Exception {
        String payloadString = "{\"ANA\":{\"DA\":\"deepActionName\"}}";
        TunePushPayload payload = buildPowerHookPushPayloadWithNoParams();
        assertEquals(payloadString, payload.toString());
    }

    @Test
    public void testToStringForDeepLink() throws Exception {
        String payloadString = "{\"ANA\":{\"URL\":\"artisandemo:\\/\\/map\"}}";
        TunePushPayload payload = buildDeepLinkPushPayload();
        assertEquals(payloadString, payload.toString());
    }

    // Auto Cancel tests
    @Test
    public void testAutoCancelOn() throws Exception {
        String payloadString = "{\"ANA\":{\"D\":\"1\", \"DA\":\"deepActionName\"}}";
        TunePushPayload payload = new TunePushPayload(payloadString);

        assertTrue(payload.getOnOpenAction().isAutoCancelNotification());
    }

    @Test
    public void testAutoCancelOff() throws Exception {
        String payloadString = "{\"ANA\":{\"D\":\"0\", \"URL\":\"artisandemo://map\"}}";
        TunePushPayload payload = new TunePushPayload(payloadString);

        assertFalse(payload.getOnOpenAction().isAutoCancelNotification());
    }

    @Test
    public void testAutoCancelOffInt() throws Exception {
        String payloadString = "{\"ANA\":{\"D\":0, \"URL\":\"artisandemo://map\"}}";
        TunePushPayload payload = new TunePushPayload(payloadString);

        assertFalse(payload.getOnOpenAction().isAutoCancelNotification());
    }

    @Test
    public void testAutoCancelOnInt() throws Exception {
        String payloadString = "{\"ANA\":{\"D\":1, \"DA\":\"deepActionName\"}}";
        TunePushPayload payload = new TunePushPayload(payloadString);

        assertTrue(payload.getOnOpenAction().isAutoCancelNotification());
    }

    @Test
    public void testAutoCancelMissing() throws Exception {
        String payloadString = "{\"ANA\":{\"DA\":\"deepActionName\"}}";
        TunePushPayload payload = new TunePushPayload(payloadString);
        assertTrue(payload.getOnOpenAction().isAutoCancelNotification());
    }

    @Test
    public void testHasUserData() throws Exception {
        String payloadString = "{\"ANA\":{\"URL\":\"myurl\"},\"user1\":\"value1\",\"user2\":\"value2\"}";
        TunePushPayload payload = new TunePushPayload(payloadString);

        assertTrue(payload.getUserExtraPayloadParams().length() == 2);
        assertEquals(payload.getUserExtraPayloadParams().getString("user1"), "value1");
        assertEquals(payload.getUserExtraPayloadParams().getString("user2"), "value2");

        JSONObject jsonObject = new JSONObject(payload.toString());
        assertTrue(jsonObject.length() == 3);
        assertEquals(jsonObject.getJSONObject("ANA").getString("URL"), "myurl");
        assertEquals(jsonObject.getString("user1"), "value1");
        assertEquals(jsonObject.getString("user2"), "value2");
    }

    @Test
    public void testNoUserData() throws Exception {
        String payloadString = "{\"ANA\":{\"URL\":\"myurl\"}}";
        TunePushPayload payload = new TunePushPayload(payloadString);

        assertTrue(payload.getUserExtraPayloadParams().length() == 0);
    }

    @Test
    public void testNoOpenAction() throws Exception {
        String payloadString = "{\"user1\":\"value1\",\"user2\":\"value2\"}";
        TunePushPayload payload = new TunePushPayload(payloadString);

        assertTrue(payload.getUserExtraPayloadParams().length() == 2);
        assertEquals(payload.getUserExtraPayloadParams().getString("user1"), "value1");
        assertEquals(payload.getUserExtraPayloadParams().getString("user2"), "value2");

        JSONObject jsonObject = new JSONObject(payload.toString());
        assertTrue(jsonObject.length() == 2);
        assertEquals(jsonObject.getString("user1"), "value1");
        assertEquals(jsonObject.getString("user2"), "value2");
    }
}
