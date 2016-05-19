package com.tune.ma.playlist;

import com.tune.TuneUnitTest;
import com.tune.ma.TuneManager;
import com.tune.ma.application.TuneActivity;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneActivityConnected;
import com.tune.ma.eventbus.event.TuneActivityDisconnected;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.playlist.model.TunePlaylist;
import com.tune.ma.powerhooks.TunePowerHookManager;
import com.tune.ma.session.TuneSessionManager;
import com.tune.ma.utils.TuneFileUtils;
import com.tune.mocks.MockFileManager;
import com.tune.testutils.SimpleCallback;
import com.tune.testutils.TuneTestUtils;

import org.json.JSONObject;
import org.mockito.Mock;

import java.util.UUID;

/**
 * Created by johng on 4/18/16.
 */
public class TunePlaylistCallbackTests extends TuneUnitTest {
    @Mock
    TuneActivity activity;

    TunePlaylistManager playlistManager;
    TunePowerHookManager powerhookManager;
    TuneSessionManager sessionManager;
    MockFileManager mockFileManager;
    JSONObject playlistJson;

    @Override
    protected void setUp() throws Exception {
        super.setUp();

        //unregister experiment manager because simple_playlist.json is not a completely valid playlist
        TuneEventBus.unregister(TuneManager.getInstance().getExperimentManager());

        playlistManager = TuneManager.getInstance().getPlaylistManager();
        powerhookManager = TuneManager.getInstance().getPowerHookManager();
        sessionManager = TuneManager.getInstance().getSessionManager();
        // Set hasActivityVisible to true
        sessionManager.setActivityVisible(true);

        mockFileManager = new MockFileManager();
        TuneManager.getInstance().setFileManager(mockFileManager);

        playlistJson = TuneFileUtils.readFileFromAssetsIntoJsonObject(getContext(), "simple_playlist.json");
    }

    @Override
    protected void tearDown() throws Exception {
        playlistManager.onEvent(new TuneAppBackgrounded());

        super.tearDown();
    }

    // Test that callback is executed after 3s with no playlist download
    public void testCallbackExecutedAfterTimeout() {
        final SimpleCallback callback = new SimpleCallback();
        playlistManager.onFirstPlaylistDownloaded(callback, 3000);

        // Wait 3s default timeout
        TuneTestUtils.assertEventually(3500, new Runnable() {
            @Override
            public void run() {
                // Callback should be executed
                assertTrue(callback.getCallbackExecuted());
            }
        });
    }

    // Test that callback is canceled on app background
    public void testCallbackCanceledAfterBackground() {
        final SimpleCallback callback = new SimpleCallback();
        playlistManager.onFirstPlaylistDownloaded(callback, 3000);

        // Trigger callback clear with app background
        playlistManager.onEvent(new TuneAppBackgrounded());

        // Wait 3s default timeout
        TuneTestUtils.assertEventually(3500, new Runnable() {
            @Override
            public void run() {
                // Timer should have been canceled, so callback was not executed
                assertFalse(callback.getCallbackExecuted());
            }
        });
    }

    // Test that callback is canceled on app background and resumed on app foreground
    public void testCallbackCanceledAndResumedAfterBackgroundForeground() {
        final SimpleCallback callback = new SimpleCallback();
        playlistManager.onFirstPlaylistDownloaded(callback, 3000);

        // Trigger callback clear with app background
        playlistManager.onEvent(new TuneAppBackgrounded());
        // Trigger new session
        playlistManager.onEvent(new TuneAppForegrounded(UUID.randomUUID().toString(), System.currentTimeMillis()));

        // Wait 3s default timeout
        TuneTestUtils.assertEventually(3500, new Runnable() {
            @Override
            public void run() {
                // Callback should be executed
                assertTrue(callback.getCallbackExecuted());
            }
        });
    }

    // Test that callback is executed when app is killed
    // and callback is registered at Activity level
    public void testCallbackExecutedAgainAfterTimeoutAfterBackgroundForeground() {
        final SimpleCallback callback = new SimpleCallback();
        playlistManager.onFirstPlaylistDownloaded(callback, 3000);
        // Trigger playlist download with new session
        playlistManager.onEvent(new TuneAppForegrounded(UUID.randomUUID().toString(), System.currentTimeMillis()));
        // Trigger callback clear with app background
        playlistManager.onEvent(new TuneAppBackgrounded());

        TuneTestUtils.assertEventually(3500, new Runnable() {
            @Override
            public void run() {
                // Timer should have been canceled, so callback was not executed
                assertFalse(callback.getCallbackExecuted());
            }
        });

        // Re-register callback to simulate callback being registered in Activity#onCreate
        playlistManager.onFirstPlaylistDownloaded(callback, 3000);

        // Trigger playlist re-download with new session
        playlistManager.onEvent(new TuneAppForegrounded(UUID.randomUUID().toString(), System.currentTimeMillis()));

        // Wait 3s default timeout
        TuneTestUtils.assertEventually(3500, new Runnable() {
            @Override
            public void run() {
                // Callback should be executed
                assertTrue(callback.getCallbackExecuted());
            }
        });
    }

    // Test that callback is executed when app is killed
    // and callback is registered at Application level
    public void testCallbackExecutedAgainAfterTimeoutAfterBackgroundForegroundWithNoRegister() {
        final SimpleCallback callback = new SimpleCallback();
        playlistManager.onFirstPlaylistDownloaded(callback, 3000);
        // Trigger playlist download with new session
        playlistManager.onEvent(new TuneAppForegrounded(UUID.randomUUID().toString(), System.currentTimeMillis()));
        // Trigger callback clear with app background
        playlistManager.onEvent(new TuneAppBackgrounded());

        TuneTestUtils.assertEventually(3500, new Runnable() {
            @Override
            public void run() {
                // Timer should have been canceled, so callback was not executed
                assertFalse(callback.getCallbackExecuted());
            }
        });

        // Don't register callback, to simulate callback being registered in Application#onCreate

        // Trigger playlist download with new session
        playlistManager.onEvent(new TuneAppForegrounded(UUID.randomUUID().toString(), System.currentTimeMillis()));
        // Simulate a playlist download
        TunePlaylist notFromDiskPlaylist = new TunePlaylist(playlistJson);
        playlistManager.setCurrentPlaylist(notFromDiskPlaylist);

        // Wait 3s default timeout
        TuneTestUtils.assertEventually(3500, new Runnable() {
            @Override
            public void run() {
                // Callback should be executed
                assertTrue(callback.getCallbackExecuted());
            }
        });
    }

    // Test that registering a second callback overrides first callback
    public void testSecondCallbackExecutedAfterTimeoutWhenRegisteredTwice() {
        final SimpleCallback callback = new SimpleCallback();
        playlistManager.onFirstPlaylistDownloaded(callback, 3000);

        // Register a second callback, should override first
        final SimpleCallback callback2 = new SimpleCallback();
        playlistManager.onFirstPlaylistDownloaded(callback2, 3000);

        // Trigger playlist download with new session
        playlistManager.onEvent(new TuneAppForegrounded(UUID.randomUUID().toString(), System.currentTimeMillis()));

        // Wait 3s default timeout
        TuneTestUtils.assertEventually(3500, new Runnable() {
            @Override
            public void run() {
                // Callback 1 should have been canceled, so callback was not executed
                assertFalse(callback.getCallbackExecuted());
                // Callback 2 should have been executed
                assertTrue(callback2.getCallbackExecuted());
            }
        });
    }

    // Test that within the same session, if a callback is registered twice it executes twice
    // Actually tests for the case of backgrounding and foregrounding the app before 1s has passed,
    // thus not triggering an actual background + foreground event to be seen as a separate session,
    // but does trigger a second register call in this same "session"
    public void testBothCallbacksExecutedWhenRegisteredTwice() {
        // Simulate a playlist download
        TunePlaylist notFromDiskPlaylist = new TunePlaylist(playlistJson);
        playlistManager.setCurrentPlaylist(notFromDiskPlaylist);

        final SimpleCallback callback = new SimpleCallback();
        playlistManager.onFirstPlaylistDownloaded(callback, 3000);

        // Callback should execute immediately since playlist already downloaded
        TuneTestUtils.assertEventually(100, new Runnable() {
            @Override
            public void run() {
                // Callback should have been executed
                assertTrue(callback.getCallbackExecuted());
            }
        });

        // Register a second callback, should override first
        final SimpleCallback callback2 = new SimpleCallback();
        playlistManager.onFirstPlaylistDownloaded(callback2, 3000);

        // Wait 3s default timeout
        TuneTestUtils.assertEventually(100, new Runnable() {
            @Override
            public void run() {
                // Callback should have been executed
                assertTrue(callback2.getCallbackExecuted());
            }
        });
    }

    // Test that registering a callback after a playlist has been downloaded executes it immediately
    public void testCallbackExecutedWhenRegisteredAfterPlaylistDownload() {
        // Simulate a playlist download
        TunePlaylist notFromDiskPlaylist = new TunePlaylist(playlistJson);
        playlistManager.setCurrentPlaylist(notFromDiskPlaylist);

        // Register the callback well after the download, like CVS's use case
        final SimpleCallback callback = new SimpleCallback();
        playlistManager.onFirstPlaylistDownloaded(callback, 3000);

        // Callback should execute immediately since playlist already downloaded
        TuneTestUtils.assertEventually(100, new Runnable() {
            @Override
            public void run() {
                // Callback should be executed
                assertTrue(callback.getCallbackExecuted());
            }
        });
    }

    // Test that downloading a playlist after a callback has been registered executes it immediately
    public void testCallbackExecutedWhenRegisteredBeforePlaylistDownload() {
        // Register the callback before the download
        final SimpleCallback callback = new SimpleCallback();
        playlistManager.onFirstPlaylistDownloaded(callback, 3000);

        // Simulate a playlist download
        TunePlaylist notFromDiskPlaylist = new TunePlaylist(playlistJson);
        playlistManager.setCurrentPlaylist(notFromDiskPlaylist);

        // Callback should execute immediately since playlist just downloaded
        TuneTestUtils.assertEventually(100, new Runnable() {
            @Override
            public void run() {
                // Callback should be executed
                assertTrue(callback.getCallbackExecuted());
            }
        });
    }

    // Test that playlist callback executes after the playlist is actually updated, for example powerhook values updated
    public void testOnPlaylistFirstDownloadIsCalledAfterPowerHookUpdate() {
        // Register a power hook so that it can be changed when the playlist downloads
        tune.registerPowerHook("itemsToDisplay", "items to display", "0");

        // Register the callbacks before the download
        final SimpleCallback playlistCallback = new SimpleCallback();
        final SimpleCallback powerhookCallback = new SimpleCallback();

        playlistManager.onFirstPlaylistDownloaded(playlistCallback, 3000);
        powerhookManager.onPowerHooksChanged(powerhookCallback);

        // Simulate a playlist download
        TunePlaylist notFromDiskPlaylist = new TunePlaylist(playlistJson);
        playlistManager.setCurrentPlaylist(notFromDiskPlaylist);

        TuneTestUtils.assertEventually(100, new Runnable() {
            @Override
            public void run() {
                // Power hooks changed callback should be executed before the playlist callback
                assertTrue(powerhookCallback.getExecutedTime() <= playlistCallback.getExecutedTime());
            }
        });
    }

    public void testPlaylistCallbackIsCalledWhenPlaylistIsNotUpdated() {
        // Register the callback before the download
        final SimpleCallback callback = new SimpleCallback();
        playlistManager.onFirstPlaylistDownloaded(callback, 3000);

        // Simulate a playlist download
        TunePlaylist notFromDiskPlaylist = new TunePlaylist(playlistJson);
        playlistManager.setCurrentPlaylist(notFromDiskPlaylist);

        // Callback should execute immediately since playlist just downloaded
        TuneTestUtils.assertEventually(100, new Runnable() {
            @Override
            public void run() {
                // Callback should be executed
                assertTrue(callback.getCallbackExecuted());
            }
        });

        // Register the callback before the download
        final SimpleCallback callback2 = new SimpleCallback();
        playlistManager.onFirstPlaylistDownloaded(callback2, 3000);

        // Simulate a playlist download of the same playlist
        TunePlaylist fromDiskPlaylist = new TunePlaylist(playlistJson);
        playlistManager.setCurrentPlaylist(fromDiskPlaylist);

        // Callback should execute immediately even though downloaded playlist is not different
        TuneTestUtils.assertEventually(100, new Runnable() {
            @Override
            public void run() {
                // Callback should be executed
                assertTrue(callback2.getCallbackExecuted());
            }
        });
    }

    // Tests backgrounding the app and downloading playlist before 1s has passed, and make sure callback is not executed
    public void testCallbackNotCalledWhenAppIsInBackgroundLessThan1Second() {
        // Register the callback before the download
        final SimpleCallback callback = new SimpleCallback();
        playlistManager.onFirstPlaylistDownloaded(callback, 3000);

        // Simulate an Activity disconnect
        sessionManager.onEvent(new TuneActivityDisconnected(activity));

        // Simulate a playlist download so that callback tries to execute
        TunePlaylist notFromDiskPlaylist = new TunePlaylist(playlistJson);
        playlistManager.setCurrentPlaylist(notFromDiskPlaylist);

        // Callback should not be executed since app is in background
        TuneTestUtils.assertEventually(100, new Runnable() {
            @Override
            public void run() {
                // Callback should be executed
                assertFalse(callback.getCallbackExecuted());
            }
        });
    }

    // Test backgrounding the app and downloading playlist, that callback is not executed
    public void testCallbackNotCalledWhenAppIsInBackground() {
        // Register the callback before the download
        final SimpleCallback callback = new SimpleCallback();
        playlistManager.onFirstPlaylistDownloaded(callback, 3000);

        // Simulate an Activity disconnect
        sessionManager.onEvent(new TuneActivityDisconnected(activity));

        // Wait at least 1s for app background to be recognized
        sleep(1500);

        // Simulate a playlist download so that callback tries to execute
        TunePlaylist notFromDiskPlaylist = new TunePlaylist(playlistJson);
        playlistManager.setCurrentPlaylist(notFromDiskPlaylist);

        // Callback should not be executed, since app is in background
        TuneTestUtils.assertEventually(100, new Runnable() {
            @Override
            public void run() {
                // Callback should be executed
                assertFalse(callback.getCallbackExecuted());
            }
        });
    }

    // Test that canceled callback gets executed when app is foregrounded again
    public void testCallbackNotCalledWhenAppIsInBackgroundAndCalledWhenResumed() {
        // Register the callback before the download
        final SimpleCallback callback = new SimpleCallback();
        playlistManager.onFirstPlaylistDownloaded(callback, 3000);

        // Simulate an Activity disconnect
        sessionManager.onEvent(new TuneActivityDisconnected(activity));

        // Wait at least 1s for app background to be recognized
        sleep(1500);

        // Simulate a playlist download so that callback tries to execute
        TunePlaylist notFromDiskPlaylist = new TunePlaylist(playlistJson);
        playlistManager.setCurrentPlaylist(notFromDiskPlaylist);

        // Callback should not be executed, since app is in background
        TuneTestUtils.assertEventually(100, new Runnable() {
            @Override
            public void run() {
                // Callback should be executed
                assertFalse(callback.getCallbackExecuted());
            }
        });

        sleep(500);

        // Simulate an activity connect
        sessionManager.onEvent(new TuneActivityConnected(activity));

        // Callback should be executed immediately after timeout since it was previously marked as canceled and eligible to retry
        // and we already have a playlist
        TuneTestUtils.assertEventually(100, new Runnable() {
            @Override
            public void run() {
                assertTrue(callback.getCallbackExecuted());
            }
        });
    }

}
