package com.tune.ma.inapp.model;

import com.tune.TuneUnitTest;
import com.tune.ma.inapp.model.modal.TuneModal;
import com.tune.ma.playlist.model.TunePlaylist;
import com.tune.ma.utils.TuneFileUtils;
import com.tune.ma.utils.TuneJsonUtils;

import org.json.JSONObject;

import java.util.Iterator;

/**
 * Created by johng on 4/11/17.
 */

public class TuneModalTests extends TuneUnitTest {
    private TunePlaylist playlist;
    private TuneModal message;

    public void setUp() throws Exception {
        super.setUp();
        JSONObject playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_2.0_single_modal_message.json");
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

            message = new TuneModal(inAppMessage) {
                @Override
                public void display() {
                    return;
                }
            };
        }

        assertEquals(300, message.getWidth());
        assertEquals(400, message.getHeight());
        assertEquals(TuneModal.EdgeStyle.ROUND, message.getEdgeStyle());
        assertEquals(TuneModal.Background.DARK, message.getBackground());
    }
}
