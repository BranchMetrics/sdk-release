package com.tune;

import com.tune.mocks.MockUrlRequester;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by audrey on 10/26/16.
 */

public class TuneMakeRequestTests extends TuneUnitTest {

    private MockUrlRequester mockUrlRequester;
    private final String[] receivedDeeplink = new String[1];
    private final String[] failedDeeplink = new String[1];

    @Override
    protected void setUp() throws Exception {
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

    public void testMakeRequestForTuneLinkMeasurementCallsListenerIfInvokeUrlReceived() throws Exception {
        final String expectedInvokeUrl = "myapp://fakefake?isFake=yes";
        mockUrlRequester.includeInFakeResponse(TuneConstants.KEY_INVOKE_URL, expectedInvokeUrl);

        JSONObject postBody = new JSONObject();
        tune.makeRequest("https://12345.tlnk.io/392842hsef?action=click&response_format=json&debug=13&adv=00000&site_id=00000&pub=00000&user_id=endpoints", "", postBody);

        assertEquals(expectedInvokeUrl, receivedDeeplink[0]);
        assertNull(failedDeeplink[0]);
    }

    public void testMakeRequestForTuneLinkMeasurementCallsListenerIfNoInvokeUrlReturned() throws Exception {
        mockUrlRequester.clearFakeResponse();

        JSONObject postBody = new JSONObject();
        tune.makeRequest("https://12345.tlnk.io/3298jdskefj84?action=click&response_format=json&debug=13&adv=00000&site_id=00000&pub=00000&user_id=endpoints", "", postBody);

        assertNull(receivedDeeplink[0]);
        assertEquals("There is no invoke url for this Tune Link", failedDeeplink[0]);
    }

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

    public void testMakeRequestInvokesRequestUrlCallback() {
        mockUrlRequester.clearFakeResponse();

        tune.setListener(new TuneListener() {
            @Override
            public void enqueuedActionWithRefId(String refId) {

            }

            @Override
            public void enqueuedRequest(String url, JSONObject postData) {
                assertTrue(url.startsWith("https://some.url"));
                assertTrue(url.contains("&data="));
                // URL in callback should not have unencrypted data
                assertFalse(url.contains("encrypted_data"));
                assertTrue(postData.toString().equals("{\"key\":\"value\"}"));
            }

            @Override
            public void didSucceedWithData(JSONObject data) {

            }

            @Override
            public void didFailWithError(JSONObject error) {

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
