package com.tune.ma.eventbus.event.inapp;

import com.tune.ma.inapp.model.TuneInAppMessage;

/**
 * Created by johng on 5/10/17.
 */

public class TuneInAppMessageShown {
    private TuneInAppMessage message;

    public TuneInAppMessageShown(TuneInAppMessage message) {
        this.message = message;
    }

    public TuneInAppMessage getMessage() {
        return message;
    }
}
