package com.tune;

import androidx.test.ext.junit.runners.AndroidJUnit4;

import com.tune.mocks.MockUrlRequester;

import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

/**
 * Created by audrey on 10/26/16.
 */
@RunWith(AndroidJUnit4.class)
public class TuneMakeRequestTests extends TuneUnitTest {

    private MockUrlRequester mockUrlRequester;
    private final String[] receivedDeeplink = new String[1];
    private final String[] failedDeeplink = new String[1];

    @Before
    public void setUp() throws Exception {
        super.setUp();

        resetReceivedDeeplinkChecks();

        mockUrlRequester = new MockUrlRequester();
        mockUrlRequester.setRequestUrlShouldSucceed(true);
        mockUrlRequester.clearFakeResponse();
        tune.setUrlRequester(mockUrlRequester);
        tune.registerDeeplinkListener(new TuneDeeplinkListener() {
            @Override
            public void didReceiveDeeplink(String deeplink) {
                receivedDeeplink[0] = deeplink;
            }

            @Override
            public void didFailDeeplink(String error) {
                failedDeeplink[0] = error;
            }
        });
        sleep(TuneTestConstants.PARAMTEST_SLEEP);
        resetReceivedDeeplinkChecks(); // clear out responses from initial register listener callbacks
    }

    private void resetReceivedDeeplinkChecks() {
        receivedDeeplink[0] = null;
        failedDeeplink[0] = null;
    }

    @Test
    public void testMakeRequestForTuneLinkMeasurementCallsListenerIfInvokeUrlReceived() throws Exception {
        final String expectedInvokeUrl = "myapp://fakefake?isFake=yes";
        mockUrlRequester.includeInFakeResponse(TuneConstants.KEY_INVOKE_URL, expectedInvokeUrl);

        JSONObject postBody = new JSONObject();
        tune.makeRequest("https://12345.tlnk.io/392842hsef?action=click&response_format=json&debug=13&adv=00000&site_id=00000&pub=00000&user_id=endpoints", "", postBody);

        assertEquals(expectedInvokeUrl, receivedDeeplink[0]);
        assertNull(failedDeeplink[0]);
    }

    @Test
    public void testMakeRequestForTuneLinkMeasurementCallsListenerIfNoInvokeUrlReturned() throws Exception {
        mockUrlRequester.clearFakeResponse();

        JSONObject postBody = new JSONObject();
        tune.makeRequest("https://12345.tlnk.io/3298jdskefj84?action=click&response_format=json&debug=13&adv=00000&site_id=00000&pub=00000&user_id=endpoints", "", postBody);

        assertNull(receivedDeeplink[0]);
        assertEquals("There is no invoke url for this Tune Link", failedDeeplink[0]);
    }

    @Test
    public void testMakeRequestWithNullLink() {
        mockUrlRequester.clearFakeResponse();

        boolean gotException = false;

        try {
            tune.makeRequest(null, null, null);
        } catch (Exception e) {
            gotException = true;
        }

        assertFalse(gotException);
    }

    @Test
    public void testMakeRequestInvokesRequestUrlCallback() {
        mockUrlRequester.clearFakeResponse();

        tune.setListener(new ITuneListener() {
            @Override
            public void enqueuedRequest(String url, JSONObject postData) {
                assertTrue(url.startsWith("https://some.url"));
                assertTrue(url.contains("&data="));
                // URL in callback should not have unencrypted data
                assertFalse(url.contains("encrypted_data"));
                assertTrue(postData.toString().equals("{\"key\":\"value\"}"));
            }

            @Override
            public void didSucceedWithData(String url, JSONObject data) {

            }

            @Override
            public void didFailWithError(String url, JSONObject error) {

            }
        });

        try {
            JSONObject postBody = new JSONObject("{\"key\":\"value\"}");
            tune.makeRequest("https://some.url", "encrypted_data", postBody);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
}
