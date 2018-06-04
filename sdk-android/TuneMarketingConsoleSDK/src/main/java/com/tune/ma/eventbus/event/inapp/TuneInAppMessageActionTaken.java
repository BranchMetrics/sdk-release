package com.tune.ma.eventbus.event.inapp;

import com.tune.ma.inapp.model.TuneInAppMessage;

/**
 * Created by johng on 5/17/17.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneInAppMessageActionTaken {
    private TuneInAppMessage message;
    private String action;
    private int secondsDisplayed;

    public TuneInAppMessageActionTaken(TuneInAppMessage message, String action, int secondsDisplayed) {
        this.message = message;
        this.action = action;
        this.secondsDisplayed = secondsDisplayed;
    }

    public TuneInAppMessage getMessage() {
        return message;
    }

    public String getAction() {
        return action;
    }

    public int getSecondsDisplayed() {
        return secondsDisplayed;
    }
}
