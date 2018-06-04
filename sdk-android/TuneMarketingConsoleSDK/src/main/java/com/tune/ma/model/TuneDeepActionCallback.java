package com.tune.ma.model;

import android.app.Activity;

import java.util.Map;

/**
 * Created by willb on 2/1/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public interface TuneDeepActionCallback {

    void execute(Activity activity, Map<String, String> extraData);

}
