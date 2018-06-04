package com.tune.ma.analytics.model.event.session;

/**
 * Created by johng on 3/23/17.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneFirstPlaylistDownloadedEvent extends TuneSessionEvent {
    public TuneFirstPlaylistDownloadedEvent() {
        super();

        setAction(FIRST_PLAYLIST_DOWNLOADED);
    }
}
