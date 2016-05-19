package com.tune.ma.playlist;

import com.tune.TuneTestConstants;
import com.tune.TuneUnitTest;
import com.tune.ma.TuneManager;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.TunePlaylistManagerCurrentPlaylistChanged;
import com.tune.ma.playlist.model.TunePlaylist;
import com.tune.ma.utils.TuneFileUtils;
import com.tune.ma.utils.TuneJsonUtils;
import com.tune.mocks.MockApi;
import com.tune.mocks.MockFileManager;
import com.tune.testutils.TuneTestUtils;

import org.json.JSONObject;


/**
 * Created by gowie on 2/1/16.
 */
public class TunePlaylistManagerTests extends TuneUnitTest {

    TunePlaylistManager playlistManager;
    MockApi mockApi;
    MockFileManager mockFileManager;
    JSONObject playlistJson;

    @Override
    protected void setUp() throws Exception {
        super.setUp();
        //unregister experiment manager because simple_playlist.json is not a completely valid playlist
        TuneEventBus.unregister(TuneManager.getInstance().getExperimentManager());

        playlistManager = TuneManager.getInstance().getPlaylistManager();

        mockFileManager = new MockFileManager();
        TuneManager.getInstance().setFileManager(mockFileManager);

        mockApi = new MockApi();
        TuneManager.getInstance().setApi(mockApi);

        playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "simple_playlist.json");
    }

    @Override
    protected void tearDown() throws Exception {
        playlistManager.onEvent(new TuneAppBackgrounded());

        super.tearDown();
    }

    public void testPlaylistRequestIsMadeOnForegroundAndLoadsPlaylist() {
        mockApi.setPlaylistResponse(playlistJson);
        playlistManager.onEvent(new TuneAppForegrounded("", 1l));

        TuneTestUtils.assertEventually(TuneTestConstants.PLAYLIST_REQUEST_PERIOD * 1000, new Runnable() {
            @Override
            public void run() {
                assertEquals(1, mockApi.getPlaylistRequestCount());
                assertNotNull(TuneJsonUtils.getJSONObject(playlistManager.getCurrentPlaylist().getPowerHooks(), "itemsToDisplay"));
            }
        });
    }

    public void testPlaylistIsLoadedFromDiskOnAppStart() {
        mockFileManager.setPlaylistResult(playlistJson);

        // Re-init to trigger load from disk
        playlistManager = new TunePlaylistManager();

        TunePlaylist playlist = playlistManager.getCurrentPlaylist();
        assertTrue(playlist.isFromDisk());
        assertEquals("10", TuneJsonUtils.getString(TuneJsonUtils.getJSONObject(playlist.getPowerHooks(), "itemsToDisplay"), "value"));
    }

    public void testPlaylistIsSavedToDiskOnAppBackground() {
        // Set current playlist to test value, will trigger a save since new playlist differs from disk
        playlistManager.setCurrentPlaylist(new TunePlaylist(playlistJson));

        // Check that value saved to disk is same as existing value
        assertEquals(mockFileManager.readPlaylist().toString(), playlistManager.getCurrentPlaylist().toJson().toString());
    }

    public void testPlaylistChangedIsOnlySentWhenPlaylistChanges() {
        TunePlaylist playlist1 = new TunePlaylist(playlistJson);
        TunePlaylist playlist2 = new TunePlaylist(playlistJson);

        PlaylistChangedReceiver changedReceiver = new PlaylistChangedReceiver();
        TuneEventBus.register(changedReceiver);

        playlistManager.setCurrentPlaylist(playlist1);

        assertTrue(changedReceiver.getEventReceived());

        changedReceiver.setEventReceived(false);

        playlistManager.setCurrentPlaylist(playlist2);

        assertFalse(changedReceiver.getEventReceived());
    }

    // Helpers
    ///////////

    class PlaylistChangedReceiver {

        boolean eventReceived;

        public PlaylistChangedReceiver() {
            eventReceived = false;
        }

        public void onEvent(TunePlaylistManagerCurrentPlaylistChanged event) {
            eventReceived = true;
        }

        public boolean getEventReceived() {
            return eventReceived;
        }

        public void setEventReceived(boolean eventReceived) {
            this.eventReceived = eventReceived;
        }
    }
}
