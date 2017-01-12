package com.tune.ma.eventbus;

import android.test.AndroidTestCase;

import com.tune.TuneEvent;
import com.tune.ma.eventbus.event.TuneEventOccurred;
import com.tune.ma.eventbus.event.TuneGetAdvertisingIdCompleted;
import com.tune.ma.eventbus.event.TuneManagerInitialized;
import com.tune.ma.eventbus.event.userprofile.TuneUpdateUserProfile;

import java.util.UUID;

/**
 * Created by johng on 2/18/16.
 */
public class TuneEventBusTests extends AndroidTestCase {
    @Override
    public void setUp() throws Exception {
        super.setUp();
        TuneEventBus.clearFlags();
        TuneEventBus.enable();
    }

    @Override
    public void tearDown() throws Exception {
        TuneEventBus.disable();
        super.tearDown();
    }

    public void testEventsQueuedBeforeManagerInitialized() {
        // Post an event before manager is initialized
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("testEvent")));

        // Check that queue has one event
        assertEquals(1, TuneEventBus.getQueue().size());

        // Post a TuneManagerInitialized event
        TuneEventBus.post(new TuneManagerInitialized());

        // Check that queue is not dequeued yet (haven't received GAID event)
        assertEquals(1, TuneEventBus.getQueue().size());
    }

    public void testEventsQueuedBeforeGetGAIDCompleted() {
        // Post an event before GetGAID is completed
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("testEvent")));

        // Check that queue has one event
        assertEquals(1, TuneEventBus.getQueue().size());

        // Post a TuneGetAdvertisingIdCompleted event
        String fakeGAID = UUID.randomUUID().toString();
        boolean fakeIsLAT = true;
        TuneEventBus.post(new TuneGetAdvertisingIdCompleted(TuneGetAdvertisingIdCompleted.Type.GOOGLE_AID, fakeGAID, fakeIsLAT));

        // Check that queue has added two events for updating GAID and isLAT values
        TuneUpdateUserProfile updateGAIDEvent = (TuneUpdateUserProfile) TuneEventBus.getQueue().get(0);
        TuneUpdateUserProfile updateIsLATEvent = (TuneUpdateUserProfile) TuneEventBus.getQueue().get(1);

        assertEquals(fakeGAID, updateGAIDEvent.getVariable().getValue());
        assertEquals("1", updateIsLATEvent.getVariable().getValue());
        // Check that queue is not dequeued yet (haven't received manager initialized event)
        // and has 3 events
        assertEquals(3, TuneEventBus.getQueue().size());
    }

    public void testQueuedEventsSentAfterBothFlagsReceived() {
        // Post an event before GetGAID is completed
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("testEvent")));

        // Post both events we need to dequeue
        TuneEventBus.post(new TuneManagerInitialized());
        TuneEventBus.post(new TuneGetAdvertisingIdCompleted(TuneGetAdvertisingIdCompleted.Type.GOOGLE_AID, UUID.randomUUID().toString(), false));

        // Check that queue gets emptied
        assertEquals(0, TuneEventBus.getQueue().size());

        // Post a new event
        TuneEventBus.post(new TuneEventOccurred(new TuneEvent("testEvent2")));

        // Check that queue is never used now that we're active
        assertEquals(0, TuneEventBus.getQueue().size());
    }
}
