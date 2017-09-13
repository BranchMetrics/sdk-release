package com.tune.ma.eventbus.event.inapp;

import com.tune.ma.inapp.model.TuneInAppMessage;

/**
 * Created by johng on 5/26/17.
 */

public class TuneInAppMessageUnspecifiedActionTaken {
    private TuneInAppMessage message;
    private String unspecifiedActionName;
    private int secondsDisplayed;

    public TuneInAppMessageUnspecifiedActionTaken(TuneInAppMessage message, String unspecifiedAction, int secondsDisplayed) {
        this.message = message;
        this.unspecifiedActionName = unspecifiedAction;
        this.secondsDisplayed = secondsDisplayed;
    }

    public TuneInAppMessage getMessage() {
        return message;
    }

    public int getSecondsDisplayed() {
        return secondsDisplayed;
    }

    public String getUnspecifiedActionName() {
        return unspecifiedActionName;
    }
}
