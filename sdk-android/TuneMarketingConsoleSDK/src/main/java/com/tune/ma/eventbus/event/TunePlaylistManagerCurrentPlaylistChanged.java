package com.tune.ma.eventbus.event;

import com.tune.ma.playlist.model.TunePlaylist;

/**
 * Created by gowie on 1/28/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TunePlaylistManagerCurrentPlaylistChanged {

    private TunePlaylist newPlaylist;

    public TunePlaylistManagerCurrentPlaylistChanged(TunePlaylist newPlaylist) {
        this.newPlaylist = newPlaylist;
    }

    public TunePlaylist getNewPlaylist() {
        return newPlaylist;
    }
}
