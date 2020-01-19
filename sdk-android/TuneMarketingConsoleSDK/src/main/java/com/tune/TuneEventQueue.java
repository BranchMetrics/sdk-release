package com.tune;

import android.content.Context;

import com.tune.utils.TuneSharedPrefsDelegate;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.concurrent.Semaphore;

public class TuneEventQueue {
    // SharedPreferences for storing events that were not fired
    private TuneSharedPrefsDelegate eventQueue;
    
    // Binary semaphore for controlling adding to queue/dumping queue
    private Semaphore queueAvailable;
    
    // Instance of tune to make getLink call on (can't use getInstance during testing)
    private TuneInternal tune;
    
    // current retry timeout, in seconds
    private static long retryTimeout = 0;
    
    public TuneEventQueue(Context context, TuneInternal tune) {
        eventQueue = new TuneSharedPrefsDelegate(context, TuneConstants.PREFS_QUEUE);
        queueAvailable = new Semaphore(1, true);
        this.tune = tune;
    }

    public void acquireLock() throws InterruptedException {
        queueAvailable.acquire();
    }

    public void releaseLock() {
        queueAvailable.release();
    }
    
    /**
     * Sets the event queue size to value.
     * @param size the new queue size
     */
    protected synchronized void setQueueSize(int size) {
        if (size < 0) size = 0;
        eventQueue.putInt("queuesize", size);
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
     * @param key The name of the item to remove.
     */
    protected synchronized void removeKeyFromQueue(String key) {
        setQueueSize(getQueueSize() - 1);
        eventQueue.remove(key);
    }

    /**
     * Remove all keys from the queue, including the queue size (effectively making the size zero).
     */
    protected synchronized void clearQueue() {
        eventQueue.clearSharedPreferences();
    }
    
    /**
     * Returns a specific item from the queue, without deleting the item.
     * @param key The name of the item to retrieve.
     * @return JSONObject of the item
     */
    protected synchronized String getKeyFromQueue(String key) {
        return eventQueue.getString(key, null);
    }
    
    /**
     * Sets the values for a particular queue key.
     * @param item The new value for the item.
     * @param key The key to modify.
     */
    protected synchronized void setQueueItemForKey(JSONObject item, String key) {
        eventQueue.putString(key, item.toString());
    }
    
    protected class Add implements Runnable {
        private String link = null;
        private String data = null;
        private JSONObject postBody = null;
        private boolean firstSession = false;
        
        /**
         * Saves an event to the queue.
         * @param link URL of the event postback
         * @param data URL data
         * @param postBody the body of the POST request
         * @param firstSession whether event should wait for advertising ID/referrer to be received
         */
        protected Add(String link, String data, JSONObject postBody, boolean firstSession) {
            TuneDebugLog.d("Add() created");

            this.link = link;
            this.data = data;
            this.postBody = postBody;
            this.firstSession = firstSession;
        }

        public void run() {
            try {
                // Acquire semaphore before modifying queue
                acquireLock();
                
                // JSON-serialize the link and json to store in Shared Preferences as a string
                JSONObject jsonEvent = new JSONObject();
                try {
                    jsonEvent.put("link", link);
                    jsonEvent.put("data", data);
                    jsonEvent.put("post_body", postBody);
                    jsonEvent.put("first_session", firstSession);
                } catch (JSONException e) {
                    TuneDebugLog.w("Failed creating event for queueing", e);
                    return;
                }
                int count = getQueueSize() + 1;
                setQueueSize(count);
                String eventIndex = Integer.toString(count);
                setQueueItemForKey(jsonEvent, eventIndex);
            } catch (InterruptedException e) {
                TuneDebugLog.w("Interrupted adding event to queue", e);
            } finally {
                releaseLock();
            }
        }
    }
    
    protected class Dump implements Runnable {
        public Dump() {
        }

        public void run() {
            int size = getQueueSize();
            if (size > 0) {
                try {
                    acquireLock();

                    int index = 1;
                    if (size > TuneConstants.MAX_DUMP_SIZE) {
                        index = 1 + (size - TuneConstants.MAX_DUMP_SIZE);
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
                                TuneDebugLog.d("Dump run exception", e);

                                // Can't rebuild saved request, remove from queue and return
                                removeKeyFromQueue(key);
                                return;
                            }

                            // For first session, try to wait for Google AID and install referrer before sending
                            if (firstSession) {
                                tune.waitForFirstRunData(TuneConstants.FIRST_RUN_LOGIC_WAIT_TIME);
                            }

                            if (tune != null) {
                                boolean success = tune.makeRequest(link, data, postBody);

                                if (success) {
                                    removeKeyFromQueue(key);
                                    retryTimeout = 0; // reset retry timeout after success
                                } else {
                                    // repeat this call
                                    index--;
                                    // update retry parameter
                                    // maybe try a regex parse instead...
                                    final String paramString = "&" + TuneUrlKeys.SDK_RETRY_ATTEMPT + "=";
                                    int retryStart = link.indexOf(paramString);
                                    if (retryStart > 0) {
                                        // find the longest substring that legally parses as an int
                                        int attempt = -1;
                                        int parseStart = retryStart + paramString.length();
                                        int parseEnd = parseStart + 1;
                                        while (true) {
                                            String attemptString = null;
                                            try {
                                                attemptString = link.substring(parseStart, parseEnd);
                                            } catch (StringIndexOutOfBoundsException e) {
                                                break; // use last successfully parsed value
                                            }
                                            try {
                                                attempt = Integer.parseInt(attemptString);
                                                parseEnd++;
                                            } catch (NumberFormatException e) {
                                                break; // use last successfully parsed value
                                            }
                                        }
                                        attempt++;
                                        // 'attempt' will always be at least 0 here
                                        link = link.replaceFirst(paramString + "\\d+", paramString + attempt);

                                        // save updated link back to queue
                                        try {
                                            JSONObject event = new JSONObject(eventJson);
                                            event.put("link", link);
                                            setQueueItemForKey(event, key);
                                        } catch (JSONException e) {
                                            // error saving modified retry parameter, ignore
                                            TuneDebugLog.d("Dump run exception saving retry parameter");
                                        }
                                    }
                                    // choose new retry timeout, in seconds
                                    if (retryTimeout == 0) {
                                        retryTimeout = 30;
                                    } else if (retryTimeout <= 30) {
                                        retryTimeout = 90;
                                    } else if (retryTimeout <= 90) {
                                        retryTimeout = 10 * 60;
                                    } else if (retryTimeout <= 10 * 60) {
                                        retryTimeout = 60 * 60;
                                    } else if (retryTimeout <= 60 * 60) {
                                        retryTimeout = 6 * 60 * 60;
                                    } else {
                                        retryTimeout = 24 * 60 * 60;
                                    }
                                    // randomize and convert to milliseconds
                                    double timeoutMs = (1 + 0.1 * Math.random()) * retryTimeout * 1000.;
                                    // sleep this thread for awhile
                                    try {
                                        TuneDebugLog.d("Dump() Sleeping " + timeoutMs + " milliseconds");
                                        Thread.sleep((long) timeoutMs);
                                    } catch (InterruptedException e) {
                                    }
                                }
                            } else {
                                TuneDebugLog.d("Dropping queued request because no TUNE object was found");
                                removeKeyFromQueue(key);
                            }
                        } else {
                            // eventJson null, queued event value was lost somehow
                            TuneDebugLog.d("Null request skipped from queue");
                            removeKeyFromQueue(key);
                        }
                    } // for each item in queue
                } catch (InterruptedException e) {
                    TuneDebugLog.d("Dump run Interrupted exception", e);
                } finally {
                    releaseLock();
                }
            }
        }
        
    }
}
