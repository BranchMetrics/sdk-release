package com.tune.ma.inapp.model;

import android.support.test.runner.AndroidJUnit4;

import com.tune.TuneUnitTest;
import com.tune.ma.inapp.model.modal.TuneModal;
import com.tune.ma.playlist.model.TunePlaylist;
import com.tune.ma.utils.TuneFileUtils;
import com.tune.ma.utils.TuneJsonUtils;

import org.json.JSONObject;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.Iterator;

import static android.support.test.InstrumentationRegistry.getContext;
import static org.junit.Assert.assertEquals;

/**
 * Created by johng on 4/11/17.
 */
@RunWith(AndroidJUnit4.class)
public class TuneModalTests extends TuneUnitTest {
    private TunePlaylist playlist;
    private TuneModal message;

    @Before
    public void setUp() throws Exception {
        super.setUp();
        JSONObject playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "playlist_2.0_single_modal_message.json");
        playlist = new TunePlaylist(playlistJson);
    }

    @Test
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
                // For these tests we never want this method to fire; suppressing lint warn
                @SuppressWarnings("UnnecessaryReturnStatement")
                public synchronized void display() {
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
