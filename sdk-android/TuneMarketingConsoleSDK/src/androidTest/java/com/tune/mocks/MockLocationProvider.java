package com.tune.mocks;

import android.content.Context;
import android.location.Location;
import android.location.LocationManager;
import android.os.Build;

/**
 * Created by johng on 2/11/16.
 */
public class MockLocationProvider {
    String providerName;
    Context ctx;
    LocationManager lm;

    public MockLocationProvider(String name, Context ctx) {
        this.providerName = name;
        this.ctx = ctx;

        lm = (LocationManager) ctx.getSystemService(
                Context.LOCATION_SERVICE);
        lm.addTestProvider(providerName, false, false, false, false, false,
                true, true, 0, 5);
        lm.setTestProviderEnabled(providerName, true);
    }

    public void pushLocation(double lat, double lon) {
        Location mockLocation = new Location(providerName);
        mockLocation.setLatitude(lat);
        mockLocation.setLongitude(lon);
        mockLocation.setAltitude(0);
        mockLocation.setTime(System.currentTimeMillis());
        mockLocation.setAccuracy(0);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            // Set it to some mock non-zero value
            mockLocation.setElapsedRealtimeNanos(1234567890);
        }
        lm.setTestProviderLocation(providerName, mockLocation);
    }

    public void clear() {
        try {
            lm.clearTestProviderLocation(providerName);
        } catch (IllegalArgumentException e) {
        }
    }

    public void shutdown() {
        try {
            lm.removeTestProvider(providerName);
        } catch (IllegalArgumentException e) {
        }
    }
}
