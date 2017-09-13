package com.tune.ma.eventbus.event;

/**
 * Created by johng on 5/2/17.
 */

public class TuneDeeplinkOpened {
    private String deeplinkUrl;

    public TuneDeeplinkOpened(String deeplinkUrl) {
        this.deeplinkUrl = deeplinkUrl;
    }

    public String getDeeplinkUrl() {
        return deeplinkUrl;
    }
}
