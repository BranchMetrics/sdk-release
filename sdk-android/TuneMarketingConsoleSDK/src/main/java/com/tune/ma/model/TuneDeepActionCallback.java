package com.tune.ma.model;

import android.app.Activity;

import java.util.Map;

/**
 * Created by willb on 2/1/16.
 */
public interface TuneDeepActionCallback {

    void execute(Activity activity, Map<String, String> extraData);

}
