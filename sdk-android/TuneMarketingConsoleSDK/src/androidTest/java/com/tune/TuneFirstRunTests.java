package com.tune;

import androidx.test.ext.junit.runners.AndroidJUnit4;

import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

/**
 * Test the TuneFirstRunLogic.
 * Note that default Tune initialization may (or may not) set the Advertiser Id, so we cannot test
 * sequences where that doesn't come in (or comes in out of order)
 */
@RunWith(AndroidJUnit4.class)
public class TuneFirstRunTests extends TuneUnitTest {
    @Test
    public void testFirstRunWaiting() {
        assertTrue(tune.firstRunLogic.isWaiting());
    }

    /**
     * Sequence A 1
     * 1. Advertiser Id
     * 2. Google Install Referrer (success)
     */
    @Test
    public void testSequenceA1() {
        assertTrue(tune.firstRunLogic.isWaiting());

        // Should still be waiting after the Advertising Id comes in
        tune.firstRunLogic.receivedAdvertisingId();
        assertTrue(tune.firstRunLogic.isWaiting());

        // Should be done waiting now.
        tune.firstRunLogic.googleInstallReferrerSequenceComplete();
        assertFalse(tune.firstRunLogic.isWaiting());
    }

    /**
     * Sequence A 2
     * 1. Advertiser Id
     * 2. Google Install Referrer (fail)
     */
    @Test
    public void testSequenceA2() {
        assertTrue(tune.firstRunLogic.isWaiting());

        // Should still be waiting after the Advertising Id comes in
        tune.firstRunLogic.receivedAdvertisingId();
        assertTrue(tune.firstRunLogic.isWaiting());

        // Should be done waiting even if the google sequence failed.
        tune.firstRunLogic.onInstallReferrerResponseError(TuneFirstRunLogic.InstallReferrerResponse_GeneralException);
        assertFalse(tune.firstRunLogic.isWaiting());
    }
}