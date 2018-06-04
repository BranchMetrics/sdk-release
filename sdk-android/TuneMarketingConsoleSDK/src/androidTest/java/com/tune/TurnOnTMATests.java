package com.tune;

import android.support.test.runner.AndroidJUnit4;

import com.tune.ma.TuneManager;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneGetAdvertisingIdCompleted;

import org.greenrobot.eventbus.Subscribe;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.UUID;

import static android.support.test.InstrumentationRegistry.getContext;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

/**
 * Created by johng on 1/21/16.
 */
@RunWith(AndroidJUnit4.class)
public class TurnOnTMATests {
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

    @Before
    public void setUp() {
        eventReceived = false;
    }

    @After
    public void tearDown() {
        TuneEventBus.unregister(this);
        if (tune != null) {
            tune.shutDown();
        }
    }

    // Test that TuneManager is init when turnOnTMA is true
    @Test
    public void testTuneManagerInit() {
        tune = Tune.init(getContext(), TuneTestConstants.advertiserId, TuneTestConstants.conversionKey, TURN_ON_TMA, null);
        TuneEventBus.register(this);
        assertNotNull(TuneManager.getInstance());
    }

    // Test that TuneEventBus can post and receive when turnOnTMA is true
    @Test
    public void testEventBusEnabled() {
        tune = Tune.init(getContext(), TuneTestConstants.advertiserId, TuneTestConstants.conversionKey, TURN_ON_TMA, null);
        TuneEventBus.post(new TuneGetAdvertisingIdCompleted(TuneGetAdvertisingIdCompleted.Type.GOOGLE_AID, UUID.randomUUID().toString(), false));
        TuneEventBus.register(this);
        TuneEventBus.post(new TuneTestEvent());
        assertTrue(eventReceived);
    }

    // Test that TuneEventBus is disabled when turnOnTMA is false
    @Test
    public void testEventBusDisabled() {
        tune = Tune.init(getContext(), TuneTestConstants.advertiserId, TuneTestConstants.conversionKey, TURN_OFF_TMA, null);
        TuneEventBus.register(this);
        TuneEventBus.post(new TuneTestEvent());
        assertFalse(eventReceived);
    }

    @Test
    public void testGetIAMAppIDWhenIAMNotEnabled() {
        tune = Tune.init(getContext(), TuneTestConstants.advertiserId, TuneTestConstants.conversionKey, TURN_OFF_TMA, null);
        assertNull(tune.getIAMAppId());
    }

    @Test
    public void testGetIAMDeviceIDWhenIAMNotEnabled() {
        tune = Tune.init(getContext(), TuneTestConstants.advertiserId, TuneTestConstants.conversionKey, TURN_OFF_TMA, null);
        assertNull(tune.getIAMDeviceId());
    }

    @Test
    public void testGetIAMAppIDWhenIAMEnabled() {
        tune = Tune.init(getContext(), TuneTestConstants.advertiserId, TuneTestConstants.conversionKey, TURN_ON_TMA, null);
        assertNotNull(tune.getIAMAppId());
    }

    @Test
    public void testGetIAMDeviceIDWhenIAMEnabled() {
        tune = Tune.init(getContext(), TuneTestConstants.advertiserId, TuneTestConstants.conversionKey, TURN_ON_TMA, null);
        assertNotNull(tune.getIAMDeviceId());
    }

}
