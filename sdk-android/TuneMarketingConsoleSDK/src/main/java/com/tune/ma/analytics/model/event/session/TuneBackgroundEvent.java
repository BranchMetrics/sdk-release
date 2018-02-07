package com.tune.ma.analytics.model.event.session;

/**
 * Created by johng on 1/27/16.
 */
public class TuneBackgroundEvent extends TuneSessionEvent {
    public TuneBackgroundEvent() {
        super();

        setAction(BACKGROUNDED);
    }
}
