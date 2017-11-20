package com.tune;

import android.test.AndroidTestCase;

import com.tune.ma.TuneManager;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneGetAdvertisingIdCompleted;

import org.greenrobot.eventbus.Subscribe;

import java.util.UUID;

/**
 * Created by johng on 1/21/16.
 */
public class TurnOnTMATests extends AndroidTestCase {
    private static final boolean TURN_ON_TMA = true;
    private static final boolean TURN_OFF_TMA = false;

    private Tune tune;
    private boolean eventReceived;

    public class TuneTestEvent {
    }

    @Subscribe
    public void onEvent(TuneTestEvent event) {
        eventReceived = true;
    }

    @Override
    public void setUp() {
        eventReceived = false;
    }

    @Override
    public void tearDown() {
        TuneEventBus.unregister(this);
    }

    // Test that TuneManager is init when turnOnTMA is true
    public void testTuneManagerInit() {
        tune = Tune.init(getContext(), TuneTestConstants.advertiserId, TuneTestConstants.conversionKey, TURN_ON_TMA, null);
        TuneEventBus.register(this);
        assertNotNull(TuneManager.getInstance());
        tune.shutDown();
    }

    // Test that TuneEventBus can post and receive when turnOnTMA is true
    public void testEventBusEnabled() {
        tune = Tune.init(getContext(), TuneTestConstants.advertiserId, TuneTestConstants.conversionKey, TURN_ON_TMA, null);
        TuneEventBus.post(new TuneGetAdvertisingIdCompleted(TuneGetAdvertisingIdCompleted.Type.GOOGLE_AID, UUID.randomUUID().toString(), false));
        TuneEventBus.register(this);
        TuneEventBus.post(new TuneTestEvent());
        assertTrue(eventReceived);
        tune.shutDown();
    }

    // Test that TuneEventBus is disabled when turnOnTMA is false
    public void testEventBusDisabled() {
        tune = Tune.init(getContext(), TuneTestConstants.advertiserId, TuneTestConstants.conversionKey, TURN_OFF_TMA, null);
        TuneEventBus.register(this);
        TuneEventBus.post(new TuneTestEvent());
        assertFalse(eventReceived);
        tune.shutDown();
    }
}
