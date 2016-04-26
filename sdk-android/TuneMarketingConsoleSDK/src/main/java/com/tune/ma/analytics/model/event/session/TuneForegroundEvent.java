package com.tune.ma.analytics.model.event.session;

/**
 * Created by johng on 1/27/16.
 */
public class TuneForegroundEvent extends TuneSessionEvent {
    public TuneForegroundEvent() {
        super();

        action = FOREGROUNDED;
    }
}
