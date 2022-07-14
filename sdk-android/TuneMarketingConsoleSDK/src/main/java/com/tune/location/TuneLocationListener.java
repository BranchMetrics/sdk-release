package com.tune.location;

import android.content.Context;
import android.location.Location;
import android.location.LocationListener;
import android.os.Bundle;

import com.tune.TuneDebugLog;

/**
 * Created by johng on 2/9/16.
 */
public class TuneLocationListener implements LocationListener {

    /**
     * Constructor.
     * @param context Context
     */
    public TuneLocationListener(final Context context) {

    }

    /**
     * Whether app has location permissions or not.
     * @return app has location permissions or not
     */
    private synchronized boolean isLocationEnabled() {
        return false;
    }

    /**
     * Gets the last location.
     * Asks for location updates if last location seen is not valid anymore
     * @return last location or null if location wasn't seen yet
     */
    public synchronized Location getLastLocation() {
        return null;
    }

    /**
     * Starts listening for location updates.
     */
    public synchronized void startListening() {
        return;
    }

    /**
     * Stops listening for location updates.
     */
    public synchronized void stopListening() { }

    /**
     * Checks if this listener is current listening for location changes.
     *
     * @return true if listening, false otherwise
     */
    public synchronized boolean isListening() {
        return false;
    }

    /**
     * Determines whether one Location reading is better than the current Location fix.
     * Code from http://developer.android.com/guide/topics/location/strategies.html#BestEstimate
     * @param location The new Location that you want to evaluate
     * @param currentBestLocation The current Location fix, to which you want to compare the new one
     * @return Whether new location is better than current best location
     */
    private boolean isBetterLocation(Location location, Location currentBestLocation) {
        return false;
    }

    /**
     * Checks whether two providers are the same.
     * Code from http://developer.android.com/guide/topics/location/strategies.html#BestEstimate
     * @param provider1 First provider to compare
     * @param provider2 Second provider to compare
     * @return Whether they're the same
     */
    private boolean isSameProvider(String provider1, String provider2) {
       return false;
    }

    private class GetLocationUpdates implements Runnable {
        @Override
        public void run() {
            TuneDebugLog.d("Location updates are deprecated.");
        }
    }

    @Override
    public void onLocationChanged(Location location) { }

    @Override
    public void onStatusChanged(String provider, int status, Bundle extras) { }

    @Override
    public void onProviderEnabled(String provider) { }

    @Override
    public void onProviderDisabled(String provider) { }
}
