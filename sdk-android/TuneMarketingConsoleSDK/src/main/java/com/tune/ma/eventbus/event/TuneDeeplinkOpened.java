package com.tune.ma.eventbus.event;

/**
 * Created by johng on 5/2/17.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneDeeplinkOpened {
    private String deeplinkUrl;

    public TuneDeeplinkOpened(String deeplinkUrl) {
        this.deeplinkUrl = deeplinkUrl;
    }

    public String getDeeplinkUrl() {
        return deeplinkUrl;
    }
}
