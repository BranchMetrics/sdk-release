package com.tune.ma.configuration;

import android.support.test.runner.AndroidJUnit4;

import com.tune.TuneConstants;
import com.tune.TuneTestConstants;
import com.tune.TuneUnitTest;
import com.tune.TuneUtils;
import com.tune.ma.TuneManager;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.file.FileManager;
import com.tune.ma.utils.TuneSharedPrefsDelegate;

import org.json.JSONException;
import org.json.JSONObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import static android.support.test.InstrumentationRegistry.getContext;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotSame;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

/**
 * Created by kristine on 1/27/16.
 */
@RunWith(AndroidJUnit4.class)
public class TuneConfigurationManagerTests extends TuneUnitTest {

    TuneConfigurationManager config;
    FileManager fileManager;

    @Before
    public void setUp() throws Exception {
        super.setUp();
        config = TuneManager.getInstance().getConfigurationManager();
        fileManager = TuneManager.getInstance().getFileManager();
    }

    @After
    public void tearDown() throws Exception {
        super.tearDown();
        TuneEventBus.unregister(this);
    }

    @Test
    public void testDefaultConfigurationSet() {
        assertEquals(config.getAnalyticsDispatchPeriod(), TuneTestConstants.ANALYTICS_DISPATCH_PERIOD);
        assertFalse(config.echoAnalytics());
        assertFalse(config.echoConfigurations());
        assertFalse(config.echoPlaylists());
        assertEquals(config.getAnalyticsMessageStorageLimit(), 250);
        assertEquals(config.getPlaylistRequestPeriod(), TuneTestConstants.PLAYLIST_REQUEST_PERIOD);
        assertNull(config.getPluginName());
        assertEquals("https://qa.ma.tune.com", config.getPlaylistHostPort());
        assertEquals("https://qa.ma.tune.com", config.getConfigurationHostPort());
        assertEquals("https://qa.ma.tune.com", config.getConnectedModeHostPort());
        assertEquals("https://analytics-qa.ma.tune.com/analytics", config.getAnalyticsHostPort());
        assertEquals("https://s3.amazonaws.com/uploaded-assets-qa2", config.getStaticContentHostPort());
    }

    @Test
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

    @Test
    public void testRemoteConfigUpdateDoesntAffectValuesThatShouldOnlyBeSetLocally() {
        JSONObject fakeRemoteJson = new JSONObject();
        try {
            //Local only values
            fakeRemoteJson.put("playlist_host_port", "testPlaylistHostPort");
            fakeRemoteJson.put("configuration_host_port", "testConfigurationHostPort");
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

        assertNotSame("testPlaylistHostPort", config.getPlaylistHostPort());
        assertNotSame("testConfigurationHostPort", config.getConfigurationHostPort());
        assertNotSame("testAnalyticsHostPort", config.getAnalyticsHostPort());
        assertNotSame("testStaticContentHostPort", config.getStaticContentHostPort());
        assertNotSame("testConnectedModeHostPort", config.getConnectedModeHostPort());
        assertFalse(config.usePlaylistPlayer());
        assertTrue(config.useConfigurationPlayer());
    }

    @Test
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

    @Test
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

    @Test
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

    @Test
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

    @Test
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

    @Test
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

    // Tests that app ID is never "null|null|android"
    // This case happens when TMA is disabled in the config when the app was opened,
    // then the EventBus gets disabled and cannot get updated with newer advertiser id and package name values
    @Test
    public void testForNullNullAndroidAppId() {
        // Let Tune pubQueue finish executing setPackageName
        sleep(50);

        TuneSharedPrefsDelegate prefsDelegate = new TuneSharedPrefsDelegate(getContext(), TuneConstants.PREFS_TUNE);
        // Manually disable TMA to mock downloading disabled config
        prefsDelegate.saveBooleanToSharedPreferences(TuneConfigurationConstants.TUNE_TMA_DISABLED, true);

        String expectedAppId = TuneUtils.md5("877|com.mobileapptracker.test|android");
        // Check that app id was initialized to md5 of "877|com.mobileapptracker.test|android"
        assertEquals(expectedAppId, tune.getAppId());

        // Clear and re-init TuneManager, to mock killing and starting the app that causes this state
        TuneManager.destroy();
        TuneManager.init(getContext(), null);

        // Let config download
        sleep(500);

        String appId = tune.getAppId();
        // Check that app id is still the expected value on re-init
        assertEquals(expectedAppId, appId);
        // Check that app id is not the md5 of the infamous "null|null|android"
        assertFalse(appId.equals("a3095d6697f9d75815a50a9feb36812c"));

        // Restore TMA disabled status
        prefsDelegate.saveBooleanToSharedPreferences(TuneConfigurationConstants.TUNE_TMA_DISABLED, false);
    }

    // Tests that app ID is updated correctly if user calls setPackageName with a different value
    @Test
    public void testAppIdUpdatedAfterSetPackageName() {
        // Let Tune pubQueue finish executing setPackageName
        sleep(50);

        TuneSharedPrefsDelegate prefsDelegate = new TuneSharedPrefsDelegate(getContext(), TuneConstants.PREFS_TUNE);
        // Manually disable TMA to mock downloading disabled config
        prefsDelegate.saveBooleanToSharedPreferences(TuneConfigurationConstants.TUNE_TMA_DISABLED, true);

        // Check that app id was initialized to default value, md5 of "877|com.mobileapptracker.test|android"
        assertEquals(TuneUtils.md5("877|com.mobileapptracker.test|android"), tune.getAppId());

        // Change the package name via setter
        tune.setPackageName("com.test");

        // Let Tune pubQueue finish executing setPackageName
        sleep(50);

        String expectedAppId = TuneUtils.md5("877|com.test|android");
        // Check that app id was updated to md5 of "877|com.test|android"
        assertEquals(expectedAppId, tune.getAppId());

        // Clear and re-init TuneManager, to mock a new startup
        TuneManager.destroy();
        TuneManager.init(getContext(), null);

        // Let config download
        sleep(500);

        String appId = tune.getAppId();
        // Check that app id is still the expected value on next session
        assertEquals(expectedAppId, appId);

        // Restore TMA disabled status
        prefsDelegate.saveBooleanToSharedPreferences(TuneConfigurationConstants.TUNE_TMA_DISABLED, false);
        // Restore package name
        tune.setPackageName("com.mobileapptracker.test");
    }
}
