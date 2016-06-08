package com.tune;

import java.net.HttpURLConnection;
import java.net.URL;

/**
 * Created by johng on 6/3/16.
 */
public class DeeplinkTests extends TuneUnitTest {
    public void testDeferredDeeplink() {
        final boolean[] receivedDeeplink = new boolean[1];
        final boolean[] failedDeeplink = new boolean[1];

        // Send a click in order to store a deferred deep link
        HttpURLConnection urlConnection= null;
        URL url = null;
        try {
            url = new URL("https://169564.measurementapi.com/serve?action=click&publisher_id=169564&site_id=47546&invoke_id=279835&google_aid=12345678-1234-1234-1234-123412341234");
            urlConnection = (HttpURLConnection) url.openConnection();
            urlConnection.getResponseCode();
            urlConnection.getInputStream();
        } catch (Exception e) {
        }

        // Spoof a GAID that matches the click
        tune.setGoogleAdvertisingId("12345678-1234-1234-1234-123412341234", false);

        // Try to retrieve deferred deeplink
        tune.checkForDeferredDeeplink(new TuneDeeplinkListener() {
            @Override
            public void didReceiveDeeplink(String deeplink) {
                receivedDeeplink[0] = true;
            }

            @Override
            public void didFailDeeplink(String error) {
            }
        });

        sleep(TuneTestConstants.SERVERTEST_SLEEP);

        // Check that deep link was received
        assertTrue(receivedDeeplink[0]);

        // Check that a second call fails
        tune.checkForDeferredDeeplink(new TuneDeeplinkListener() {
            @Override
            public void didReceiveDeeplink(String deeplink) {
            }

            @Override
            public void didFailDeeplink(String error) {
                failedDeeplink[0] = true;
            }
        });

        sleep(TuneTestConstants.ENDPOINTTEST_SLEEP);

        // Check that second deep link call failed
        assertTrue(failedDeeplink[0]);
    }
}
