package com.tune.ma.eventbus.event;

import com.tune.ma.playlist.model.TunePlaylist;

/**
 * Created by gowie on 1/28/16.
 */
public class TunePlaylistManagerCurrentPlaylistChanged {

    private TunePlaylist newPlaylist;

    public TunePlaylistManagerCurrentPlaylistChanged(TunePlaylist newPlaylist) {
        this.newPlaylist = newPlaylist;
    }

    public TunePlaylist getNewPlaylist() {
        return newPlaylist;
    }
}
