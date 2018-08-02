package com.tune;

import android.content.Intent;
import android.support.test.InstrumentationRegistry;
import android.support.test.runner.AndroidJUnit4;

import com.tune.location.TuneLocationListener;
import com.tune.mocks.MockActivity;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.assertNotNull;

/**
 * Created by johng on 2/10/16.
 */
@RunWith(AndroidJUnit4.class)
public class LocationTests extends TuneUnitTest {
    public static final double GPS_LATITUDE = -12.34;
    public static final double GPS_LONGITUDE = 23.45;
    public static final double NETWORK_LATITUDE = 111.11;
    public static final double NETWORK_LONGITUDE = -111.11;

    private static final int LOCATION_SLEEP = 1000;
    private static final double LOCATION_DELTA = 0.01;

    private TuneLocationListener locationListener;

    @Before
    public void setUp() {
        Intent intent = new Intent(InstrumentationRegistry.getTargetContext(), MockActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        InstrumentationRegistry.getTargetContext().startActivity(intent);

        // Activity needs time to start up
        sleep(LOCATION_SLEEP);

        // Get the location listener started from the activity, make sure it's not null
        locationListener = MockActivity.getLocationListener();
        assertNotNull(locationListener);
    }

    @After
    public void tearDown() throws Exception {
        MockActivity.clear();
    }

    @Test
    public void testLocationFromGps() {
//        // Put a fake location for GPS provider
//        MockActivity.pushGPSLocation();
//
//        // Check that last location is null, triggering a location update
//        assertNull(locationListener.getLastLocation());
//
//        // Allow location some time to get read
//        sleep(LOCATION_SLEEP);
//
//        Location lastLocation = locationListener.getLastLocation();
//        // Check that listener got the location
//        assertNotNull(lastLocation);
//        // Check that listener got the right GPS coordinates
//        assertEquals(GPS_LATITUDE, lastLocation.getLatitude(), LOCATION_DELTA);
//        assertEquals(GPS_LONGITUDE, lastLocation.getLongitude(), LOCATION_DELTA);
    }

    @Test
    public void testLocationFromNetwork() {
//        // Put a fake location for network provider
//        MockActivity.pushNetworkLocation();
//
//        // Check that last location is null, triggering a location update
//        assertNull(locationListener.getLastLocation());
//
//        // Allow location some time to get read
//        sleep(LOCATION_SLEEP);
//
//        Location lastLocation = locationListener.getLastLocation();
//        // Check that listener got the location
//        assertNotNull(lastLocation);
//        // Check that listener got the right network coordinates
//        assertEquals(NETWORK_LATITUDE, lastLocation.getLatitude(), LOCATION_DELTA);
//        assertEquals(NETWORK_LONGITUDE, lastLocation.getLongitude(), LOCATION_DELTA);
    }
}
