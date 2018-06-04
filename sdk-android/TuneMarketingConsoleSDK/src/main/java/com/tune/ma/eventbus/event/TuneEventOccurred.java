package com.tune.ma.eventbus.event;

import com.tune.TuneEvent;

/**
 * Created by johng on 12/29/15.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneEventOccurred {
    private TuneEvent event;

    public TuneEventOccurred(TuneEvent event) {
        this.event = event;
    }

    public TuneEvent getEvent() {
        return event;
    }
}
