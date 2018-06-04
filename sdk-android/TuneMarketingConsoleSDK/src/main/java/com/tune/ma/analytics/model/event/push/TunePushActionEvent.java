package com.tune.ma.analytics.model.event.push;

import com.tune.ma.push.model.TunePushMessage;

/**
 * Created by charlesgilliam on 2/10/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TunePushActionEvent extends TunePushEvent {
    public TunePushActionEvent(TunePushMessage message) {
        super(message);

        if (message.isOpenActionDeepAction()) {
            setAction("INAPP_DEEP_ACTION");
        } else if (message.isOpenActionDeepLink()) {
            setAction("INAPP_OPEN_URL");
        } else {
            setAction("INAPP_NO_ACTION");
        }
    }
}