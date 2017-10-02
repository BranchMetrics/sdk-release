package com.tune.smartwhere;

import android.annotation.SuppressLint;
import android.content.Context;

import com.tune.TuneEvent;
import com.tune.TuneUnitTest;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;

import java.util.HashMap;
import java.util.HashSet;

import static com.tune.TuneEvent.ADD_TO_CART;
import static com.tune.TuneEvent.NAME_SESSION;
import static org.mockito.Matchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;


/**
 * Created by gordonstewart on 8/17/16.
 *
 * @author gordon@smartwhere.com
 */

public class TuneSmartWhereTests extends TuneUnitTest {

    private TuneSmartWhere testObj;
    private Context context;
    private TuneSmartWhereFakeAttribute mockAttribute;

    @Override
    public void setUp() throws Exception {
        super.setUp();
        FakeProximityControl.reset();

        mockAttribute = mock(TuneSmartWhereFakeAttribute.class);
        TuneSmartWhereFakeAttribute.instance = mockAttribute;

        context = getContext();

        testObj = TuneSmartWhereForTest.getInstance();
    }

    @Override
    public void tearDown() throws Exception {
        super.tearDown();
        TuneSmartWhereForTest.setInstance(null);
    }

    public void testIsProximityInstalledReturnsFalseWhenProximityControlClassNotFound() throws Exception {
        TuneSmartWhereForTest.proximityControlClass = null;

        assertFalse(testObj.isSmartWhereAvailableInternal());
        assertEquals("Incorrect class name specified", "com.proximity.library.ProximityControl", TuneSmartWhereForTest.capturedClassNameString);
    }

    public void testIsProximityInstalledReturnsTrueWhenProximityControlClassIsFound() throws Exception {
        TuneSmartWhereForTest.proximityControlClass = this.getClass();

        assertTrue(testObj.isSmartWhereAvailableInternal());
        assertEquals("Incorrect class name specified", "com.proximity.library.ProximityControl", TuneSmartWhereForTest.capturedClassNameString);
    }

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

    public void testStartMonitoringSetsDebugLoggingWhenTuneLoggingIsEnabled() throws Exception {
        String addId = "addId";
        String conversionKey = "conversionKey";

        testObj.startMonitoring(context, addId, conversionKey, true);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("DEBUG_LOG"));
        assertEquals(actualConfig.get("DEBUG_LOG"), "true");
    }

    public void testStartMonitoringSetsProximityNotificationServiceName() throws Exception {
        String addId = "addId";
        String conversionKey = "conversionKey";

        testObj.startMonitoring(context, addId, conversionKey, false);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("NOTIFICATION_HANDLER_SERVICE"));
        assertEquals(actualConfig.get("NOTIFICATION_HANDLER_SERVICE"), "com.tune.smartwhere.TuneSmartWhereNotificationService");
    }

    public void testStartMonitoringSetsPermissionPromptingOff() throws Exception {
        String addId = "addId";
        String conversionKey = "conversionKey";

        testObj.startMonitoring(context, addId, conversionKey, false);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("PROMPT_FOR_LOCATION_PERMISSION"));
        assertEquals(actualConfig.get("PROMPT_FOR_LOCATION_PERMISSION"), "false");
    }

    public void testStartMonitoringSetsServiceAutoStartOn() throws Exception {
        String addId = "addId";
        String conversionKey = "conversionKey";

        testObj.startMonitoring(context, addId, conversionKey, false);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("SERVICE_AUTO_START"));
        assertEquals(actualConfig.get("SERVICE_AUTO_START"), "true");
    }

    public void testStartMonitoringSetsGeofenceRangingOn() throws Exception {
        String appId = "addId";
        String conversionKey = "conversionKey";

        testObj.startMonitoring(context, appId, conversionKey, false);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("ENABLE_GEOFENCE_RANGING"));
        assertEquals(actualConfig.get("ENABLE_GEOFENCE_RANGING"), "true");
    }

    public void testStartMonitoringStartsService() throws Exception {
        String addId = "addId";
        String conversionKey = "conversionKey";

        testObj.startMonitoring(context, addId, conversionKey, false);

        assertTrue(FakeProximityControl.hasStartServiceBeenCalled);
    }

    public void testSetPackageNameCallsConfigureServiceWithPackageName() throws Exception {
        String packageName = "com.set.package.name";
        testObj.setPackageName(context, packageName);
        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("PACKAGE_NAME"));
        assertEquals(actualConfig.get("PACKAGE_NAME"), packageName);
    }

    public void testStopMonitoringSetsServiceAutoStartOff() throws Exception {
        testObj.stopMonitoring(context);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("SERVICE_AUTO_START"));
        assertEquals(actualConfig.get("SERVICE_AUTO_START"), "false");
    }

    public void testStopMonitoringStopsService() throws Exception {
        testObj.stopMonitoring(context);

        assertTrue(FakeProximityControl.hasStopServiceBeenCalled);
    }

    public void testSetDebugModeSetsDebugLoggingWhenTrue() throws Exception {
        testObj.setDebugMode(context, true);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("DEBUG_LOG"));
        assertEquals(actualConfig.get("DEBUG_LOG"), "true");
    }

    public void testSetDebugModeSetsDebugLoggingWhenFalse() throws Exception {
        testObj.setDebugMode(context, false);

        HashMap actualConfig = FakeProximityControl.capturedConfig;
        assertTrue(FakeProximityControl.hasConfigureServiceBeenCalled);
        assertTrue(actualConfig.containsKey("DEBUG_LOG"));
        assertEquals(actualConfig.get("DEBUG_LOG"), "false");
    }

    public void testProcessMappedEventCallsOnSmartWhereWhenAvailable() throws Exception {
        TuneEvent event = new TuneEvent(ADD_TO_CART);

        testObj.processMappedEvent(context,event);

        assertTrue(FakeProximityControl.hasProcessMappedEventBeenCalled);
        assertEquals(context, FakeProximityControl.context);
        assertEquals(ADD_TO_CART, FakeProximityControl.capturedEventId);

    }

    public void testProcessMappedEventDoesntCallOnSmartWhereForSessionEvents() throws Exception {
        TuneEvent event = new TuneEvent(NAME_SESSION);

        testObj.processMappedEvent(context,event);

        assertFalse(FakeProximityControl.hasProcessMappedEventBeenCalled);
    }

    public void testProcessMappedEventDoesntCallOnSmartWhereWhenNotAvailable() throws Exception {
        TuneSmartWhereForTest.proximityControlClass = null;

        TuneEvent event = new TuneEvent(ADD_TO_CART);

        testObj.processMappedEvent(context,event);

        assertFalse(FakeProximityControl.hasProcessMappedEventBeenCalled);
    }

    public void testProcessMappedEventDoesntCallOnSmartWhereWhenMethodNotFound() throws Exception {
        TuneSmartWhereForTest.proximityControlClass = Object.class;

        TuneEvent event = new TuneEvent(ADD_TO_CART);

        testObj.processMappedEvent(context,event);

        assertFalse(FakeProximityControl.hasProcessMappedEventBeenCalled);

    }

    public void testsetAttributeValueFromAnalyticsVariableCallsOnSmartWhereAttributeClass() throws Exception {
        String expectedVariableName = "expectedName";
        String expectedValue = "expectedValue";

        TuneAnalyticsVariable analyticsVariable = new TuneAnalyticsVariable(expectedVariableName, expectedValue);

        testObj.setAttributeValueFromAnalyticsVariable(context, analyticsVariable);

        verify(mockAttribute).setAttributeValue(TuneSmartWhere.TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX + expectedVariableName, expectedValue);
    }

    public void testsetAttributeValueFromAnalyticsVariableDoesntCallSmartWhereWhenAttributeClassIsNotFound() throws Exception {
        TuneSmartWhereForTest.attributeClass = null;
        String expectedVariableName = "expectedName";
        String expectedValue = "expectedValue";

        TuneAnalyticsVariable analyticsVariable = new TuneAnalyticsVariable(expectedVariableName, expectedValue);

        testObj.setAttributeValueFromAnalyticsVariable(context, analyticsVariable);

        verify(mockAttribute, never()).setAttributeValue(anyString(), anyString());
    }

    public void testsetAttributeFromAnalyticsVariableDoesntCallSmartWhereWhenMethodNotFound() throws Exception {
        TuneSmartWhereForTest.attributeClass = Object.class;
        String expectedVariableName = "expectedName";
        String expectedValue = "expectedValue";

        TuneAnalyticsVariable analyticsVariable = new TuneAnalyticsVariable(expectedVariableName, expectedValue);

        testObj.setAttributeValueFromAnalyticsVariable(context, analyticsVariable);

        verify(mockAttribute, never()).setAttributeValue(anyString(), anyString());
    }

    public void testsetAttributeFromAnalyticsVariableChecksThatTheNameExists() throws Exception {
        String expectedValue = "expectedValue";

        TuneAnalyticsVariable analyticsVariable = new TuneAnalyticsVariable(null, expectedValue);

        testObj.setAttributeValueFromAnalyticsVariable(context, analyticsVariable);

        verify(mockAttribute, never()).setAttributeValue(anyString(), anyString());

        analyticsVariable = new TuneAnalyticsVariable("", expectedValue);

        testObj.setAttributeValueFromAnalyticsVariable(context, analyticsVariable);

        verify(mockAttribute, never()).setAttributeValue(anyString(), anyString());
    }

    public void testsetAttributeFromAnalyticsVariableRemovesTheAttributeIfTheValueIsNull() throws Exception {
        String expectedVariableName = "expectedName";

        TuneAnalyticsVariable analyticsVariable = new TuneAnalyticsVariable(expectedVariableName, (String) null);

        testObj.setAttributeValueFromAnalyticsVariable(context, analyticsVariable);

        verify(mockAttribute).removeAttributeValue(TuneSmartWhere.TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX + expectedVariableName);
    }

    public void testsetAttributeValuesFromEventTagsCallsSmartWhere() throws Exception {
        String expectedName = "name";
        String expectedValue = "value";

        TuneEvent event = new TuneEvent(TuneEvent.PURCHASE)
                .withRevenue(0.99)
                .withCurrencyCode("USD")
                .withAdvertiserRefId("12999azzzx748531")
                .withTagAsString(expectedName, expectedValue);

        testObj.setAttributeValuesFromEventTags(context, event);

        verify(mockAttribute).setAttributeValue(TuneSmartWhere.TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX+expectedName, expectedValue);
    }

    public void testsetAttributeValuesFromEventTagsCallSmartWhereForEachTag() throws Exception {
        String expectedName = "name";
        String expectedValue = "value";
        String expectedName2 = "name2";
        String expectedValue2 = "value2";

        TuneAnalyticsVariable analyticsVariable = new TuneAnalyticsVariable(expectedName, expectedValue);
        TuneAnalyticsVariable analyticsVariable2 = new TuneAnalyticsVariable(expectedName2, expectedValue2);

        TuneEvent mockEvent = mock(TuneEvent.class);
        HashSet<TuneAnalyticsVariable> tags = new HashSet<>();
        tags.add(analyticsVariable);
        tags.add(analyticsVariable2);

        when(mockEvent.getTags()).thenReturn(tags);

        testObj.setAttributeValuesFromEventTags(context, mockEvent);

        verify(mockAttribute).setAttributeValue(TuneSmartWhere.TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX + expectedName, expectedValue);
        verify(mockAttribute).setAttributeValue(TuneSmartWhere.TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX + expectedName2, expectedValue2);
    }

    public void testsetAttributeValuesFromEventTagsDoesntCallSmartWhereWhenNotAvailable() throws Exception {
        TuneSmartWhereForTest.attributeClass = null;
        String expectedName = "name";
        String expectedValue = "value";

        TuneEvent event = new TuneEvent(TuneEvent.PURCHASE)
                .withRevenue(0.99)
                .withCurrencyCode("USD")
                .withAdvertiserRefId("12999azzzx748531")
                .withTagAsString(expectedName, expectedValue);

        testObj.setAttributeValuesFromEventTags(context, event);

        verify(mockAttribute, never()).setAttributeValue(anyString(),anyString());
    }

    public void testclearAttributeValueCallsSmartWhereToRemoveObject() throws Exception {
        String expectedName = "expectedName";
        testObj.clearAttributeValue(context, expectedName);

        verify(mockAttribute).removeAttributeValue(TuneSmartWhere.TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX + expectedName);
    }

    public void testclearAttributeValueDoesntCallSmartWhereWhenNotAvailable() throws Exception {
        TuneSmartWhereForTest.attributeClass = null;

        String expectedName = "expectedName";
        testObj.clearAttributeValue(context, expectedName);

        verify(mockAttribute,never()).removeAttributeValue(anyString());
    }

    public void testclearAllAttributeValuesCallsSmartWhereForEachValueWithTunePrefix() throws Exception {
        HashMap<String,String> currentlySetAttributes = new HashMap<String,String>(){{
            put("key1","value1");
            put("key2","value2");
            put("key3","value3");
            put(TuneSmartWhere.TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX + "key1","doesnt matter");
            put(TuneSmartWhere.TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX + "key2","tune value 2");
        }};

        when(mockAttribute.getAttributes()).thenReturn(currentlySetAttributes);

        testObj.clearAllAttributeValues(context);

        verify(mockAttribute,never()).removeAttributeValue("key1");
        verify(mockAttribute,never()).removeAttributeValue("key2");
        verify(mockAttribute,never()).removeAttributeValue("key3");
        verify(mockAttribute).removeAttributeValue(TuneSmartWhere.TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX + "key1");
        verify(mockAttribute).removeAttributeValue(TuneSmartWhere.TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX + "key2");

    }

    public void testclearAllAttributeValuesDoesntCallSmartWhereWhenNotAvailable() throws Exception {
        TuneSmartWhereForTest.attributeClass = null;
        HashMap<String,String> currentlySetAttributes = new HashMap<String,String>(){{
            put("key1","value1");
            put("key2","value2");
            put("key3","value3");
            put(TuneSmartWhere.TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX + "key1","doesnt matter");
            put(TuneSmartWhere.TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX + "key2","tune value 2");
        }};

        when(mockAttribute.getAttributes()).thenReturn(currentlySetAttributes);

        testObj.clearAllAttributeValues(context);

        verify(mockAttribute,never()).removeAttributeValue(anyString());
    }
}

class TuneSmartWhereForTest extends TuneSmartWhere {
    static Class proximityControlClass;
    static Class attributeClass;
    static String capturedClassNameString;

    public static synchronized TuneSmartWhere getInstance() {
        proximityControlClass = FakeProximityControl.class;
        attributeClass = TuneSmartWhereFakeAttribute.class;
        return new TuneSmartWhereForTest();
    }

    @Override
    protected Class classForName(String name) {
        TuneSmartWhereForTest.capturedClassNameString = name;
        if (name.equalsIgnoreCase(TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_PROXIMITYCONTROL)){
            return proximityControlClass;
        } else if (name.equalsIgnoreCase(TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_ATTRIBUTE)){
            return attributeClass;
        }
        return null;
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