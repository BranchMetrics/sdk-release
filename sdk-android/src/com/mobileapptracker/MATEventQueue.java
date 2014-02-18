package com.mobileapptracker;

import java.util.Date;
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
    
    // Instance of mat to make getLink call from (for testing)
    private MobileAppTracker mat;
    
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
    
    protected class Add implements Runnable {
        private String link = null;
        private String eventItems = null;
        private String action = null;
        private double revenue = 0;
        private String currency = null;
        private String refId = null;
        private String iapData = null;
        private String iapSignature = null;
        private String eventAttribute1 = null;
        private String eventAttribute2 = null;
        private String eventAttribute3 = null;
        private String eventAttribute4 = null;
        private String eventAttribute5 = null;
        private boolean shouldBuildData = false;
        private Date runDate = null;
        
        /**
         * Saves an event to the queue.
         * @param link URL of the event postback
         * @param eventItems (Optional) MATEventItem JSON information to post to server
         * @param action the action for the event (conversion/install/open)
         * @param revenue value associated with the event
         * @param currency currency code for the revenue
         * @param refId the advertiser ref ID associated with the event
         * @param iapData the receipt data from Google Play
         * @param iapSignature the receipt signature from Google Play
         * @param shouldBuildData whether link needs encrypted data to be appended or not
         * @param runDate datetime for request to be made
         */
        protected Add(
                String link,
                String eventItems,
                String action,
                double revenue,
                String currency,
                String refId,
                String iapData,
                String iapSignature,
                String eventAttribute1,
                String eventAttribute2,
                String eventAttribute3,
                String eventAttribute4,
                String eventAttribute5,
                boolean shouldBuildData,
                Date runDate) {
            this.link = link;
            this.eventItems = eventItems;
            this.action = action;
            this.revenue = revenue;
            this.currency = currency;
            this.refId = refId;
            this.iapData = iapData;
            this.iapSignature = iapSignature;
            this.eventAttribute1 = eventAttribute1;
            this.eventAttribute2 = eventAttribute2;
            this.eventAttribute3 = eventAttribute3;
            this.eventAttribute4 = eventAttribute4;
            this.eventAttribute5 = eventAttribute5;
            this.shouldBuildData = shouldBuildData;
            this.runDate = runDate;
        }

        public void run() {
            try {
                // Acquire semaphore before modifying queue
                queueAvailable.acquire();
                
                // JSON-serialize the link and json to store in Shared Preferences as a string
                JSONObject jsonEvent = new JSONObject();
                try {
                    jsonEvent.put("link", link);
                    if (eventItems != null) {
                        jsonEvent.put("event_items", eventItems);
                    }
                    jsonEvent.put("action", action);
                    jsonEvent.put("revenue", revenue);
                    if (currency == null) {
                        currency = MATConstants.DEFAULT_CURRENCY_CODE;
                    }
                    jsonEvent.put("currency", currency);
                    if (refId != null) {
                        jsonEvent.put("ref_id", refId);
                    }
                    if (eventAttribute1 != null) {
                        jsonEvent.put("event_attribute1", eventAttribute1);
                    }
                    if (eventAttribute2 != null) {
                        jsonEvent.put("event_attribute2", eventAttribute2);
                    }
                    if (eventAttribute3 != null) {
                        jsonEvent.put("event_attribute3", eventAttribute3);
                    }
                    if (eventAttribute4 != null) {
                        jsonEvent.put("event_attribute4", eventAttribute4);
                    }
                    if (eventAttribute5 != null) {
                        jsonEvent.put("event_attribute5", eventAttribute5);
                    }
                    if (iapData != null) {
                        jsonEvent.put("iap_data", iapData);
                    }
                    if (iapSignature != null) {
                        jsonEvent.put("iap_signature", iapSignature);
                    }
                    jsonEvent.put("should_build_data", shouldBuildData);
                    jsonEvent.put("run_date", runDate.getTime());
                } catch (JSONException e) {
                    // Return if we can't create JSONObject
                    return;
                }
                SharedPreferences.Editor editor = eventQueue.edit();
                int count = getQueueSize() + 1;
                setQueueSize(count);
                String eventIndex = Integer.toString(count);
                editor.putString(eventIndex, jsonEvent.toString());
                editor.commit();
            } catch (InterruptedException e) {
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
                    String eventJson = eventQueue.getString(key, null);

                    if (eventJson != null) {
                        String link = null;
                        String eventItems = null;
                        String action = null;
                        double revenue = 0;
                        String currency = null;
                        String refId = null;
                        String iapData = null;
                        String iapSignature = null;
                        String eventAttribute1 = null;
                        String eventAttribute2 = null;
                        String eventAttribute3 = null;
                        String eventAttribute4 = null;
                        String eventAttribute5 = null;
                        boolean shouldBuildData = false;
                        long runDate = 0;
                        try {
                            // De-serialize the stored string from the queue to get URL and json values
                            JSONObject event = new JSONObject(eventJson);
                            link = event.getString("link");
                            if (event.has("event_items")) {
                                eventItems = event.getString("event_items");
                            }
                            action = event.getString("action");
                            revenue = event.getDouble("revenue");
                            currency = event.getString("currency");
                            if (event.has("ref_id")) {
                                refId = event.getString("ref_id");
                            }
                            if (event.has("iap_data")) {
                                iapData = event.getString("iap_data");
                            }
                            if (event.has("iap_signature")) {
                                iapSignature = event.getString("iap_signature");
                            }
                            if (event.has("event_attribute1")) {
                                eventAttribute1 = event.getString("event_attribute1");
                            }
                            if (event.has("event_attribute2")) {
                                eventAttribute2 = event.getString("event_attribute2");
                            }
                            if (event.has("event_attribute3")) {
                                eventAttribute3 = event.getString("event_attribute3");
                            }
                            if (event.has("event_attribute4")) {
                                eventAttribute4 = event.getString("event_attribute4");
                            }
                            if (event.has("event_attribute5")) {
                                eventAttribute5 = event.getString("event_attribute5");
                            }
                            shouldBuildData = event.getBoolean("should_build_data");
                            runDate = event.getLong("run_date");
                        } catch (JSONException e) {
                            e.printStackTrace();
                            // Can't rebuild saved request, remove from queue and return
                            removeKeyFromQueue(key);
                            return;
                        }

                        // sleep until this action's scheduled run date
                        Date scheduledDate = new Date(runDate);
                        Date now = new Date();
                        if (scheduledDate.after(now)) {
                            try {
                                Thread.sleep(scheduledDate.getTime() - now.getTime());
                            } catch (InterruptedException e) {
                            }
                        }

                        // Remove request from queue and execute
                        removeKeyFromQueue(key);

                        if (mat != null) {
                            mat.makeRequest(link, eventItems, action, revenue, currency, refId, iapData, iapSignature,
                                    eventAttribute1, eventAttribute2, eventAttribute3, eventAttribute4, eventAttribute5, shouldBuildData);
                        } else {
                            Log.d(MATConstants.TAG, "Dropping queued request because no MAT object was found");
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
