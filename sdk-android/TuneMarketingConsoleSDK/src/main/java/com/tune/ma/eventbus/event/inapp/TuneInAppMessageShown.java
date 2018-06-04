package com.tune.ma.eventbus.event.inapp;

import com.tune.ma.inapp.model.TuneInAppMessage;

/**
 * Created by johng on 5/10/17.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneInAppMessageShown {
    private TuneInAppMessage message;

    public TuneInAppMessageShown(TuneInAppMessage message) {
        this.message = message;
    }

    public TuneInAppMessage getMessage() {
        return message;
    }
}
