package com.tune.mocks;

import com.tune.TuneDeferredDplinkr;
import com.tune.http.UrlRequester;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by gowie on 2/8/16.
 */
public class MockUrlRequester implements UrlRequester {

    private boolean requestUrlShouldSucceed;

    public MockUrlRequester() {
        requestUrlShouldSucceed = true;
    }

    @Override
    public void requestDeeplink(TuneDeferredDplinkr dplinkr) {

    }

    @Override
    public JSONObject requestUrl(String url, JSONObject json, boolean debugMode) {
        JSONObject response = new JSONObject();

        try {
            if (requestUrlShouldSucceed) {
                response.put("success", "true");
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
}
