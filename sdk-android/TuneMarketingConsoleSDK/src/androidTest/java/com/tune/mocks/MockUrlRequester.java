package com.tune.mocks;

import com.tune.TuneConstants;
import com.tune.TuneDeeplinkListener;
import com.tune.http.UrlRequester;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by gowie on 2/8/16.
 */
public class MockUrlRequester implements UrlRequester {

    private boolean requestUrlShouldSucceed;
    private JSONObject fakeResponse = new JSONObject();

    public MockUrlRequester() {
        requestUrlShouldSucceed = true;
    }

    @Override
    public void requestDeeplink(String deeplinkURL, String conversionKey, TuneDeeplinkListener listener) {
        if (listener != null) {
            if (requestUrlShouldSucceed) {
                // Notify listener of deeplink url
                listener.didReceiveDeeplink("testing://allthethings?success=yes");
            } else {
                // Notify listener of error
                listener.didFailDeeplink("Deeplink not found");
            }
        }
    }

    @Override
    public JSONObject requestUrl(String url, JSONObject json, boolean debugMode) {
        JSONObject response = fakeResponse;

        try {
            if (requestUrlShouldSucceed) {
                response.put(TuneConstants.SERVER_RESPONSE_SUCCESS, true);
            } else {
                response.put("error", "error");
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }

        return response;
    }

    public void setRequestUrlShouldSucceed(boolean requestUrlShouldSucceed) {
        this.requestUrlShouldSucceed = requestUrlShouldSucceed;
    }

    public void includeInFakeResponse(String key, String value) throws Exception {
        fakeResponse.put(key, value);
    }

    public void clearFakeResponse() {
        this.fakeResponse = new JSONObject();
    }
}
