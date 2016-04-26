package com.tune;

import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;

public class TuneTestQueue extends TuneEventQueue {

    public TuneTestQueue(Context context, Tune mat) {
        super(context, mat);
    }
    
    public synchronized int getQueueSize() {
        return super.getQueueSize();
    }

    public synchronized void clearQueue() {
        for (int i = getQueueSize(); i > 0; i--) {
            removeKeyFromQueue(Integer.toString(i));
        }
    }
    
    public synchronized JSONObject getQueueItem( int index ) throws JSONException {
        String key = Integer.toString(index);
        String eventJson = getKeyFromQueue(key);
        return new JSONObject(eventJson);
    }
}
