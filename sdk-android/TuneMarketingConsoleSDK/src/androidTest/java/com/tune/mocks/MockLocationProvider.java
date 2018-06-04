package com.tune.mocks;

import android.content.Context;
import android.location.Location;
import android.location.LocationManager;
import android.os.Build;
import android.util.Log;

/**
 * Created by johng on 2/11/16.
 */
public class MockLocationProvider {
    private static final String TAG = "Tune::MockLocationProvider";
    String providerName;
    LocationManager lm;
    private boolean mMockAvailable;

    public MockLocationProvider(String name, Context ctx) {
        this.providerName = name;

        lm = (LocationManager) ctx.getSystemService(Context.LOCATION_SERVICE);

        try {
            lm.addTestProvider(providerName, false, false, false, false, false,
                    true, true, 0, 5);
            mMockAvailable = true;
        } catch (SecurityException e) {
            Log.d(TAG, "MOCK Location Not Available");
        }

        try {
            lm.setTestProviderEnabled(providerName, isMockLocationAvailable());
        } catch (SecurityException e) {
        }
    }

    public boolean isMockLocationAvailable() {
        return mMockAvailable;
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
        } catch (SecurityException e) {
        }
    }

    public void shutdown() {
        try {
            lm.removeTestProvider(providerName);
        } catch (IllegalArgumentException e) {
        } catch (SecurityException e) {
        }
    }
}
