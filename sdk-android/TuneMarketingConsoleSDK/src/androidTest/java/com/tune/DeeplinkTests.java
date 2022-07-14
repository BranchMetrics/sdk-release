package com.tune;

import androidx.annotation.NonNull;
import androidx.test.ext.junit.runners.AndroidJUnit4;

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

    private final class WaitObject {
        private boolean receivedDeeplink;
        private boolean failedDeeplink;
        private boolean didCallback;
    }

    @Before
    public void setUp() throws Exception {
        super.setUp();

        // Pretend that we start with a fresh install
        prepareFreshInstallPreferences();

        mockUrlRequester = new MockUrlRequester();
        mockUrlRequester.setRequestUrlShouldSucceed(true);
        tune.setUrlRequester(mockUrlRequester);
    }

    private void prepareFreshInstallPreferences() {
        tune.setIsFirstInstall(true);
    }

    private void prepareAlreadyInstalledPreferences() {
        tune.setIsFirstInstall(false);
    }

    @Test
    public void testDeferredDeeplinkSuccess() {
        final WaitObject waitObject = new WaitObject();
        tune.setGoogleAdvertisingId("12345678-1234-1234-1234-123412341234", false);

        tune.registerDeeplinkListener(makeDeeplinkListener(waitObject));
        waitForDeeplink(waitObject, TuneTestConstants.ENDPOINTTEST_SLEEP);

        assertFalse(waitObject.failedDeeplink);
        assertTrue(waitObject.receivedDeeplink);

        // Reset the WaitObject
        resetReceivedDeeplinkChecks(waitObject);

        tune.registerDeeplinkListener(makeDeeplinkListener(waitObject));
        waitForDeeplink(waitObject, TuneTestConstants.ENDPOINTTEST_SLEEP);

        // Should NOT get a failed deeplink response after registering again.
        assertFalse(waitObject.didCallback);
    }

    @Test
    public void testDeferredDeeplinkAlreadyInstalled() {
        final WaitObject waitObject = new WaitObject();
        prepareAlreadyInstalledPreferences();

        tune.setGoogleAdvertisingId("12345678-1234-1234-1234-123412341234", false);

        tune.registerDeeplinkListener(makeDeeplinkListener(waitObject));
        waitForDeeplink(waitObject, TuneTestConstants.ENDPOINTTEST_SLEEP);

        // Should NOT call deferred deeplink listener.
        assertFalse(waitObject.didCallback);
    }

    @Test
    public void testDeferredDeeplinkErrorFromServer() {
        final WaitObject waitObject = new WaitObject();
        mockUrlRequester.setRequestUrlShouldSucceed(false);

        tune.setGoogleAdvertisingId("12345678-1234-1234-1234-123412341234", false);

        tune.registerDeeplinkListener(makeDeeplinkListener(waitObject));
        waitForDeeplink(waitObject, TuneTestConstants.ENDPOINTTEST_SLEEP);

        assertFalse(waitObject.receivedDeeplink);
        assertTrue(waitObject.failedDeeplink);
    }

    @Test
    public void testDeferredDeeplinkDoesntGetRequestedWithoutDeviceIdentifier() {
        final WaitObject waitObject = new WaitObject();

        // Initial Sleep to make sure that the sdk is in a stable state
        sleep(TuneTestConstants.ENDPOINTTEST_SLEEP);

        // Mock that the SDK has not received a GAID or ANDROID_ID yet
        tune.setGoogleAdvertisingId(null, false);
        tune.registerDeeplinkListener(makeDeeplinkListener(waitObject));

        // Neither success nor failure should be called, no request went out since criteria was not fulfilled,
        // no valid device identifier was received yet
        assertFalse(waitObject.receivedDeeplink);
        assertFalse(waitObject.failedDeeplink);

        // Mock that the SDK finished receiving a GAID - this should kick off the deferred deeplink request
        tune.setGoogleAdvertisingId("12345678-1234-1234-1234-123412341234", false);

        waitForDeeplink(waitObject, TuneTestConstants.ENDPOINTTEST_SLEEP);

        // Check that deferred deeplink request succeeded
        assertTrue(waitObject.receivedDeeplink);
        assertFalse(waitObject.failedDeeplink);
    }

    private void resetReceivedDeeplinkChecks(final WaitObject waitObject) {
        waitObject.receivedDeeplink = false;
        waitObject.failedDeeplink = false;
        waitObject.didCallback = false;
    }

    private void waitForDeeplink(final WaitObject waitObject, long timeout) {
        synchronized (waitObject) {
            try {
                waitObject.wait(timeout);
            } catch (InterruptedException e) {
            }
        }
    }

    @NonNull
    private TuneDeeplinkListener makeDeeplinkListener(final WaitObject waitObject) {
        return new TuneDeeplinkListener() {
            @Override
            public void didReceiveDeeplink(String deeplink) {
                synchronized (waitObject) {
                    waitObject.receivedDeeplink = true;
                    waitObject.didCallback = true;
                    waitObject.notify();
                }
            }

            @Override
            public void didFailDeeplink(String error) {
                synchronized (waitObject) {
                    waitObject.failedDeeplink = true;
                    waitObject.didCallback = true;
                    waitObject.notify();
                }
            }
        };
    }
}
