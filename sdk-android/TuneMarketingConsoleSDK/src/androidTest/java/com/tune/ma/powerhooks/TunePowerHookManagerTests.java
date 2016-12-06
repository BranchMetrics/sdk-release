package com.tune.ma.powerhooks;

import com.tune.TuneUnitTest;
import com.tune.ma.playlist.model.TunePlaylist;
import com.tune.ma.powerhooks.model.TunePowerHookValue;
import com.tune.mocks.MockExecutorService;
import com.tune.testutils.TestCallback;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Map;

/**
 * Created by gowie on 1/26/16.
 */
public class TunePowerHookManagerTests extends TuneUnitTest {

    private TunePowerHookManager phookManager;

    @Override
    protected void setUp() throws Exception {
        super.setUp();
        phookManager = new TunePowerHookManager();
        phookManager.setExecutorService(new MockExecutorService());
    }
    
    @Override
    protected void tearDown() throws Exception {
        super.tearDown();
        phookManager.clearPowerHooks();
    }

    public void testRegisteringAndRetrievingValues() {
        tune.registerPowerHook("name", "friendly", "default");
        assertEquals("default", tune.getValueForHookById("name"));
    }

    public void testSettingPowerHookValues() {
        tune.registerPowerHook("name", "friendly", "default");
        tune.setValueForHookById("name", "newValue");
        assertEquals("newValue", tune.getValueForHookById("name"));
    }

    public void testRegisteringWithBadCharacters() {
        tune.registerPowerHook("BADCHARACTERS.$   ", "Bad characters approaching, target acquired", "default");

        assertEquals("default", tune.getValueForHookById("BADCHARACTERS.$   "));
        assertEquals("default", tune.getValueForHookById("BADCHARACTERS__"));
    }

    public void testRegisteringWithNullsRegistersNothing() {
        tune.registerPowerHook(null, "friendly", "default");
        tune.registerPowerHook("hookId", null, "default");
        tune.registerPowerHook("hookId", "friendly", null);
        assertEquals(0, phookManager.getPowerHooks().size());
    }

    public void testRegisteringDuplicatePowerHook() throws JSONException {
        tune.registerPowerHook("name", "friendly", "default");
        assertEquals("default", tune.getValueForHookById("name"));
        
        tune.registerPowerHook("name", "friendly", "default1");
        assertEquals("default", tune.getValueForHookById("name"));
    }


    // Playlist Changes
    ////////////////////

    public void testChangingPowerHookValueFromPlaylist() throws JSONException {
        phookManager.registerPowerHook("name", "friendly", "default", null, null);

        JSONObject phookJson = new JSONObject();
        phookJson.put(TunePowerHookValue.VALUE, "NEWVALUE");
        postPlaylistChangedWithPhookJson("name", phookJson);

        assertEquals(1, phookManager.getPowerHooks().size());
        assertEquals("NEWVALUE", phookManager.getValueForHookById("name"));
    }

    public void testExperimentsComingDownInPlaylist() throws JSONException {
        phookManager.registerPowerHook("name", "friendly", "default", null, null);

        JSONObject phookJson = new JSONObject();
        phookJson.put(TunePowerHookValue.VALUE, "noshow");
        phookJson.put(TunePowerHookValue.EXPERIMENT_VALUE, "value_for_experiment");
        phookJson.put(TunePowerHookValue.START_DATE, "2015-01-25T19:12:45Z");
        phookJson.put(TunePowerHookValue.END_DATE, "2200-01-25T19:12:45Z");
        phookJson.put(TunePowerHookValue.EXPERIMENT_ID, "123");
        phookJson.put(TunePowerHookValue.VARIATION_ID, "234");
        postPlaylistChangedWithPhookJson("name", phookJson);

        Map<String, TunePowerHookValue> phooks = phookManager.getPowerHooks();
        TunePowerHookValue updatedPhook = phooks.get("name");
        assertEquals(1, phooks.size());
        assertEquals("value_for_experiment", phookManager.getValueForHookById("name"));
        assertNotNull(updatedPhook.getExperimentValue());
        assertNotNull(updatedPhook.getVariationId());
        assertNotNull(updatedPhook.getExperimentId());
        assertNotNull(updatedPhook.getStartDate());
        assertNotNull(updatedPhook.getEndDate());
    }

    public void testPlaylistBeingProcessedBeforeRegister() throws JSONException {
        Map<String, TunePowerHookValue> phooks = phookManager.getPowerHooks();
        assertEquals(0, phooks.size());

        JSONObject phookJson = new JSONObject();
        phookJson.put(TunePowerHookValue.VALUE, "nonregistered");
        postPlaylistChangedWithPhookJson("name", phookJson);

        Map<String, TunePowerHookValue> phooksAfter = phookManager.getPowerHooks();
        assertEquals(0, phooks.size());
        assertEquals("nonregistered", phookManager.getValueForHookById("name"));
    }

    // Power Hook Changed Callbacks
    ////////////////////////////////

    public void testPowerHookChangeKicksOffChangedCallbacks() throws JSONException {
        phookManager.registerPowerHook("name", "friendly", "default", null, null);

        TestCallback testCallback = new TestCallback();

        phookManager.onPowerHooksChanged(testCallback);

        JSONObject phookJson = new JSONObject();
        phookJson.put(TunePowerHookValue.VALUE, "nonregistered");
        postPlaylistChangedWithPhookJson("name", phookJson);

        assertEquals(1, testCallback.getCallbackCount());
    }

    public void testPowerHookChangeKicksOffLastChangedCallbacks() throws JSONException {
        phookManager.registerPowerHook("name", "friendly", "default", null, null);

        TestCallback testCallback1 = new TestCallback();
        TestCallback testCallback2 = new TestCallback();

        phookManager.onPowerHooksChanged(testCallback1);
        phookManager.onPowerHooksChanged(testCallback2);

        JSONObject phookJson = new JSONObject();
        phookJson.put(TunePowerHookValue.VALUE, "nonregistered");
        postPlaylistChangedWithPhookJson("name", phookJson);

        assertEquals(0, testCallback1.getCallbackCount());
        assertEquals(1, testCallback2.getCallbackCount());
    }

    public void testNonChangedPlaylistDoesntKickOffCallback() throws JSONException {
        phookManager.registerPowerHook("name", "friendly", "default", null, null);

        TestCallback testCallback = new TestCallback();

        phookManager.onPowerHooksChanged(testCallback);

        JSONObject phookJson = new JSONObject();
        phookJson.put(TunePowerHookValue.VALUE, "default");
        postPlaylistChangedWithPhookJson("name", phookJson);

        assertEquals(0, testCallback.getCallbackCount());
    }

    public void testPowerHookChangeKicksOffChangedCallbacksAfterEachChange() throws JSONException {
        phookManager.registerPowerHook("name", "friendly", "default", null, null);

        TestCallback testCallback = new TestCallback();

        phookManager.onPowerHooksChanged(testCallback);

        JSONObject phookJson1 = new JSONObject();
        phookJson1.put(TunePowerHookValue.VALUE, "nonregistered");
        postPlaylistChangedWithPhookJson("name", phookJson1);

        assertEquals(1, testCallback.getCallbackCount());

        postPlaylistChangedWithPhookJson("name", phookJson1);
        assertEquals(1, testCallback.getCallbackCount());


        JSONObject phookJson2 = new JSONObject();
        phookJson2.put(TunePowerHookValue.VALUE, "anotherChange");
        postPlaylistChangedWithPhookJson("name", phookJson2);

        assertEquals(2, testCallback.getCallbackCount());
    }

    // Test Helpers
    ////////////////

    private void postPlaylistChangedWithPhookJson(String name, JSONObject phookJson) throws JSONException {
        JSONObject phooksJson = new JSONObject();
        phooksJson.put(name, phookJson);

        JSONObject playlistJson = new JSONObject();
        playlistJson.put(TunePlaylist.POWER_HOOKS_KEY, phooksJson);

        TunePlaylist playlist = new TunePlaylist(playlistJson);

        phookManager.updatePowerHooksFromPlaylist(playlist);
    }
}
