package com.tune.ma.model;

import com.tune.ma.TuneManager;
import com.tune.ma.playlist.TunePlaylistManager;
import com.tune.ma.session.TuneSessionManager;

import java.util.Timer;
import java.util.TimerTask;

/**
 * Created by gowie on 1/28/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneCallbackHolder {

    private TuneCallback callback;
    private long timeInMillis;
    private Timer timer;
    private Object lock;
    private boolean timerActive;
    private boolean canceled;

    public TuneCallbackHolder(TuneCallback callback) {
        this.callback = callback;
        this.lock = new Object();
        this.timerActive = false;
        this.canceled = false;
    }

    public boolean isCanceled() {
        return canceled;
    }

    public long getTimeout() {
        return this.timeInMillis;
    }

    public void setTimeout(long timeInMillis) {
        this.timeInMillis = timeInMillis;
        this.canceled = false;
        timer = new Timer(true);
        timerActive = true;
        timer.schedule(new TimerTask() {

            @Override
            public void run() {
                synchronized (lock) {
                    timerActive = false;
                }
                execute();
            }
        }, this.timeInMillis);
    }

    public void stopTimer() {
        synchronized (lock) {
            if (timer != null) {
                if (timerActive) {
                    timerActive = false; // timer could still fire, invalidate to stop
                    this.timer.cancel();
                    canceled = true;
                }
                timer = null;
            }
        }
    }

    public void executeBlock() {
        synchronized (lock) {
            this.canceled = false;
            if (timer != null) {
                if (timerActive) {
                    timerActive = false; // timer could still fire, invalidate to stop
                    this.timer.cancel();
                }

                timer = null;
            }
            
            execute();
        }
    }

    private void execute() {
        if (callback != null && TuneManager.getInstance() != null) {
            TunePlaylistManager playlistManager = TuneManager.getInstance().getPlaylistManager();
            TuneSessionManager sessionManager = TuneManager.getInstance().getSessionManager();

            // Only execute callback and mark as executed if app is in foreground
            if (playlistManager != null && !playlistManager.hasFirstPlaylistCallbackExecuted()) {
                if (sessionManager != null && sessionManager.hasActivityVisible()){
                    playlistManager.setFirstPlaylistCallbackExecuted(true);
                    callback.execute();
                } else {
                    canceled = true;
                }
            }
        }
    }
}
