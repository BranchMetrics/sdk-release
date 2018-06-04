package com.tune.ma.eventbus.event.push;

/**
 * Created by Harshal Ogale on 2/10/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TunePushEnabled {
    boolean enabled;

    public TunePushEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public boolean isEnabled() {
        return enabled;
    }
}
