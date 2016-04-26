package com.tune.ma.eventbus.event;

import com.tune.TuneEvent;

/**
 * Created by johng on 12/29/15.
 */
public class TuneEventOccurred {
    private TuneEvent event;

    public TuneEventOccurred(TuneEvent event) {
        this.event = event;
    }

    public TuneEvent getEvent() {
        return event;
    }
}
