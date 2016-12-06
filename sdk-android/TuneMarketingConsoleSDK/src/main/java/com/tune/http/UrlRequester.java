package com.tune.http;

import com.tune.TuneDeeplinkListener;
import com.tune.TuneDeeplinker;

import org.json.JSONObject;

/**
 * Created by gowie on 2/8/16.
 */
public interface UrlRequester {

    void requestDeeplink(String deeplinkURL, String conversionKey, TuneDeeplinkListener listener);

    JSONObject requestUrl(String url, JSONObject json, boolean debugMode);

}
