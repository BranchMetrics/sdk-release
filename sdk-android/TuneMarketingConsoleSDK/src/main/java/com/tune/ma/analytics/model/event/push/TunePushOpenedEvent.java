package com.tune.ma.analytics.model.event.push;

import com.tune.ma.push.model.TunePushMessage;

/**
 * Created by charlesgilliam on 2/10/16.
 */
public class TunePushOpenedEvent extends TunePushEvent {
    public TunePushOpenedEvent(TunePushMessage message) {
        super(message);

        setAction("NotificationOpened");
    }
}
