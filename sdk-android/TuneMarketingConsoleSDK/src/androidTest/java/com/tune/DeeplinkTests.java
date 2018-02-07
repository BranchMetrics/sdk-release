package com.tune;

import android.support.annotation.NonNull;

import com.tune.mocks.MockUrlRequester;

/**
 * Created by johng on 6/3/16.
 */
public class DeeplinkTests extends TuneUnitTest {

    private MockUrlRequester mockUrlRequester;

    private class WaitObject {
        private boolean receivedDeeplink;
        private boolean failedDeeplink;
        private boolean didCallback;
    }
    private WaitObject mWaitObject;

    @Override
    protected void setUp() throws Exception {
        super.setUp();

        // Pretend that we start with a fresh install
        prepareFreshInstallPreferences();

        mockUrlRequester = new MockUrlRequester();
        mockUrlRequester.setRequestUrlShouldSucceed(true);
        tune.setUrlRequester(mockUrlRequester);

        resetReceivedDeeplinkChecks();
    }

    private void resetReceivedDeeplinkChecks() {
        mWaitObject = new WaitObject();
    }

    private void prepareFreshInstallPreferences() {
        tune.setIsFirstInstall(true);
    }

    private void prepareAlreadyInstalledPreferences() {
        tune.setIsFirstInstall(false);
    }

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

    public void testDeferredDeeplinkAlreadyInstalled() {
        prepareAlreadyInstalledPreferences();

        tune.setGoogleAdvertisingId("12345678-1234-1234-1234-123412341234", false);
        tune.registerDeeplinkListener(makeDeeplinkListener());

        waitForDeeplink(TuneTestConstants.ENDPOINTTEST_SLEEP);

        // Should NOT call deferred deeplink listener.
        assertFalse(mWaitObject.didCallback);
    }

    public void testDeferredDeeplinkErrorFromServer() {
        mockUrlRequester.setRequestUrlShouldSucceed(false);

        tune.setGoogleAdvertisingId("12345678-1234-1234-1234-123412341234", false);
        tune.registerDeeplinkListener(makeDeeplinkListener());

        waitForDeeplink(TuneTestConstants.ENDPOINTTEST_SLEEP);

        assertFalse(mWaitObject.receivedDeeplink);
        assertTrue(mWaitObject.failedDeeplink);
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
