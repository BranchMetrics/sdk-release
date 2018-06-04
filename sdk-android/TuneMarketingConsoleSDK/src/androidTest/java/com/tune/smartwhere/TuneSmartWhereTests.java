package com.tune.smartwhere;

import android.annotation.SuppressLint;
import android.content.Context;
import android.support.test.runner.AndroidJUnit4;

import com.tune.TuneEvent;
import com.tune.TuneUnitTest;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.HashMap;

import static android.support.test.InstrumentationRegistry.getContext;
import static com.tune.TuneEvent.ADD_TO_CART;
import static com.tune.TuneEvent.NAME_SESSION;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;


/**
 * Created by gordonstewart on 8/17/16.
 *
 * @author gordon@smartwhere.com
 */
@RunWith(AndroidJUnit4.class)
public class TuneSmartWhereTests extends TuneUnitTest {

    private TuneSmartWhere testObj;
    private Context context;

    @Before
    public void setUp() throws Exception {
        super.setUp();
        FakeProximityControl.reset();
        context = getContext();

        testObj = TuneSmartWhereForTest.getInstance();
    }

    @After
    public void tearDown() throws Exception {
        super.tearDown();
        TuneSmartWhereForTest.setInstance(null);
    }

    @Test
    public void testIsProximityInstalledReturnsFalseWhenProximityControlClassNotFound() throws Exception {
        TuneSmartWhereForTest.clazz = null;

        assertFalse(testObj.isSmartWhereAvailableInternal());
        assertEquals("Incorrect class name specified", "com.proximity.library.ProximityControl", TuneSmartWhereForTest.capturedClassNameString);
    }

    @Test
    public void testIsProximityInstalledReturnsTrueWhenProximityControlClassIsFound() throws Exception {
        TuneSmartWhereForTest.clazz = this.getClass();

        assertTrue(testObj.isSmartWhereAvailableInternal());
        assertEquals("Incorrect class name specified", "com.proximity.library.ProximityControl", TuneSmartWhereForTest.capturedClassNameString);
    }

    @Test
    public void testStartMonitoringConfiguresWithAdIdAndConversionKey() throws Exception {
        String addId = "addId";
        String conversionKey = "conversionKey";

        testObj.startMonitoring(context, addId, conversionKey, false);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("API_KEY"));
        assertEquals(actualConfig.get("API_KEY"), addId);
        assertTrue(actualConfig.containsKey("API_SECRET"));
        assertEquals(actualConfig.get("API_SECRET"), conversionKey);
        assertTrue(actualConfig.containsKey("APPLICATION_ID"));
        assertEquals(actualConfig.get("APPLICATION_ID"), addId);
    }

    @Test
    public void testStartMonitoringSetsDebugLoggingWhenTuneLoggingIsEnabled() throws Exception {
        String addId = "addId";
        String conversionKey = "conversionKey";

        testObj.startMonitoring(context, addId, conversionKey, true);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("DEBUG_LOG"));
        assertEquals(actualConfig.get("DEBUG_LOG"), "true");
    }

    @Test
    public void testStartMonitoringSetsProximityNotificationServiceName() throws Exception {
        String addId = "addId";
        String conversionKey = "conversionKey";

        testObj.startMonitoring(context, addId, conversionKey, false);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("NOTIFICATION_HANDLER_SERVICE"));
        assertEquals(actualConfig.get("NOTIFICATION_HANDLER_SERVICE"), "com.tune.smartwhere.TuneSmartWhereNotificationService");
    }

    @Test
    public void testStartMonitoringSetsPermissionPromptingOff() throws Exception {
        String addId = "addId";
        String conversionKey = "conversionKey";

        testObj.startMonitoring(context, addId, conversionKey, false);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("PROMPT_FOR_LOCATION_PERMISSION"));
        assertEquals(actualConfig.get("PROMPT_FOR_LOCATION_PERMISSION"), "false");
    }

    @Test
    public void testStartMonitoringSetsServiceAutoStartOn() throws Exception {
        String addId = "addId";
        String conversionKey = "conversionKey";

        testObj.startMonitoring(context, addId, conversionKey, false);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("SERVICE_AUTO_START"));
        assertEquals(actualConfig.get("SERVICE_AUTO_START"), "true");
    }

    @Test
    public void testStartMonitoringSetsGeofenceRangingOn() throws Exception {
        String appId = "addId";
        String conversionKey = "conversionKey";

        testObj.startMonitoring(context, appId, conversionKey, false);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("ENABLE_GEOFENCE_RANGING"));
        assertEquals(actualConfig.get("ENABLE_GEOFENCE_RANGING"), "true");
    }

    @Test
    public void testStartMonitoringStartsService() throws Exception {
        String addId = "addId";
        String conversionKey = "conversionKey";

        testObj.startMonitoring(context, addId, conversionKey, false);

        assertTrue(FakeProximityControl.hasStartServiceBeenCalled);
    }

    @Test
    public void testSetPackageNameCallsConfigureServiceWithPackageName() throws Exception {
        String packageName = "com.set.package.name";
        testObj.setPackageName(context, packageName);
        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("PACKAGE_NAME"));
        assertEquals(actualConfig.get("PACKAGE_NAME"), packageName);
    }

    @Test
    public void testStopMonitoringSetsServiceAutoStartOff() throws Exception {
        testObj.stopMonitoring(context);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("SERVICE_AUTO_START"));
        assertEquals(actualConfig.get("SERVICE_AUTO_START"), "false");
    }

    @Test
    public void testStopMonitoringStopsService() throws Exception {
        testObj.stopMonitoring(context);

        assertTrue(FakeProximityControl.hasStopServiceBeenCalled);
    }

    @Test
    public void testSetDebugModeSetsDebugLoggingWhenTrue() throws Exception {
        testObj.setDebugMode(context, true);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("DEBUG_LOG"));
        assertEquals(actualConfig.get("DEBUG_LOG"), "true");
    }

    @Test
    public void testSetDebugModeSetsDebugLoggingWhenFalse() throws Exception {
        testObj.setDebugMode(context, false);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("DEBUG_LOG"));
        assertEquals(actualConfig.get("DEBUG_LOG"), "false");
    }

    @Test
    public void testProcessMappedEventCallsOnSmartWhereWhenAvailable() throws Exception {
        TuneEvent event = new TuneEvent(ADD_TO_CART);

        testObj.processMappedEvent(context,event);

        assertTrue(FakeProximityControl.hasProcessMappedEventBeenCalled);
        assertEquals(context, FakeProximityControl.context);
        assertEquals(ADD_TO_CART, FakeProximityControl.capturedEventId);

    }

    @Test
    public void testProcessMappedEventDoesntCallOnSmartWhereForSessionEvents() throws Exception {
        TuneEvent event = new TuneEvent(NAME_SESSION);

        testObj.processMappedEvent(context,event);

        assertFalse(FakeProximityControl.hasProcessMappedEventBeenCalled);
    }

    @Test
    public void testProcessMappedEventDoesntCallOnSmartWhereWhenNotAvailable() throws Exception {
        TuneSmartWhereForTest.clazz = null;

        TuneEvent event = new TuneEvent(ADD_TO_CART);

        testObj.processMappedEvent(context,event);

        assertFalse(FakeProximityControl.hasProcessMappedEventBeenCalled);
    }

    @Test
    public void testProcessMappedEventDoesntCallOnSmartWhereWhenMethodNotFound() throws Exception {
        TuneSmartWhereForTest.clazz = Object.class;

        TuneEvent event = new TuneEvent(ADD_TO_CART);

        testObj.processMappedEvent(context,event);

        assertFalse(FakeProximityControl.hasProcessMappedEventBeenCalled);

    }
}

class TuneSmartWhereForTest extends TuneSmartWhere {
    static Class clazz;
    static String capturedClassNameString;

    public static synchronized TuneSmartWhere getInstance() {
        clazz = FakeProximityControl.class;
        return new TuneSmartWhereForTest();
    }

    @Override
    protected Class classForName(String name) {
        TuneSmartWhereForTest.capturedClassNameString = name;
        return clazz;
    }
}

@SuppressWarnings("unused")
class FakeProximityControl {
    @SuppressLint("StaticFieldLeak")
    static Context context;
    private static Object proximityNotification;
    private static String code;
    static HashMap capturedConfig;
    private static boolean permissionResult;
    static String capturedEventId;

    private static boolean hasFireNotificationBeenCalled;
    private static boolean hasProcessScanBeenCalled;
    static boolean hasStartServiceBeenCalled;
    static boolean hasStopServiceBeenCalled;
    static boolean hasConfigureServiceBeenCalled;
    private static boolean hasSetPermissionRquestResultBeenCalled;
    static boolean hasProcessMappedEventBeenCalled;

    static void reset() {
        FakeProximityControl.permissionResult = false;
        FakeProximityControl.context = null;
        FakeProximityControl.capturedConfig = null;
        FakeProximityControl.proximityNotification = null;
        FakeProximityControl.code = null;
        FakeProximityControl.capturedEventId = null;

        FakeProximityControl.hasFireNotificationBeenCalled = false;
        FakeProximityControl.hasProcessScanBeenCalled = false;
        FakeProximityControl.hasStartServiceBeenCalled = false;
        FakeProximityControl.hasStopServiceBeenCalled = false;
        FakeProximityControl.hasConfigureServiceBeenCalled = false;
        FakeProximityControl.hasSetPermissionRquestResultBeenCalled = false;
        FakeProximityControl.hasProcessMappedEventBeenCalled = false;
    }

    public static void fireNotification(Context context, Object proximityNotification) {
        hasFireNotificationBeenCalled = true;
        FakeProximityControl.context = context;
        FakeProximityControl.proximityNotification = proximityNotification;
    }

    public static void processScan(Context context, String code) {
        hasProcessScanBeenCalled = true;
        FakeProximityControl.context = context;
        FakeProximityControl.code = code;
    }

    public static void startService(Context context) {
        hasStartServiceBeenCalled = true;
        FakeProximityControl.context = context;
    }

    public static void stopService(Context context) {
        hasStopServiceBeenCalled = true;
        FakeProximityControl.context = context;
    }

    public static void configureService(Context context, HashMap config) {
        hasConfigureServiceBeenCalled = true;
        FakeProximityControl.context = context;
        FakeProximityControl.capturedConfig = config;
    }

    public static void setPermissionRequestResult(Context context, boolean permissionResult) {
        hasSetPermissionRquestResultBeenCalled = true;
        FakeProximityControl.context = context;
        FakeProximityControl.permissionResult = permissionResult;
    }

    public static void processMappedEvent(Context context, String eventId) {
        hasProcessMappedEventBeenCalled = true;
        FakeProximityControl.context = context;
        FakeProximityControl.capturedEventId = eventId;
    }

}