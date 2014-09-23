package com.mobileapptracker;

import java.util.concurrent.Semaphore;

import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

public class MATEventQueue {
    // SharedPreferences for storing events that were not fired
    private SharedPreferences eventQueue;
    
    // Binary semaphore for controlling adding to queue/dumping queue
    private Semaphore queueAvailable;
    
    // Instance of mat to make getLink call on (can't use getInstance during testing)
    private MobileAppTracker mat;
    
    // current retry timeout, in seconds
    private static long retryTimeout = 0;
    
    public MATEventQueue(Context context, MobileAppTracker mat) {
        eventQueue = context.getSharedPreferences(MATConstants.PREFS_NAME, Context.MODE_PRIVATE);
        queueAvailable = new Semaphore(1, true);
        this.mat = mat;
    }
    
    /**
     * Sets the event queue size to value.
     * @param size the new queue size
     */
    protected synchronized void setQueueSize(int size) {
        SharedPreferences.Editor editor = eventQueue.edit();
        if (size < 0) size = 0;
        editor.putInt("queuesize", size);
        editor.commit();
    }
    
    /**
     * Returns the current event queue size.
     * @return the event queue size
     */
    protected synchronized int getQueueSize() {
        return eventQueue.getInt("queuesize", 0);
    }
    
    /**
     * Removes a specific item from the queue.
     */
    protected synchronized void removeKeyFromQueue(String key) {
        setQueueSize(getQueueSize() - 1);
        SharedPreferences.Editor editor = eventQueue.edit();
        editor.remove(key);
        editor.commit();
    }
    
    /**
     * Returns a specific item from the queue, without deleting the item.
     * @return JSONObject of the item
     */
    protected synchronized String getKeyFromQueue( String key ) {
        return eventQueue.getString(key, null);
    }
    
    /**
     * Sets the values for a particular queue key.
     */
    protected synchronized void setQueueItemForKey( JSONObject item, String key ) {
        SharedPreferences.Editor editor = eventQueue.edit();
        editor.putString(key, item.toString());
        editor.commit();
    }
    
    protected class Add implements Runnable {
        private String link = null;
        private String data = null;
        private JSONObject postBody = null;
        private boolean firstSession = false;
        
        /**
         * Saves an event to the queue.
         * @param link URL of the event postback
         * @param postBody the body of the POST request
         * @param firstSession whether event should wait for GAID/referrer to be received
         */
        protected Add(String link, String data, JSONObject postBody, boolean firstSession) {
            this.link = link;
            this.data = data;
            this.postBody = postBody;
            this.firstSession = firstSession;
        }

        public void run() {
            try {
                // Acquire semaphore before modifying queue
                queueAvailable.acquire();
                
                // JSON-serialize the link and json to store in Shared Preferences as a string
                JSONObject jsonEvent = new JSONObject();
                try {
                    jsonEvent.put("link", link);
                    jsonEvent.put("data", data);
                    jsonEvent.put("post_body", postBody);
                    jsonEvent.put("first_session", firstSession);
                } catch (JSONException e) {
                    Log.w(MATConstants.TAG, "Failed creating event for queueing");
                    e.printStackTrace();
                    return;
                }
                int count = getQueueSize() + 1;
                setQueueSize(count);
                String eventIndex = Integer.toString(count);
                setQueueItemForKey(jsonEvent, eventIndex);
            } catch (InterruptedException e) {
                Log.w(MATConstants.TAG, "Interrupted adding event to queue");
                e.printStackTrace();
            } finally {
                queueAvailable.release();
            }
        }
    }
    
    protected class Dump implements Runnable {

        public void run() {
            int size = getQueueSize();
            if (size == 0) return;
            
            try {
                queueAvailable.acquire();

                int index = 1;
                if (size > MATConstants.MAX_DUMP_SIZE) {
                    index = 1 + (size - MATConstants.MAX_DUMP_SIZE);
                }

                // Iterate through events and do postbacks for each, using GetLink
                for (; index <= size; index++) {
                    String key = Integer.toString(index);
                    String eventJson = getKeyFromQueue(key);

                    if (eventJson != null) {
                        String link = null;
                        String data = null;
                        JSONObject postBody = null;
                        boolean firstSession = false;
                        try {
                            // De-serialize the stored string from the queue to get URL and json values
                            JSONObject event = new JSONObject(eventJson);
                            link = event.getString("link");
                            data = event.getString("data");
                            postBody = event.getJSONObject("post_body");
                            firstSession = event.getBoolean("first_session");
                        } catch (JSONException e) {
                            e.printStackTrace();
                            // Can't rebuild saved request, remove from queue and return
                            removeKeyFromQueue(key);
                            return;
                        }
                        
                        // For first session, try to wait for Google AID and install referrer before sending
                        if (firstSession) {
                            synchronized(mat.pool) {
                                mat.pool.wait(MATConstants.DELAY);
                            }
                        }
                        
                        if (mat != null) {
                            boolean success = mat.makeRequest(link, data, postBody);

                            if (success) {
                                removeKeyFromQueue(key);
                                retryTimeout = 0; // reset retry timeout after success
                            } else {
                                // repeat this call
                                index--;
                                // update retry parameter
                                // maybe try a regex parse instead...
                                final String paramString = "&sdk_retry_attempt=";
                                int retryStart = link.indexOf( paramString );
                                if( retryStart > 0 ) {
                                    // find the longest substring that legally parses as an int
                                    int attempt = -1;
                                    int parseStart = retryStart + paramString.length();
                                    int parseEnd = parseStart + 1;
                                    while( true ) {
                                        String attemptString = null;
                                        try {
                                            attemptString = link.substring( parseStart, parseEnd );
                                        } catch (StringIndexOutOfBoundsException e) {
                                            break; // use last successfully parsed value
                                        }
                                        try {
                                            attempt = Integer.parseInt( attemptString );
                                            parseEnd++;
                                        } catch (NumberFormatException e) {
                                            break; // use last successfully parsed value
                                        }
                                    }
                                    attempt++;
                                    // 'attempt' will always be at least 0 here
                                    link = link.replaceFirst( paramString + "\\d+", paramString + attempt );

                                    // save updated link back to queue
                                    try {
                                        JSONObject event = new JSONObject(eventJson);
                                        event.put("link", link);
                                        setQueueItemForKey( event, key );
                                    } catch (JSONException e) {
                                        // error saving modified retry parameter, ignore
                                        e.printStackTrace();
                                    }
                                }
                                // choose new retry timeout, in seconds
                                if( retryTimeout == 0 ) {
                                    retryTimeout = 30;
                                } else if( retryTimeout <= 30 ) {
                                    retryTimeout = 90;
                                } else if( retryTimeout <= 90 ) {
                                    retryTimeout = 10*60;
                                } else if( retryTimeout <= 10*60 ) {
                                    retryTimeout = 60*60;
                                } else if( retryTimeout <= 60*60 ) {
                                    retryTimeout = 6*60*60;
                                } else {
                                    retryTimeout = 24*60*60;
                                }
                                // randomize and convert to milliseconds
                                double timeoutMs = (1 + 0.1*Math.random())*retryTimeout*1000.;
                                // sleep this thread for awhile
                                try {
                                    Thread.sleep( (long)timeoutMs );
                                } catch (InterruptedException e) {
                                }
                            }
                        } else {
                            Log.d(MATConstants.TAG, "Dropping queued request because no MAT object was found");
                            removeKeyFromQueue(key);
                        }
                    } else {
                        // eventJson null, queued event value was lost somehow
                        Log.d(MATConstants.TAG, "Null request skipped from queue");
                        removeKeyFromQueue(key);
                    }
                } // for each item in queue
            } catch (InterruptedException e) {
                e.printStackTrace();
            } finally {
                queueAvailable.release();
            }
        }
        
    }
}
