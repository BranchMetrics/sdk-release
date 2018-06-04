package com.tune.ma.analytics;

import android.support.test.runner.AndroidJUnit4;

import com.tune.TuneEvent;
import com.tune.ma.TuneManager;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneEventOccurred;
import com.tune.mocks.MockFileManager;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

/**
 * Created by johng on 1/11/16.
 */
@RunWith(AndroidJUnit4.class)
public class AnalyticsStorageTests extends TuneAnalyticsTest {
    MockFileManager mockFileManager;

    @Before
    public void setUp() throws Exception {
        super.setUp();

        mockFileManager = new MockFileManager();
        TuneManager.getInstance().setFileManager(mockFileManager);
    }

    /**
     * Test that measureSession causes a write to disk
     * @throws InterruptedException
     */
    @Test
    public void testMeasureSessionStored() throws InterruptedException {
        // Don't dispatch while we're trying to read file
        TuneManager.getInstance().getAnalyticsManager().stopScheduledDispatch();

        assertTrue("shouldQueueCustomEvents was not true", TuneManager.getInstance().getAnalyticsManager().shouldQueueCustomEvents());

        // Trigger a session
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("session")));

        int analyticsCount = ((MockFileManager)TuneManager.getInstance().getFileManager()).getAnalyticsCount();
        assertEquals("stored analytics length was not zero", 0, analyticsCount);
        assertEquals("custom event queue size was not 1", 1, TuneManager.getInstance().getAnalyticsManager().getCustomEventQueue().size());

        // Triggering directly instead of through Foreground so it doesn't get sent out
        TuneManager.getInstance().getAnalyticsManager().setShouldQueueCustomEvents(false);

        // Allow some time to write analytics to disk
        Thread.sleep(200);

        // Check that analytics was written to disk in correct format
        analyticsCount = ((MockFileManager)TuneManager.getInstance().getFileManager()).getAnalyticsCount();
        assertEquals("stored analytics length was not 1", 1, analyticsCount);
    }

    /**
     * Test that measureEvent causes a write to disk
     * @throws InterruptedException
     */
    @Test
    public void testMeasureEventStored() throws InterruptedException {
        // Don't dispatch while we're trying to read file
        TuneManager.getInstance().getAnalyticsManager().stopScheduledDispatch();

        // Trigger events
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("testEvent")));
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("testEvent2")));

        int analyticsCount = ((MockFileManager)TuneManager.getInstance().getFileManager()).getAnalyticsCount();
        assertEquals(0, analyticsCount);
        assertEquals(2, TuneManager.getInstance().getAnalyticsManager().getCustomEventQueue().size());

        // Triggering directly instead of through Foreground so it doesn't get sent out
        TuneManager.getInstance().getAnalyticsManager().setShouldQueueCustomEvents(false);

        // Allow some time to write analytics to disk
        Thread.sleep(200);

        // Check that analytics was written to disk in correct format
        analyticsCount = ((MockFileManager)TuneManager.getInstance().getFileManager()).getAnalyticsCount();
        assertEquals(2, analyticsCount);
    }

    @Test
    public void testAnalyticsStoredAfterCustomEventQueueTurnedOff() throws InterruptedException {
        // Don't dispatch while we're trying to read file
        TuneManager.getInstance().getAnalyticsManager().stopScheduledDispatch();

        // Trigger events
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("testEvent")));
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("testEvent2")));

        int analyticsCount = ((MockFileManager)TuneManager.getInstance().getFileManager()).getAnalyticsCount();
        assertEquals(0, analyticsCount);
        assertEquals(2, TuneManager.getInstance().getAnalyticsManager().getCustomEventQueue().size());

        // Triggering directly instead of through Foreground so it doesn't get sent out
        TuneManager.getInstance().getAnalyticsManager().setShouldQueueCustomEvents(false);

        // Allow some time to write analytics to disk
        Thread.sleep(200);

        // Check that analytics was written to disk in correct format
        analyticsCount = ((MockFileManager)TuneManager.getInstance().getFileManager()).getAnalyticsCount();
        assertEquals(2, analyticsCount);
        assertEquals(0, TuneManager.getInstance().getAnalyticsManager().getCustomEventQueue().size());

        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("testEvent3")));
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("testEvent4")));

        Thread.sleep(200);

        // Check that analytics was written to disk in correct format
        analyticsCount = ((MockFileManager)TuneManager.getInstance().getFileManager()).getAnalyticsCount();
        assertEquals(4, analyticsCount);
    }
}

