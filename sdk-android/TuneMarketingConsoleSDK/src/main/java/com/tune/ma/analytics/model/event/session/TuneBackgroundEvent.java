package com.tune.ma.analytics.model.event.session;

/**
 * Created by johng on 1/27/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneBackgroundEvent extends TuneSessionEvent {
    public TuneBackgroundEvent() {
        super();

        setAction(BACKGROUNDED);
    }
}
