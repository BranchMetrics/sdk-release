package com.tune.ma.experiments;

import android.support.test.runner.AndroidJUnit4;

import com.tune.TuneUnitTest;
import com.tune.ma.TuneManager;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.experiments.model.TuneInAppMessageExperimentDetails;
import com.tune.ma.experiments.model.TunePowerHookExperimentDetails;
import com.tune.ma.playlist.TunePlaylistManager;
import com.tune.ma.utils.TuneFileUtils;
import com.tune.mocks.MockApi;
import com.tune.mocks.MockFileManager;

import org.json.JSONException;
import org.json.JSONObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.Map;

import static android.support.test.InstrumentationRegistry.getContext;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

/**
 * Created by kristine on 2/9/16.
 */
@RunWith(AndroidJUnit4.class)
public class TuneExperimentManagerTests extends TuneUnitTest {

    TunePlaylistManager playlistManager;
    TuneExperimentManager experimentManager;
    MockApi mockApi;
    MockFileManager mockFileManager;
    JSONObject playlistJson;

    @Before
    public void setUp() throws Exception {
        super.setUp();
        experimentManager = TuneManager.getInstance().getExperimentManager();

        playlistManager = TuneManager.getInstance().getPlaylistManager();

        mockFileManager = new MockFileManager();
        TuneManager.getInstance().setFileManager(mockFileManager);

        mockApi = new MockApi();
        TuneManager.getInstance().setApi(mockApi);

        playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "tune_experiment_manager_test_playlist.json");
    }

    @After
    public void tearDown() throws Exception {
        super.tearDown();
        playlistManager.onEvent(new TuneAppBackgrounded());
    }

    @Test
    public void testPowerHookDetailsUpdateWithPlaylist() {
        mockFileManager.setPlaylistResult(playlistJson);
        playlistManager = new TunePlaylistManager();

        Map<String, TunePowerHookExperimentDetails> experimentDetails = experimentManager.getPhookExperimentDetails();

        assertEquals(2, experimentDetails.size());

        TunePowerHookExperimentDetails details = experimentDetails.get("itemsToDisplay");
        assertEquals("123", details.getExperimentId());
        assertEquals("Number of Items to Display Experiment", details.getExperimentName());
        assertEquals("power_hook", details.getExperimentType());
        assertEquals("abc", details.getCurrentVariantId());
        assertEquals("Variation A", details.getCurrentVariantName());
        assertTrue(details.isRunning());

        details = experimentDetails.get("showMainScreen");
        assertEquals("456", details.getExperimentId());
        assertEquals("Testing w/ Main screen hidden", details.getExperimentName());
        assertEquals("power_hook", details.getExperimentType());
        assertEquals("def", details.getCurrentVariantId());
        assertEquals("Variation B", details.getCurrentVariantName());
        assertTrue(details.isRunning());
    }

    @Test
    public void testInAppMessageDetailsUpdateWithPlaylist() {
        mockFileManager.setPlaylistResult(playlistJson);
        playlistManager = new TunePlaylistManager();

        Map<String, TuneInAppMessageExperimentDetails> experimentDetails = experimentManager.getInAppExperimentDetails();

        assertEquals(1, experimentDetails.size());

        TuneInAppMessageExperimentDetails details = experimentDetails.get("Testing a Message");
        assertEquals("789", details.getExperimentId());
        assertEquals("Testing a Message", details.getExperimentName());
        assertEquals("in_app", details.getExperimentType());
        assertEquals("foobar", details.getCurrentVariantId());
        assertEquals("Variation B", details.getCurrentVariantName());
    }

    @Test
    public void testActiveVariationsOnlyGetAddedOnce() {
        mockFileManager.setPlaylistResult(playlistJson);
        playlistManager = new TunePlaylistManager();

        assertEquals(2, TuneManager.getInstance().getProfileManager().getSessionVariables().size());

        mockFileManager.setPlaylistResult(playlistJson);
        playlistManager = new TunePlaylistManager();

        assertEquals(2, TuneManager.getInstance().getProfileManager().getSessionVariables().size());
    }

    @Test
    public void testPlaylistWithoutExperimentDetails() {
        try {
            playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_default.json");
            mockFileManager.setPlaylistResult(playlistJson);
            playlistManager.onEvent(new TuneAppForegrounded("", 1l));

            Map<String, TunePowerHookExperimentDetails> pHookExperimentDetails = experimentManager.getPhookExperimentDetails();
            Map<String, TuneInAppMessageExperimentDetails> inAppExperimentDetails = experimentManager.getInAppExperimentDetails();
            assertEquals(0, pHookExperimentDetails.size());
            assertEquals(0, inAppExperimentDetails.size());
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    // Test that the public getter's experiment details match that of the experiment manager's
    @Test
    public void testPublicGetPowerHookExperimentDetails() {
        mockFileManager.setPlaylistResult(playlistJson);
        playlistManager = new TunePlaylistManager();

        Map<String, TunePowerHookExperimentDetails> experimentDetails = experimentManager.getPhookExperimentDetails();
        Map<String, TunePowerHookExperimentDetails> experimentDetailsPublic = tune.getPowerHookExperimentDetails();
        assertEquals(experimentDetails, experimentDetailsPublic);
    }

    // Test that the public getter's experiment details match that of the experiment manager's
    @Test
    public void testPublicGetInAppExperimentDetails() {
        mockFileManager.setPlaylistResult(playlistJson);
        playlistManager = new TunePlaylistManager();

        Map<String, TuneInAppMessageExperimentDetails> experimentDetails = experimentManager.getInAppExperimentDetails();
        Map<String, TuneInAppMessageExperimentDetails> experimentDetailsPublic = tune.getInAppMessageExperimentDetails();
        assertEquals(experimentDetails, experimentDetailsPublic);
    }
}
