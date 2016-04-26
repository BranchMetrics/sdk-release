package com.tune.http;

import com.tune.TuneDeferredDplinkr;

import org.json.JSONObject;

/**
 * Created by gowie on 2/8/16.
 */
public interface UrlRequester {


    void requestDeeplink(TuneDeferredDplinkr dplinkr);

    JSONObject requestUrl(String url, JSONObject json, boolean debugMode);

}
