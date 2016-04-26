package com.tune.wear;

import java.io.ByteArrayInputStream;
import java.io.ObjectInputStream;

import com.google.android.gms.wearable.DataMap;
import com.google.android.gms.wearable.MessageEvent;
import com.google.android.gms.wearable.WearableListenerService;
import com.tune.Tune;
import com.tune.TuneEvent;

public class TuneWearableListenerService extends WearableListenerService {
    private Tune tune;
    
    @Override
    public void onMessageReceived(MessageEvent messageEvent) {
        String path = messageEvent.getPath();
        
        if (path.equals(TuneWearable.TUNE_EVENT)) {
            DataMap map = DataMap.fromByteArray(messageEvent.getData());

            // If app has not been opened yet, init Tune using the id and key passed from WearTracker
            if (Tune.getInstance() == null) {
                tune = Tune.init(getApplicationContext(),
                        map.getString("advertiserId"),
                        map.getString("conversionKey"));
            } else {
                tune = Tune.getInstance();
            }
            
            // Set wearable device brand, model, os version
            tune.setDeviceBrand(map.getString("deviceBrand"));
            tune.setDeviceModel(map.getString("deviceModel"));
            tune.setOsVersion(map.getString("osVersion"));

            // Get the TuneEvent from byte array and measure event
            ByteArrayInputStream bis = new ByteArrayInputStream(map.getByteArray("event"));
            try {
                ObjectInputStream ois = new ObjectInputStream(bis);
                TuneEvent event = (TuneEvent) ois.readObject();
                tune.measureEvent(event);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
