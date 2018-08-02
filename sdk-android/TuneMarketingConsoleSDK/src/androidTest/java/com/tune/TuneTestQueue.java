package com.tune;

import android.content.Context;

import org.json.JSONException;
import org.json.JSONObject;

public class TuneTestQueue extends TuneEventQueue {

    public TuneTestQueue(Context context, TuneInternal mat) {
        super(context, mat);
    }
    
    public synchronized int getQueueSize() {
        return super.getQueueSize();
    }

    public synchronized void clearQueue() {
        super.clearQueue();
    }
    
    public synchronized JSONObject getQueueItem( int index ) throws JSONException {
        String key = Integer.toString(index);
        String eventJson = getKeyFromQueue(key);
        return new JSONObject(eventJson);
    }
}
