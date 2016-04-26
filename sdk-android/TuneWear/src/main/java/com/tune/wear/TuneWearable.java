package com.tune.wear;

import java.io.ByteArrayOutputStream;
import java.io.ObjectOutputStream;
import java.util.HashSet;

import android.content.Context;
import android.os.Build;
import android.os.Handler;
import android.os.HandlerThread;

import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.wearable.DataMap;
import com.google.android.gms.wearable.Node;
import com.google.android.gms.wearable.NodeApi;
import com.google.android.gms.wearable.Wearable;
import com.tune.TuneEvent;

public class TuneWearable {
    public final static String TUNE_EVENT = "/tune/event";
    final static String THREAD_NAME = "TuneWearableThread";
    
    private Handler mHandler;
    private HandlerThread mHandlerThread;
    
    private Context mContext;
    private String mAdvertiserId;
    private String mConversionKey;
    
    private static volatile TuneWearable wearTracker = null;

    private TuneWearable(Context context, String advertiserId, String conversionKey) {
        mHandlerThread = new HandlerThread(THREAD_NAME);
        mHandlerThread.start();
        mHandler = new Handler(mHandlerThread.getLooper());
        
        mContext = context;
        mAdvertiserId = advertiserId;
        mConversionKey = conversionKey;
    }

    public static synchronized TuneWearable getInstance() {
        return wearTracker;
    }
    
    public static synchronized TuneWearable init(Context context, String advertiserId, String conversionKey) {
        if (wearTracker == null) {
            if (context == null) {
                throw new IllegalArgumentException("Context must not be null.");
            }
            wearTracker = new TuneWearable(context, advertiserId, conversionKey);
        }
        return wearTracker;
    }
    
    public void measureSession() {
        measureEvent(new TuneEvent("session"));
    }
    
    public void measureEvent(String eventName) {
        measureEvent(new TuneEvent(eventName));
    }
    
    public void measureEvent(int eventId) {
        measureEvent(new TuneEvent(eventId));
    }

    public void measureEvent(TuneEvent event) {
        // Start Runnable to send message for measurement
        mHandler.post(new MeasureEvent(event));
    }
    
    private HashSet<String> getNodes(GoogleApiClient mGoogleApiClient) {
        HashSet<String> results = new HashSet<String>();
        NodeApi.GetConnectedNodesResult nodes =
                Wearable.NodeApi.getConnectedNodes(mGoogleApiClient).await();
        for (Node node : nodes.getNodes()) {
            results.add(node.getId());
        }
        return results;
    }
    
    private class MeasureEvent implements Runnable {
        private TuneEvent event;

        public MeasureEvent(TuneEvent event) {
            this.event = event;
        }

        public void run() {
            GoogleApiClient mGoogleApiClient = new GoogleApiClient.Builder(mContext)
                    .addApi(Wearable.API)
                    .build();
            mGoogleApiClient.blockingConnect();

            // Set device form to wearable for TuneEvent
            event = event.withDeviceForm(TuneEvent.DEVICE_FORM_WEARABLE);
            
            // Convert TuneEvent to byte array for messaging
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            ObjectOutputStream oos = null;

            try {
                oos = new ObjectOutputStream(bos);
                oos.writeObject(event);

                byte[] eventData = bos.toByteArray();

                DataMap dataMap = new DataMap();
                dataMap.putString("advertiserId", mAdvertiserId);
                dataMap.putString("conversionKey", mConversionKey);
                dataMap.putString("deviceModel", Build.MODEL);
                dataMap.putString("deviceBrand", Build.MANUFACTURER);
                dataMap.putString("osVersion", Build.VERSION.RELEASE);
                dataMap.putByteArray("event", eventData);
                
                // Message all connected nodes
                HashSet<String> nodes = getNodes(mGoogleApiClient);
                for (String node : nodes) {
                    Wearable.MessageApi.sendMessage(mGoogleApiClient, node, TUNE_EVENT, dataMap.toByteArray());
                }
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                try {
                    if (oos != null)
                        oos.close();
                } catch (Exception e) {
                }
                try {
                    bos.close();
                } catch (Exception e) {
                }
            }
        }
    }
}
