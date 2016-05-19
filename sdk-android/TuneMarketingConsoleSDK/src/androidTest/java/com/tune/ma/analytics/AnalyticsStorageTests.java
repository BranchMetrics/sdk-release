package com.tune.ma.analytics;

import com.tune.TuneEvent;
import com.tune.ma.TuneManager;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneEventOccurred;

import org.json.JSONArray;

/**
 * Created by johng on 1/11/16.
 */
public class AnalyticsStorageTests extends TuneAnalyticsTest {

    /**
     * Test that measureSession causes a write to disk
     * @throws InterruptedException
     */
    public void testMeasureSessionStored() throws InterruptedException {
        // Don't dispatch while we're trying to read file
        TuneManager.getInstance().getAnalyticsManager().stopScheduledDispatch();

        // Trigger a session
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("session")));

        JSONArray storedAnalytics = TuneManager.getInstance().getFileManager().readAnalytics();
        assertEquals(0, storedAnalytics.length());

        // Triggering directly instead of through Foreground so it doesn't get sent out
        TuneManager.getInstance().getAnalyticsManager().setShouldQueueCustomEvents(false);

        // Allow some time to write analytics to disk
        Thread.sleep(200);

        // Check that analytics was written to disk in correct format
        storedAnalytics = TuneManager.getInstance().getFileManager().readAnalytics();
        assertEquals(1, storedAnalytics.length());
    }

    /**
     * Test that measureEvent causes a write to disk
     * @throws InterruptedException
     */
    public void testMeasureEventStored() throws InterruptedException {
        // Don't dispatch while we're trying to read file
        TuneManager.getInstance().getAnalyticsManager().stopScheduledDispatch();

        // Trigger events
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("testEvent")));
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("testEvent2")));

        JSONArray storedAnalytics = TuneManager.getInstance().getFileManager().readAnalytics();
        assertEquals(0, storedAnalytics.length());

        // Triggering directly instead of through Foreground so it doesn't get sent out
        TuneManager.getInstance().getAnalyticsManager().setShouldQueueCustomEvents(false);

        // Allow some time to write analytics to disk
        Thread.sleep(200);

        // Check that analytics was written to disk in correct format
        storedAnalytics = TuneManager.getInstance().getFileManager().readAnalytics();
        assertEquals(2, storedAnalytics.length());
    }

    public void testAnalyticsStoredAfterCustomEventQueueTurnedOff() throws InterruptedException {
        // Don't dispatch while we're trying to read file
        TuneManager.getInstance().getAnalyticsManager().stopScheduledDispatch();

        // Trigger events
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("testEvent")));
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("testEvent2")));

        JSONArray storedAnalytics = TuneManager.getInstance().getFileManager().readAnalytics();
        assertEquals(0, storedAnalytics.length());

        // Triggering directly instead of through Foreground so it doesn't get sent out
        TuneManager.getInstance().getAnalyticsManager().setShouldQueueCustomEvents(false);

        // Allow some time to write analytics to disk
        Thread.sleep(200);

        // Check that analytics was written to disk in correct format
        storedAnalytics = TuneManager.getInstance().getFileManager().readAnalytics();
        assertEquals(2, storedAnalytics.length());

        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("testEvent3")));
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("testEvent4")));

        Thread.sleep(200);

        // Check that analytics was written to disk in correct format
        storedAnalytics = TuneManager.getInstance().getFileManager().readAnalytics();
        assertEquals(4, storedAnalytics.length());
    }
}

