package com.tune.ma.playlist;

import com.tune.TuneDebugUtilities;
import com.tune.TuneTestConstants;
import com.tune.TuneTestWrapper;
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

import java.util.ArrayList;
import java.util.List;


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

    public void testPlaylistIsLoadedFromDiskBeforePowerHookValuesAreRead() {
        // Register a power hook
        TuneManager.getInstance().getPowerHookManager().registerPowerHook("showMainScreen", "Show Main Screen", "NO", null, null);

        // Power hook value should be default
        assertEquals("NO", TuneManager.getInstance().getPowerHookManager().getValueForHookById("showMainScreen"));

        // Mock playlist being saved to disk
        mockFileManager.setPlaylistResult(playlistJson);

        // Trigger a load of powerhooks from the playlist from disk
        playlistManager = new TunePlaylistManager();

        // Power hook value should be the value from playlist
        assertEquals("YES", TuneManager.getInstance().getPowerHookManager().getValueForHookById("showMainScreen"));
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

    public void testIsUserInSegment() {
        TunePlaylist playlistWithSegments = new TunePlaylist(playlistJson);
        playlistManager.setCurrentPlaylist(playlistWithSegments);

        assertTrue(playlistManager.isUserInSegmentId("abc"));
        assertFalse(playlistManager.isUserInSegmentId("xyz"));
    }

    public void testIsUserInAnySegments() {
        TunePlaylist playlistWithSegments = new TunePlaylist(playlistJson);
        playlistManager.setCurrentPlaylist(playlistWithSegments);

        // Add some segment ids that aren't in the playlist
        List<String> segmentIds = new ArrayList<String>();
        segmentIds.add("asdf");
        segmentIds.add("xyz");

        // User should not be found in any of the segments
        assertFalse(playlistManager.isUserInAnySegmentIds(segmentIds));

        // Add a segment id that IS in the playlist
        segmentIds.add("def");

        // User should now be found in a segment
        assertTrue(playlistManager.isUserInAnySegmentIds(segmentIds));
    }

    // If segments in playlist is empty, should not crash
    public void testIsUserInEmptySegment() throws Exception {
        TunePlaylist playlistWithEmptySegments = new TunePlaylist(TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_default.json"));
        playlistManager.setCurrentPlaylist(playlistWithEmptySegments);

        assertFalse(playlistManager.isUserInSegmentId("abc"));
        assertFalse(playlistManager.isUserInSegmentId("xyz"));
        assertFalse(playlistManager.isUserInSegmentId(""));
    }

    // If user passes null or empty params, should not crash
    public void testIsUserInSegmentWithNullOrEmpty() throws Exception {
        TunePlaylist playlistWithEmptySegments = new TunePlaylist(TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_default.json"));
        playlistManager.setCurrentPlaylist(playlistWithEmptySegments);

        assertFalse(playlistManager.isUserInSegmentId(""));
        assertFalse(playlistManager.isUserInSegmentId(null));

        List<String> emptySegmentIds = new ArrayList<String>();
        emptySegmentIds.add("");
        emptySegmentIds.add("");

        assertFalse(playlistManager.isUserInAnySegmentIds(emptySegmentIds));
        assertFalse(playlistManager.isUserInAnySegmentIds(null));
    }

    // If playlist doesn't contain "segments" key, should not crash
    public void testIsUserInSegmentWithPlaylistMissingSegments() throws Exception {
        TunePlaylist playlistWithEmptySegments = new TunePlaylist(TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_without_segments.json"));
        playlistManager.setCurrentPlaylist(playlistWithEmptySegments);

        assertFalse(playlistManager.isUserInSegmentId("abc"));
        assertFalse(playlistManager.isUserInSegmentId("xyz"));
        assertFalse(playlistManager.isUserInSegmentId(""));
        assertFalse(playlistManager.isUserInSegmentId(null));

        // Create a list of segment ids
        List<String> segmentIds = new ArrayList<String>();
        segmentIds.add("asdf");
        segmentIds.add("xyz");

        List<String> emptySegmentIds = new ArrayList<String>();
        emptySegmentIds.add("");
        emptySegmentIds.add("");

        assertFalse(playlistManager.isUserInAnySegmentIds(segmentIds));
        assertFalse(playlistManager.isUserInAnySegmentIds(emptySegmentIds));
        assertFalse(playlistManager.isUserInAnySegmentIds(null));
    }

    public void testForceSetUserInSegment() {
        TunePlaylist playlistWithSegments = new TunePlaylist(playlistJson);
        playlistManager.setCurrentPlaylist(playlistWithSegments);

        String segmentId = "localTestSegmentId";

        TuneDebugUtilities.forceSetUserInSegmentId(segmentId, true);

        assertTrue(TuneTestWrapper.getInstance().isUserInSegmentId(segmentId));

        TuneDebugUtilities.forceSetUserInSegmentId(segmentId, false);

        assertFalse(TuneTestWrapper.getInstance().isUserInSegmentId(segmentId));
    }

    // If playlist doesn't contain "segments" key, we should still be able to force set values
    public void testForceSetUserInSegmentWithPlaylistMissingSegments() throws Exception {
        TunePlaylist playlistWithEmptySegments = new TunePlaylist(TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_without_segments.json"));
        playlistManager.setCurrentPlaylist(playlistWithEmptySegments);

        String segmentId = "localTestSegmentId";

        TuneDebugUtilities.forceSetUserInSegmentId(segmentId, true);

        assertTrue(TuneTestWrapper.getInstance().isUserInSegmentId(segmentId));

        TuneDebugUtilities.forceSetUserInSegmentId(segmentId, false);

        assertFalse(TuneTestWrapper.getInstance().isUserInSegmentId(segmentId));
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
