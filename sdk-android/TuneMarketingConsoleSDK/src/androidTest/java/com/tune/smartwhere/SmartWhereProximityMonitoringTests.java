package com.tune.smartwhere;

import android.content.Context;
import android.location.Location;

import com.tune.Tune;
import com.tune.TuneLocation;
import com.tune.TuneTestConstants;
import com.tune.TuneUnitTest;

import java.lang.reflect.Field;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import static android.support.test.InstrumentationRegistry.getInstrumentation;
import static org.mockito.Matchers.any;
import static org.mockito.Matchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

public class SmartWhereProximityMonitoringTests extends TuneUnitTest {

    @Override
    protected void setUp() throws Exception {
        super.setUp();

        System.setProperty(
                "dexmaker.dexcache",
                getInstrumentation().getTargetContext().getCacheDir().getPath());

        tune.setOnline(false);
    }

    @Override
    protected void tearDown() throws Exception {
        tune.setOnline(true);

        super.tearDown();
    }

    public void testSetLocationStopsProximityMonitoring() throws Exception {
        shutdownWaitAndRecreatePubQueue();
        TuneSmartWhere mockTuneSmartWhere =   mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailable()).thenReturn(true);

        tune.setLocation(new Location("mockProvider"));

        shutdownWaitAndRecreatePubQueue();

        verify(mockTuneSmartWhere).isSmartWhereAvailable();
        verify(mockTuneSmartWhere).stopMonitoring(mContext);
    }

    public void testSetLocationDoesntStopProximityMonitoringIfNotInstalled() throws Exception {
        shutdownWaitAndRecreatePubQueue();
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailable()).thenReturn(false);

        tune.setLocation(new Location("mockProvider"));

        shutdownWaitAndRecreatePubQueue();

        verify(mockTuneSmartWhere).isSmartWhereAvailable();
        verify(mockTuneSmartWhere, never()).stopMonitoring(mContext);

    }

    public void testSetLocationWithTuneLocationStopsProximityMonitoring() throws Exception {
        shutdownWaitAndRecreatePubQueue();
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailable()).thenReturn(true);

        tune.setLocation(new TuneLocation(new Location("mockProvider")));

        shutdownWaitAndRecreatePubQueue();

        verify(mockTuneSmartWhere).isSmartWhereAvailable();
        verify(mockTuneSmartWhere).stopMonitoring(mContext);
    }

    public void testSetLocationWithTuneLocationDoesntStopProximityMonitoringIfNotInstalled() throws Exception {
        shutdownWaitAndRecreatePubQueue();
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailable()).thenReturn(false);

        tune.setLocation(new TuneLocation(new Location("mockProvider")));
        shutdownWaitAndRecreatePubQueue();

        verify(mockTuneSmartWhere).isSmartWhereAvailable();
        verify(mockTuneSmartWhere, never()).stopMonitoring(mContext);

    }

    public void testSetShouldAutoCollectDeviceLocationStopsProximityMonitoringWhenSetToFalse() throws Exception {
        shutdownWaitAndRecreatePubQueue();
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailable()).thenReturn(true);

        tune.setShouldAutoCollectDeviceLocation(false);

        shutdownWaitAndRecreatePubQueue();

        verify(mockTuneSmartWhere).isSmartWhereAvailable();
        verify(mockTuneSmartWhere).stopMonitoring(mContext);
    }

    public void testSetShouldAutoCollectDeviceLocationDoesntAttemptToStopProximityMonitoringWhenSetToFalseButNotInstalled() throws Exception {
        shutdownWaitAndRecreatePubQueue();
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailable()).thenReturn(false);

        tune.setShouldAutoCollectDeviceLocation(false);

        shutdownWaitAndRecreatePubQueue();

        verify(mockTuneSmartWhere).isSmartWhereAvailable();
        verify(mockTuneSmartWhere, never()).stopMonitoring(mContext);
    }

    public void testSetShouldAutoCollectDeviceLocationStartsProximityMonitoringWhenSetToTrue() throws Exception {
        shutdownWaitAndRecreatePubQueue();
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailable()).thenReturn(true);

        tune.setShouldAutoCollectDeviceLocation(true);

        shutdownWaitAndRecreatePubQueue();

        verify(mockTuneSmartWhere).isSmartWhereAvailable();
        verify(mockTuneSmartWhere).startMonitoring(mContext, TuneTestConstants.advertiserId, TuneTestConstants.conversionKey, false);
    }

    public void testSetShouldAutoCollectDeviceLocationDoesntAttemptToStartProximityMonitoringWhenSetToTrueButNotInstalled() throws Exception {
        shutdownWaitAndRecreatePubQueue();
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailable()).thenReturn(false);

        tune.setShouldAutoCollectDeviceLocation(true);

        shutdownWaitAndRecreatePubQueue();

        verify(mockTuneSmartWhere).isSmartWhereAvailable();
        verify(mockTuneSmartWhere, never()).startMonitoring(any(Context.class), any(String.class), any(String.class), any(Boolean.class));
    }

    public void testSetDebugModeTrueSetsProximityDebugModeTrueWhenInstalled() throws Exception {
        shutdownWaitAndRecreatePubQueue();
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailable()).thenReturn(true);

        tune.setDebugMode(true);

        shutdownWaitAndRecreatePubQueue();

        verify(mockTuneSmartWhere).isSmartWhereAvailable();
        verify(mockTuneSmartWhere).setDebugMode(mContext, true);
    }

    public void testSetDebugModeFalseSetsProximityDebugModeFalseWhenInstalled() throws Exception {
        shutdownWaitAndRecreatePubQueue();
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailable()).thenReturn(true);

        tune.setDebugMode(false);
        shutdownWaitAndRecreatePubQueue();

        verify(mockTuneSmartWhere).isSmartWhereAvailable();
        verify(mockTuneSmartWhere).setDebugMode(mContext, false);
    }

    public void testSetDebugModeDoesntSetsProximityDebugModeWhenInstalled() throws Exception {
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailable()).thenReturn(false);

        tune.setDebugMode(false);
        shutdownWaitAndRecreatePubQueue();

        verify(mockTuneSmartWhere).isSmartWhereAvailable();
        verify(mockTuneSmartWhere, never()).setDebugMode(any(Context.class), eq(true));
        verify(mockTuneSmartWhere, never()).setDebugMode(any(Context.class), eq(false));
    }

    public void testSetPackageNameDoesntSetsProximityPackageNameWhenNotInstalled() throws Exception {
        shutdownWaitAndRecreatePubQueue();
        String expectedPackageName = "com.expected.package.name";
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailable()).thenReturn(false);
        tune.setPackageName(expectedPackageName);
        shutdownWaitAndRecreatePubQueue();
        verify(mockTuneSmartWhere).isSmartWhereAvailable();
        verify(mockTuneSmartWhere, never()).setPackageName(any(Context.class), any(String.class));
    }

    public void testSetPackageNameSetsProximityPackageNameWhenInstalled() throws Exception {
        shutdownWaitAndRecreatePubQueue();
        String expectedPackageName = "com.another.expected.package.name";
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailable()).thenReturn(true);
        tune.setPackageName(expectedPackageName);
        shutdownWaitAndRecreatePubQueue();
        verify(mockTuneSmartWhere).isSmartWhereAvailable();
        verify(mockTuneSmartWhere).setPackageName(mContext, expectedPackageName);
    }

    private void shutdownWaitAndRecreatePubQueue() throws InterruptedException {
        tune.getPubQueue().shutdown();
        tune.getPubQueue().awaitTermination(60, TimeUnit.SECONDS);
        Field declaredField =  null;
        try {
            declaredField = Tune.class.getDeclaredField("pubQueue");
            boolean accessible = declaredField.isAccessible();

            declaredField.setAccessible(true);

            Executor exec = Executors.newSingleThreadExecutor();
            declaredField.set(tune, exec);

            declaredField.setAccessible(accessible);

        } catch (NoSuchFieldException
                | SecurityException
                | IllegalArgumentException
                | IllegalAccessException e) {
            e.printStackTrace();
        }
    }
}
