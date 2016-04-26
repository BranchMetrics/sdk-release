package com.tune.ma.eventbus.event.push;

import com.tune.ma.push.model.TunePushMessage;

/**
 * Created by charlesgilliam on 2/10/16.
 */
public class TunePushOpened {
    TunePushMessage message;

    public TunePushOpened(TunePushMessage message) {
        this.message = message;
    }

    public TunePushMessage getMessage() {
        return message;
    }
}
