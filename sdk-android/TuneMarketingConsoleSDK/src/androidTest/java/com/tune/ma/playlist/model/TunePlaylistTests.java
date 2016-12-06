package com.tune.ma.playlist.model;

import com.tune.TuneUnitTest;
import com.tune.ma.utils.TuneFileUtils;

import org.json.JSONObject;

/**
 * Created by johng on 11/9/16.
 */

public class TunePlaylistTests extends TuneUnitTest {
    private JSONObject playlistJson;

    public void setUp() throws Exception {
        super.setUp();
        playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "simple_playlist.json");
    }

    public void testPlaylistEquality() throws Exception {
        JSONObject playlistJson2 = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "simple_playlist.json");
        TunePlaylist playlist1 = new TunePlaylist(playlistJson);
        TunePlaylist playlist2 = new TunePlaylist(playlistJson2);

        assertTrue("Playlists should be equal, but weren't", playlist1.equals(playlist2));
    }

    public void testPlaylistEqualityWithNullObject() {
        // Test with null object
        TunePlaylist playlist1 = new TunePlaylist(playlistJson);
        TunePlaylist playlist2 = null;

        assertFalse(playlist1.equals(playlist2));
    }

    public void testPlaylistEqualityWithNullSchema() {
        // Test with null schema version
        TunePlaylist playlist1 = new TunePlaylist(playlistJson);
        TunePlaylist playlist2 = new TunePlaylist(playlistJson);
        playlist2.setSchemaVersion(null);

        assertFalse(playlist1.equals(playlist2));

        playlist1.setSchemaVersion(null);

        assertTrue(playlist1.equals(playlist2));
    }

    public void testPlaylistEqualityWithNullPowerHooks() {
        // Test with null power hooks
        TunePlaylist playlist1 = new TunePlaylist(playlistJson);
        TunePlaylist playlist2 = new TunePlaylist(playlistJson);
        playlist2.setPowerHooks(null);

        assertFalse(playlist1.equals(playlist2));

        playlist1.setPowerHooks(null);

        assertTrue(playlist1.equals(playlist2));
    }

    public void testPlaylistEqualityWithNullInAppMessages() {
        // Test with null in-app messages
        TunePlaylist playlist1 = new TunePlaylist(playlistJson);
        TunePlaylist playlist2 = new TunePlaylist(playlistJson);
        playlist2.setInAppMessages(null);

        assertFalse(playlist1.equals(playlist2));

        playlist1.setInAppMessages(null);

        assertTrue(playlist1.equals(playlist2));
    }

    public void testPlaylistEqualityWithNullSegments() {
        // Test with null segments
        TunePlaylist playlist1 = new TunePlaylist(playlistJson);
        TunePlaylist playlist2 = new TunePlaylist(playlistJson);
        playlist2.setSegments(null);

        assertFalse(playlist1.equals(playlist2));

        playlist1.setSegments(null);

        assertTrue(playlist1.equals(playlist2));
    }

    public void testPlaylistEqualityWithNullExperimentDetails() {
        // Test with null experiment details
        TunePlaylist playlist1 = new TunePlaylist(playlistJson);
        TunePlaylist playlist2 = new TunePlaylist(playlistJson);
        playlist2.setExperimentDetails(null);

        assertFalse(playlist1.equals(playlist2));

        playlist1.setExperimentDetails(null);

        assertTrue(playlist1.equals(playlist2));
    }

    public void testPlaylistHashCodeEquality() throws Exception {
        JSONObject playlistJson2 = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "simple_playlist.json");
        TunePlaylist playlist1 = new TunePlaylist(playlistJson);
        TunePlaylist playlist2 = new TunePlaylist(playlistJson2);

        assertTrue("Playlist hash codes should be equal, but were " + playlist1.hashCode() + " and " + playlist2.hashCode(), playlist1.hashCode() == playlist2.hashCode());
    }
}
