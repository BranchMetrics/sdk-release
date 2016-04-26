package com.tune;

import android.location.Location;

/**
 * Created by charlesgilliam on 1/22/16.
 */
public class TuneLocation {
    double altitude;
    double longitude;
    double latitude;

    public TuneLocation(Location location) {
        this.altitude = location.getAltitude();
        this.longitude = location.getLongitude();
        this.latitude = location.getLatitude();
    }

    public TuneLocation(double longitude, double latitude) {
        this.longitude = longitude;
        this.latitude = latitude;
    }

    public double getAltitude() {
        return altitude;
    }

    public double getLongitude() {
        return longitude;
    }

    public TuneLocation setLongitude(double longitude) {
        this.longitude = longitude;
        return this;
    }

    public double getLatitude() {
        return latitude;
    }

    public TuneLocation setLatitude(double latitude) {
        this.latitude = latitude;
        return this;
    }
}
