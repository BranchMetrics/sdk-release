package com.tune.mocks;

import android.app.Activity;
import android.location.LocationManager;
import android.os.Bundle;

import com.tune.LocationTests;
import com.tune.location.TuneLocationListener;

/**
 * Created by johng on 2/11/16.
 */
public class MockActivity extends Activity {
    private static MockActivity activity;
    private static MockLocationProvider mockGpsProvider;
    private static MockLocationProvider mockNetworkProvider;
    private static TuneLocationListener listener;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        activity = this;

        // Create some mock providers for GPS and network
        mockGpsProvider = new MockLocationProvider(LocationManager.GPS_PROVIDER, this);
        mockNetworkProvider = new MockLocationProvider(LocationManager.NETWORK_PROVIDER, this);
        // Manually create a location listener (normally started in Tune.init)
        listener = new TuneLocationListener(this);
        listener.startListening();
    }

    public static TuneLocationListener getLocationListener() {
        return listener;
    }

// Commenting out method per 8/8/16 TO DO in LocationTests.java, where the method was originally used. Tests still broken as of 12/5/2017.
//    public static void pushGPSLocation() {
//        // Set a mock GPS location
//        mockGpsProvider.pushLocation(LocationTests.GPS_LATITUDE, LocationTests.GPS_LONGITUDE);
//    }

// Commenting out method per 8/8/16 TO DO in LocationTests.java, where the method was originally used. Tests still broken as of 12/5/2017.
//    public static void pushNetworkLocation() {
//        // Set a mock network location
//        mockNetworkProvider.pushLocation(LocationTests.NETWORK_LATITUDE, LocationTests.NETWORK_LONGITUDE);
//    }

    public static void clear() {
        mockGpsProvider.shutdown();
        mockGpsProvider.clear();
        mockNetworkProvider.shutdown();
        mockNetworkProvider.clear();
        activity.finish();
    }
}
