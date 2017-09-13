package com.tune.ma.analytics.model.event.session;

/**
 * Created by johng on 3/23/17.
 */

public class TuneFirstPlaylistDownloadedEvent extends TuneSessionEvent {
    public TuneFirstPlaylistDownloadedEvent() {
        super();

        action = FIRST_PLAYLIST_DOWNLOADED;
    }
}
