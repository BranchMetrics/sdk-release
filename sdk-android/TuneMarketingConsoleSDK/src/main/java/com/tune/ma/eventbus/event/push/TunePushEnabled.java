package com.tune.ma.eventbus.event.push;

/**
 * Created by Harshal Ogale on 2/10/16.
 */
public class TunePushEnabled {
    boolean enabled;

    public TunePushEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public boolean isEnabled() {
        return enabled;
    }
}
