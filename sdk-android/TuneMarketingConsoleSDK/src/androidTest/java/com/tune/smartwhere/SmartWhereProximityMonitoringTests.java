package com.tune.smartwhere;

import android.content.Context;

import com.tune.Tune;
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

    public void testSetDebugModeTrueSetsProximityDebugModeTrueWhenInstalled() throws Exception {
        shutdownWaitAndRecreatePubQueue();
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailableInternal()).thenReturn(true);

        tune.setDebugMode(true);

        shutdownWaitAndRecreatePubQueue();

        verify(mockTuneSmartWhere).isSmartWhereAvailableInternal();
        verify(mockTuneSmartWhere).setDebugMode(mContext, true);
    }

    public void testSetDebugModeFalseSetsProximityDebugModeFalseWhenInstalled() throws Exception {
        shutdownWaitAndRecreatePubQueue();
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailableInternal()).thenReturn(true);

        tune.setDebugMode(false);
        shutdownWaitAndRecreatePubQueue();

        verify(mockTuneSmartWhere).isSmartWhereAvailableInternal();
        verify(mockTuneSmartWhere).setDebugMode(mContext, false);
    }

    public void testSetDebugModeDoesntSetsProximityDebugModeWhenInstalled() throws Exception {
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailableInternal()).thenReturn(false);

        tune.setDebugMode(false);
        shutdownWaitAndRecreatePubQueue();

        verify(mockTuneSmartWhere).isSmartWhereAvailableInternal();
        verify(mockTuneSmartWhere, never()).setDebugMode(any(Context.class), eq(true));
        verify(mockTuneSmartWhere, never()).setDebugMode(any(Context.class), eq(false));
    }

    public void testSetPackageNameDoesntSetsProximityPackageNameWhenNotInstalled() throws Exception {
        shutdownWaitAndRecreatePubQueue();
        String expectedPackageName = "com.expected.package.name";
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailableInternal()).thenReturn(false);
        tune.setPackageName(expectedPackageName);
        shutdownWaitAndRecreatePubQueue();
        verify(mockTuneSmartWhere).isSmartWhereAvailableInternal();
        verify(mockTuneSmartWhere, never()).setPackageName(any(Context.class), any(String.class));
    }

    public void testSetPackageNameSetsProximityPackageNameWhenInstalled() throws Exception {
        shutdownWaitAndRecreatePubQueue();
        String expectedPackageName = "com.another.expected.package.name";
        TuneSmartWhere mockTuneSmartWhere = mock(TuneSmartWhere.class);
        TuneSmartWhere.setInstance(mockTuneSmartWhere);
        when(mockTuneSmartWhere.isSmartWhereAvailableInternal()).thenReturn(true);
        tune.setPackageName(expectedPackageName);
        shutdownWaitAndRecreatePubQueue();
        verify(mockTuneSmartWhere).isSmartWhereAvailableInternal();
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