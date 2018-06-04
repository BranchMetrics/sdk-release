package com.tune.mocks;

import android.app.Activity;
import android.location.LocationManager;
import android.os.Bundle;
import android.support.test.InstrumentationRegistry;

import com.tune.LocationTests;
import com.tune.location.TuneLocationListener;

import java.lang.ref.WeakReference;

/**
 * Created by johng on 2/11/16.
 */
public class MockActivity extends Activity {
    private static WeakReference<MockActivity> activity;
    private static MockLocationProvider mockGpsProvider;
    private static MockLocationProvider mockNetworkProvider;
    private static TuneLocationListener listener;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        activity = new WeakReference<>(this);

        // Create some mock providers for GPS and network
        mockGpsProvider = new MockLocationProvider(LocationManager.GPS_PROVIDER, InstrumentationRegistry.getTargetContext());
        mockNetworkProvider = new MockLocationProvider(LocationManager.NETWORK_PROVIDER, InstrumentationRegistry.getTargetContext());

        // Manually create a location listener (normally started in Tune.init)
        listener = new TuneLocationListener(this);

        // Check to see if the Mock Provider was successfully started
        if (mockGpsProvider.isMockLocationAvailable()) {
            listener.onProviderEnabled(LocationManager.GPS_PROVIDER);
        } else {
            listener.onProviderDisabled(LocationManager.GPS_PROVIDER);
        }

        if (mockNetworkProvider.isMockLocationAvailable()) {
            listener.onProviderEnabled(LocationManager.NETWORK_PROVIDER);
        } else {
            listener.onProviderDisabled(LocationManager.NETWORK_PROVIDER);
        }

        listener.startListening();
    }

    public static TuneLocationListener getLocationListener() {
        return listener;
    }

    public static void pushGPSLocation() {
        // Set a mock GPS location
        if (mockGpsProvider.isMockLocationAvailable()) {
            mockGpsProvider.pushLocation(LocationTests.GPS_LATITUDE, LocationTests.GPS_LONGITUDE);
        }
    }

    public static void pushNetworkLocation() {
        // Set a mock network location
        if (mockNetworkProvider.isMockLocationAvailable()) {
            mockNetworkProvider.pushLocation(LocationTests.NETWORK_LATITUDE, LocationTests.NETWORK_LONGITUDE);
        }
    }

    public static void clear() {
        mockGpsProvider.shutdown();
        mockGpsProvider.clear();
        mockNetworkProvider.shutdown();
        mockNetworkProvider.clear();

        Activity a = activity.get();
        if (a != null) {
            a.finish();
        }
    }
}
