package com.tune.ma.configuration;

import com.tune.TuneTestConstants;
import com.tune.TuneUnitTest;
import com.tune.ma.TuneManager;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.file.FileManager;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by kristine on 1/27/16.
 */
public class TuneConfigurationManagerTests extends TuneUnitTest {

    TuneConfigurationManager config;
    FileManager fileManager;

    @Override
    public void setUp() throws Exception {
        super.setUp();
        config = TuneManager.getInstance().getConfigurationManager();
        fileManager = TuneManager.getInstance().getFileManager();
    }

    @Override
    public void tearDown() throws Exception {
        super.tearDown();
        TuneEventBus.unregister(this);
    }

    public void testDefaultConfigurationSet() {
        assertEquals(config.getAnalyticsDispatchPeriod(), TuneTestConstants.ANALYTICS_DISPATCH_PERIOD);
        assertFalse(config.echoAnalytics());
        assertFalse(config.echoConfigurations());
        assertFalse(config.echoPlaylists());
        assertEquals(config.getAnalyticsMessageStorageLimit(), 250);
        assertEquals(config.getPlaylistRequestPeriod(), TuneTestConstants.PLAYLIST_REQUEST_PERIOD);
        assertNull(config.getPluginName());
        assertEquals("https://qa.ma.tune.com", config.getApiHostPort());
    }

    public void testIgnoresValuesForUnknownKeys() {
        JSONObject fakeRemoteJson = new JSONObject();
        try {
            fakeRemoteJson.put(TuneConfigurationConstants.TUNE_ANALYTICS_DISPATCH_PERIOD, 120);
            fakeRemoteJson.put(TuneConfigurationConstants.TUNE_KEY_ECHO_CONFIGURATIONS, true);
            fakeRemoteJson.put("random_key", "random_value");
            fakeRemoteJson.put("this_should_not_matter", 44);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        config.updateConfigurationFromRemoteJson(fakeRemoteJson);

        assertEquals(120, config.getAnalyticsDispatchPeriod());
        assertTrue(config.echoConfigurations());
    }

    public void testRemoteConfigUpdateDoesntAffectValuesThatShouldOnlyBeSetLocally() {
        JSONObject fakeRemoteJson = new JSONObject();
        try {
            //Local only values
            fakeRemoteJson.put("api_host_port", "testApiHostPort");
            fakeRemoteJson.put("analytics_host_port", "testAnalyticsHostPort");
            fakeRemoteJson.put("static_content_host_port", "testStaticContentHostPort");
            fakeRemoteJson.put("connected_mode_host_port", "testConnectedModeHostPort");
            fakeRemoteJson.put("use_playlist_player", true);
            fakeRemoteJson.put("use_configuration_player", false);

            fakeRemoteJson.put(TuneConfigurationConstants.TUNE_ANALYTICS_DISPATCH_PERIOD, 120);
            fakeRemoteJson.put(TuneConfigurationConstants.TUNE_KEY_ECHO_CONFIGURATIONS, true);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        config.updateConfigurationFromRemoteJson(fakeRemoteJson);

        assertEquals(120, config.getAnalyticsDispatchPeriod());
        assertTrue(config.echoConfigurations());

        assertNotSame("testApiHostPort", config.getApiHostPort());
        assertNotSame("testAnalyticsHostPort", config.getAnalyticsHostPort());
        assertNotSame("testStaticContentHostPort", config.getStaticContentHostPort());
        assertNotSame("testConnectedModeHostPort", config.getConnectedModeHostPort());
        assertFalse(config.usePlaylistPlayer());
        assertTrue(config.useConfigurationPlayer());
    }

    public void testSetupConfigurationWithSavedJson() {
        TuneConfiguration testConfig = new TuneConfiguration();
        testConfig.setShouldAutoCollectDeviceLocation(true);
        testConfig.setAnalyticsMessageStorageLimit(50);
        testConfig.setEchoConfigurations(false);

        JSONObject savedJson = new JSONObject();
        try {
            savedJson.put(TuneConfigurationConstants.TUNE_KEY_AUTOCOLLECT_LOCATION, false);
            savedJson.put(TuneConfigurationConstants.TUNE_ANALYTICS_MESSAGE_LIMIT, 500);
            savedJson.put(TuneConfigurationConstants.TUNE_KEY_ECHO_CONFIGURATIONS, true);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        fileManager.writeConfiguration(savedJson);
        config.setupConfiguration(testConfig);

        assertFalse(config.shouldAutoCollectDeviceLocation());
        assertEquals(config.getAnalyticsMessageStorageLimit(), 500);
        assertTrue(config.echoConfigurations());

        fileManager.deleteConfiguration();
    }

    public void testTMANotPermanentlyDisabledMeansTMAIsOn() {
        assertFalse(config.isTMAPermanentlyDisabled());
        assertFalse(config.isTMADisabled());

        JSONObject remoteJson = new JSONObject();
        try {
            remoteJson.put(TuneConfigurationConstants.TUNE_TMA_PERMANENTLY_DISABLED, false);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        config.updateConfigurationFromRemoteJson(remoteJson);
        assertFalse(config.isTMAPermanentlyDisabled());
        assertFalse(config.isTMADisabled());
    }

    public void testTMAPermanentlyDisabledMeansTMAIsOff() {
        assertFalse(config.isTMAPermanentlyDisabled());
        assertFalse(config.isTMADisabled());

        JSONObject remoteJson = new JSONObject();
        try {
            remoteJson.put(TuneConfigurationConstants.TUNE_TMA_PERMANENTLY_DISABLED, true);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        config.updateConfigurationFromRemoteJson(remoteJson);
        assertTrue(config.isTMAPermanentlyDisabled());
        assertTrue(config.isTMADisabled());

    }

    public void testTMAPermanentlyDisabledIsPermanent() {
        assertFalse(config.isTMAPermanentlyDisabled());
        assertFalse(config.isTMADisabled());

        JSONObject remoteJson = new JSONObject();
        try {
            remoteJson.put(TuneConfigurationConstants.TUNE_TMA_PERMANENTLY_DISABLED, true);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        config.updateConfigurationFromRemoteJson(remoteJson);
        assertTrue(config.isTMAPermanentlyDisabled());
        assertTrue(config.isTMADisabled());

        try {
            remoteJson.put(TuneConfigurationConstants.TUNE_TMA_PERMANENTLY_DISABLED, false);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        config.updateConfigurationFromRemoteJson(remoteJson);
        assertTrue(config.isTMAPermanentlyDisabled());
        assertTrue(config.isTMADisabled());
    }

    public void testTMADisabledMeansTMAisDisabled() {
        assertFalse(config.isTMAPermanentlyDisabled());
        assertFalse(config.isTMADisabled());

        JSONObject remoteJson = new JSONObject();
        try {
            remoteJson.put(TuneConfigurationConstants.TUNE_TMA_DISABLED, true);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        config.updateConfigurationFromRemoteJson(remoteJson);
        assertFalse(config.isTMAPermanentlyDisabled());
        assertTrue(config.isTMADisabled());

        try {
            remoteJson.put(TuneConfigurationConstants.TUNE_TMA_DISABLED, false);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        config.updateConfigurationFromRemoteJson(remoteJson);
        assertFalse(config.isTMAPermanentlyDisabled());
        assertFalse(config.isTMADisabled());
    }

    public void testConfigurationPlayerUpdatesValuesSequentially() {
        assertTrue(config.useConfigurationPlayer());
        assertEquals(2, config.getConfigurationPlayerFilenames().size());
        assertFalse(config.echoConfigurations());
        assertFalse(config.echoPlaylists());
        assertFalse(config.echoAnalytics());
        assertEquals(250, config.getAnalyticsMessageStorageLimit());

        // should update from configuration1.json
        config.updateConfigurationFromServer();

        assertTrue(config.echoConfigurations());
        assertTrue(config.echoPlaylists());
        assertFalse(config.echoAnalytics());
        assertEquals(125, config.getAnalyticsMessageStorageLimit());

        // should update from configuration 2.json
        config.updateConfigurationFromServer();

        assertTrue(config.echoConfigurations());
        assertTrue(config.echoPlaylists());
        assertTrue(config.echoAnalytics());
        assertEquals(200, config.getAnalyticsMessageStorageLimit());
    }
}
