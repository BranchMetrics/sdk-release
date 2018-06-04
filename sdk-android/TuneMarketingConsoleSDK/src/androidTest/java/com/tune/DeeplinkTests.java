package com.tune;

import android.support.annotation.NonNull;
import android.support.test.runner.AndroidJUnit4;

import com.tune.mocks.MockUrlRequester;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

/**
 * Created by johng on 6/3/16.
 */
@RunWith(AndroidJUnit4.class)
public class DeeplinkTests extends TuneUnitTest {

    private MockUrlRequester mockUrlRequester;

    private class WaitObject {
        private boolean receivedDeeplink;
        private boolean failedDeeplink;
        private boolean didCallback;
    }
    private final WaitObject mWaitObject = new WaitObject();

    @Before
    public void setUp() throws Exception {
        super.setUp();

        // Pretend that we start with a fresh install
        prepareFreshInstallPreferences();

        mockUrlRequester = new MockUrlRequester();
        mockUrlRequester.setRequestUrlShouldSucceed(true);
        tune.setUrlRequester(mockUrlRequester);

        resetReceivedDeeplinkChecks();
    }

    private void resetReceivedDeeplinkChecks() {
        mWaitObject.receivedDeeplink = false;
        mWaitObject.failedDeeplink = false;
        mWaitObject.didCallback = false;
    }

    private void prepareFreshInstallPreferences() {
        tune.setIsFirstInstall(true);
    }

    private void prepareAlreadyInstalledPreferences() {
        tune.setIsFirstInstall(false);
    }

    @Test
    public void testDeferredDeeplinkSuccess() {
        tune.setGoogleAdvertisingId("12345678-1234-1234-1234-123412341234", false);

        tune.registerDeeplinkListener(makeDeeplinkListener());
        waitForDeeplink(TuneTestConstants.ENDPOINTTEST_SLEEP);

        assertFalse(mWaitObject.failedDeeplink);
        assertTrue(mWaitObject.receivedDeeplink);
        resetReceivedDeeplinkChecks();

        tune.registerDeeplinkListener(makeDeeplinkListener());
        waitForDeeplink(TuneTestConstants.ENDPOINTTEST_SLEEP);

        // Should NOT get a failed deeplink response after registering again.
        assertFalse(mWaitObject.didCallback);
    }

    @Test
    public void testDeferredDeeplinkAlreadyInstalled() {
        prepareAlreadyInstalledPreferences();

        tune.setGoogleAdvertisingId("12345678-1234-1234-1234-123412341234", false);
        tune.registerDeeplinkListener(makeDeeplinkListener());

        waitForDeeplink(TuneTestConstants.ENDPOINTTEST_SLEEP);

        // Should NOT call deferred deeplink listener.
        assertFalse(mWaitObject.didCallback);
    }

    @Test
    public void testDeferredDeeplinkErrorFromServer() {
        mockUrlRequester.setRequestUrlShouldSucceed(false);

        tune.setGoogleAdvertisingId("12345678-1234-1234-1234-123412341234", false);
        tune.registerDeeplinkListener(makeDeeplinkListener());

        waitForDeeplink(TuneTestConstants.ENDPOINTTEST_SLEEP);

        assertFalse(mWaitObject.receivedDeeplink);
        assertTrue(mWaitObject.failedDeeplink);
    }

    @Test
    public void testDeferredDeeplinkDoesntGetRequestedWithoutDeviceIdentifier() {
        // Initial Sleep to make sure that the sdk is in a stable state
        sleep(TuneTestConstants.ENDPOINTTEST_SLEEP);

        // Mock that the SDK has not received a GAID or ANDROID_ID yet
        tune.setGoogleAdvertisingId(null, false);
        tune.registerDeeplinkListener(makeDeeplinkListener());

        // Neither success nor failure should be called, no request went out since criteria was not fulfilled,
        // no valid device identifier was received yet
        assertFalse(mWaitObject.receivedDeeplink);
        assertFalse(mWaitObject.failedDeeplink);

        // Mock that the SDK finished receiving a GAID - this should kick off the deferred deeplink request
        tune.setGoogleAdvertisingId("12345678-1234-1234-1234-123412341234", false);

        waitForDeeplink(TuneTestConstants.ENDPOINTTEST_SLEEP);

        // Check that deferred deeplink request succeeded
        assertTrue(mWaitObject.receivedDeeplink);
        assertFalse(mWaitObject.failedDeeplink);
    }

    private void waitForDeeplink(long timeout) {
        synchronized (mWaitObject) {
            try {
                mWaitObject.wait(timeout);
            } catch (InterruptedException e) {
            }
        }
    }

    @NonNull
    private TuneDeeplinkListener makeDeeplinkListener() {
        return new TuneDeeplinkListener() {
            @Override
            public void didReceiveDeeplink(String deeplink) {
                synchronized (mWaitObject) {
                    mWaitObject.receivedDeeplink = true;
                    mWaitObject.didCallback = true;
                    mWaitObject.notify();
                }
            }

            @Override
            public void didFailDeeplink(String error) {
                synchronized (mWaitObject) {
                    mWaitObject.failedDeeplink = true;
                    mWaitObject.didCallback = true;
                    mWaitObject.notify();
                }
            }
        };
    }
}
