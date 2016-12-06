package com.tune;

import android.support.annotation.NonNull;

import com.tune.mocks.MockUrlRequester;

/**
 * Created by johng on 6/3/16.
 */
public class DeeplinkTests extends TuneUnitTest {

    private MockUrlRequester mockUrlRequester;
    private final boolean[] receivedDeeplink = new boolean[1];
    private final boolean[] failedDeeplink = new boolean[1];

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
        receivedDeeplink[0] = false;
        failedDeeplink[0] = false;
    }

    private void prepareFreshInstallPreferences() {
        tune.setIsFirstInstall(true);
    }

    private void prepareAlreadyInstalledPreferences() {
        tune.setIsFirstInstall(false);
    }

    public void testDeferredDeeplinkLegacy() {
        tune.setGoogleAdvertisingId("12345678-1234-1234-1234-123412341234", false);

        tune.checkForDeferredDeeplink(makeDeeplinkListener(receivedDeeplink, failedDeeplink));
        sleep(TuneTestConstants.ENDPOINTTEST_SLEEP);

        // Check that deep link was received
        assertFalse(failedDeeplink[0]);
        assertTrue(receivedDeeplink[0]);
        resetReceivedDeeplinkChecks();

        tune.checkForDeferredDeeplink(makeDeeplinkListener(receivedDeeplink, failedDeeplink));
        sleep(TuneTestConstants.ENDPOINTTEST_SLEEP);

        // Should not request deeplink twice, but also should not get error
        assertFalse(failedDeeplink[0]);
        assertFalse(receivedDeeplink[0]);
    }

    public void testDeferredDeeplinkSuccess() {
        tune.setGoogleAdvertisingId("12345678-1234-1234-1234-123412341234", false);

        tune.registerDeeplinkListener(makeDeeplinkListener(receivedDeeplink, failedDeeplink));
        sleep(TuneTestConstants.ENDPOINTTEST_SLEEP);

        assertFalse(failedDeeplink[0]);
        assertTrue(receivedDeeplink[0]);
        resetReceivedDeeplinkChecks();

        tune.registerDeeplinkListener(makeDeeplinkListener(receivedDeeplink, failedDeeplink));
        sleep(TuneTestConstants.ENDPOINTTEST_SLEEP);

        // Should NOT get a failed deeplink response after registering again.
        assertFalse(receivedDeeplink[0]);
        assertFalse(failedDeeplink[0]);
    }

    public void testDeferredDeeplinkAlreadyInstalled() {
        prepareAlreadyInstalledPreferences();

        tune.setGoogleAdvertisingId("12345678-1234-1234-1234-123412341234", false);
        tune.registerDeeplinkListener(makeDeeplinkListener(receivedDeeplink, failedDeeplink));

        sleep(TuneTestConstants.ENDPOINTTEST_SLEEP);

        // Should NOT call deferred deeplink listener.
        assertFalse(receivedDeeplink[0]);
        assertFalse(failedDeeplink[0]);
    }

    public void testDeferredDeeplinkErrorFromServer() {
        mockUrlRequester.setRequestUrlShouldSucceed(false);

        tune.setGoogleAdvertisingId("12345678-1234-1234-1234-123412341234", false);
        tune.registerDeeplinkListener(makeDeeplinkListener(receivedDeeplink, failedDeeplink));

        sleep(TuneTestConstants.ENDPOINTTEST_SLEEP);

        assertFalse(receivedDeeplink[0]);
        assertTrue(failedDeeplink[0]);
    }

    @NonNull
    private TuneDeeplinkListener makeDeeplinkListener(final boolean[] receivedDeeplink, final boolean[] failedDeeplink) {
        return new TuneDeeplinkListener() {
            @Override
            public void didReceiveDeeplink(String deeplink) {
                receivedDeeplink[0] = true;
            }

            @Override
            public void didFailDeeplink(String error) {
                failedDeeplink[0] = true;
            }
        };
    }
}
