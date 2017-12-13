package com.tune.ma.inapp.model;

import com.tune.TuneUnitTest;
import com.tune.ma.inapp.model.banner.TuneBanner;
import com.tune.ma.playlist.model.TunePlaylist;
import com.tune.ma.utils.TuneFileUtils;
import com.tune.ma.utils.TuneJsonUtils;

import org.json.JSONObject;

import java.util.Iterator;

/**
 * Created by johng on 3/9/17.
 */

public class TuneBannerTests extends TuneUnitTest {
    private TunePlaylist playlist;
    private TuneBanner message;

    public void setUp() throws Exception {
        super.setUp();
        JSONObject playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_2.0_single_banner_message.json");
        playlist = new TunePlaylist(playlistJson);
    }

    public void testConstructor() {
        JSONObject inAppMessagesJson = playlist.getInAppMessages();

        // Iterate through in-app messages and create map of messages
        Iterator<String> inAppMessagesIter = inAppMessagesJson.keys();
        String triggerRuleId;
        while (inAppMessagesIter.hasNext()) {
            triggerRuleId = inAppMessagesIter.next();

            JSONObject inAppMessage = TuneJsonUtils.getJSONObject(inAppMessagesJson, triggerRuleId);

            message = new TuneBanner(inAppMessage) {
                @Override
                // For these tests we never want this method to fire; suppressing lint warn
                @SuppressWarnings("UnnecessaryReturnStatement")
                public synchronized void display() {
                    return;
                }
            };
        }

        assertEquals(TuneBanner.Location.BOTTOM, message.getLocation());
        assertEquals(TuneBanner.Transition.FADE_IN, message.getTransition());
        assertEquals(10, message.getDuration());
    }
}
