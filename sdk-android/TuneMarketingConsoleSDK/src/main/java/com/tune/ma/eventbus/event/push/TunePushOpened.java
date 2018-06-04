package com.tune.ma.eventbus.event.push;

import com.tune.ma.push.model.TunePushMessage;

/**
 * Created by charlesgilliam on 2/10/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TunePushOpened {
    TunePushMessage message;

    public TunePushOpened(TunePushMessage message) {
        this.message = message;
    }

    public TunePushMessage getMessage() {
        return message;
    }
}
