package com.tune.ma.analytics.model.event.push;

import com.tune.ma.push.model.TunePushMessage;

/**
 * Created by charlesgilliam on 2/10/16.
 */
public class TunePushActionEvent extends TunePushEvent {
    public TunePushActionEvent(TunePushMessage message) {
        super(message);

        if (message.isOpenActionDeepAction()) {
            action = "INAPP_DEEP_ACTION";
        } else if (message.isOpenActionDeepLink()) {
            action = "INAPP_OPEN_URL";
        } else {
            action = "INAPP_NO_ACTION";
        }
    }
}