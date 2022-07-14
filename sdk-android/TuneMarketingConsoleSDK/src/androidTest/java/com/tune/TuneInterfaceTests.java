package com.tune;

import androidx.test.ext.junit.runners.AndroidJUnit4;

import junit.framework.Assert;

import org.junit.After;
import org.junit.Test;
import org.junit.runner.RunWith;

import static androidx.test.platform.app.InstrumentationRegistry.getContext;

/**
 * Some Unit tests need to be run as if they only have access to the ITune interface, and not the
 * internals.  This test suite does not inherit from TuneUnitTest and therefore does not set up
 * tune before tests run.  It will however shut Tune down afterwards.
 */
@RunWith(AndroidJUnit4.class)
public class TuneInterfaceTests {
    @After
    public void tearDown() throws Exception {
        ITune tune = Tune.getInstance();
        if (tune instanceof TuneInternal) {
            ((TuneInternal)tune).shutDown();
        }
    }

    @Test
    public void testInitWithContext() {
        ITune tune = Tune.init(getContext(), TuneTestConstants.advertiserId, TuneTestConstants.conversionKey);
        Assert.assertNotNull(tune);
        Assert.assertNotNull(Tune.getInstance());
    }

    @Test
    public void testInitWithoutContext() {
        ITune tune = Tune.init(null, TuneTestConstants.advertiserId, TuneTestConstants.conversionKey);
        Assert.assertNull(tune);
        Assert.assertNull(Tune.getInstance());
    }
}
