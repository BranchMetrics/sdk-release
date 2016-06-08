package com.tune.ma.experiments;

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

import java.util.Map;

/**
 * Created by kristine on 2/9/16.
 */
public class TuneExperimentManagerTests extends TuneUnitTest {

    TunePlaylistManager playlistManager;
    TuneExperimentManager experimentManager;
    MockApi mockApi;
    MockFileManager mockFileManager;
    JSONObject playlistJson;

    @Override
    protected void setUp() throws Exception {
        super.setUp();
        experimentManager = TuneManager.getInstance().getExperimentManager();

        playlistManager = TuneManager.getInstance().getPlaylistManager();

        mockFileManager = new MockFileManager();
        TuneManager.getInstance().setFileManager(mockFileManager);

        mockApi = new MockApi();
        TuneManager.getInstance().setApi(mockApi);

        playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "tune_experiment_manager_test_playlist.json");
    }

    @Override
    protected void tearDown() throws Exception {
        super.tearDown();
        playlistManager.onEvent(new TuneAppBackgrounded());
    }

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

    public void testActiveVariationsOnlyGetAddedOnce() {
        mockFileManager.setPlaylistResult(playlistJson);
        playlistManager = new TunePlaylistManager();

        assertEquals(2, TuneManager.getInstance().getProfileManager().getSessionVariables().size());

        mockFileManager.setPlaylistResult(playlistJson);
        playlistManager = new TunePlaylistManager();

        assertEquals(2, TuneManager.getInstance().getProfileManager().getSessionVariables().size());
    }

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
    public void testPublicGetPowerHookExperimentDetails() {
        mockFileManager.setPlaylistResult(playlistJson);
        playlistManager = new TunePlaylistManager();

        Map<String, TunePowerHookExperimentDetails> experimentDetails = experimentManager.getPhookExperimentDetails();
        Map<String, TunePowerHookExperimentDetails> experimentDetailsPublic = tune.getPowerHookExperimentDetails();
        assertEquals(experimentDetails, experimentDetailsPublic);
    }

    // Test that the public getter's experiment details match that of the experiment manager's
    public void testPublicGetInAppExperimentDetails() {
        mockFileManager.setPlaylistResult(playlistJson);
        playlistManager = new TunePlaylistManager();

        Map<String, TuneInAppMessageExperimentDetails> experimentDetails = experimentManager.getInAppExperimentDetails();
        Map<String, TuneInAppMessageExperimentDetails> experimentDetailsPublic = tune.getInAppMessageExperimentDetails();
        assertEquals(experimentDetails, experimentDetailsPublic);
    }
}
