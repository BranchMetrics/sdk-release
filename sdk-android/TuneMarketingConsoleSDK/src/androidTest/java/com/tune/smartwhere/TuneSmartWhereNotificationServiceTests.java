package com.tune.smartwhere;

import android.content.Context;
import android.content.Intent;
import android.support.annotation.NonNull;

import com.tune.TuneUnitTest;

import java.io.Serializable;
import java.util.HashMap;

/**
 * Created by gordon stewart on 8/18/16.
 *
 * @author gordon@smartwhere.com
 */

public class TuneSmartWhereNotificationServiceTests extends TuneUnitTest {
    TuneSmartWhereNotificationService testObj;
    Context context;

    @Override
    public void setUp() throws Exception {
        super.setUp();
        context = getContext();

        testObj = new TuneSmartWhereNotificationService();
    }

    @Override
    public void tearDown() throws Exception {
        super.tearDown();
    }

    public void testOnHandleIntentChecksForProximityNotification() throws Exception {
        Class targetClass = TuneSmartWhereNotificationService.class;
        Object tuneProximityEvent = new FakeTuneSmartWhereEvent();
        Object tuneProximityNotification = createProximityNotification(10, new Object(), tuneProximityEvent);
        Intent notificationIntent = new Intent(context, targetClass);
        notificationIntent.setAction("proximity-notification");
        notificationIntent.putExtra("proximityNotification", (Serializable) tuneProximityNotification);

        testObj.onHandleIntent(notificationIntent);

        assertTrue(FakeSmartWhereNotification.hasGetTitleBeenCalled);
    }

    //  Helpers
    @NonNull
    private Object createProximityNotification(int state, Object proximityObject, Object event) {
        return new FakeSmartWhereNotification(state, "title", "text", proximityObject, event);
    }
}

class FakeSmartWhereNotification implements Serializable {
    public static int state;
    public static Object event;
    public static String title;
    public static String message;
    public static Object proximityObject;

    public static boolean hasGetEventBeenCalled;
    public static boolean hasGetTitleBeenCalled;
    public static boolean hasGetMessageBeenCalled;
    public static boolean hasGetProximityObjectBeenCalled;

    public FakeSmartWhereNotification(int state, String title, String text, Object proximityObject, Object event) {
        FakeSmartWhereNotification.title = title;
        FakeSmartWhereNotification.message = text;
        FakeSmartWhereNotification.event = event;
        FakeSmartWhereNotification.proximityObject = proximityObject;
        FakeSmartWhereNotification.state = state;

        FakeSmartWhereNotification.hasGetProximityObjectBeenCalled = false;
        FakeSmartWhereNotification.hasGetMessageBeenCalled = false;
        FakeSmartWhereNotification.hasGetTitleBeenCalled = false;
        FakeSmartWhereNotification.hasGetEventBeenCalled = false;
    }

    public Object getEvent() {
        hasGetEventBeenCalled = true;
        return event;
    }

    @SuppressWarnings("unused")
    public String getTitle() {
        hasGetTitleBeenCalled = true;
        return title;
    }

    @SuppressWarnings("unused")
    public String getMessage() {
        hasGetMessageBeenCalled = true;
        return message;
    }

    @SuppressWarnings("unused")
    public Object getProximityObject() {
        hasGetProximityObjectBeenCalled = true;
        return proximityObject;
    }
}

class FakeTuneSmartWhereEvent implements Serializable {
    public static String title;
    public static HashMap<String, String> variables;

    public static boolean hasGetVariablesBeenCalled;
    public static boolean hasGetTitleBeenCalled;
    public static boolean hasSetTitleBeenCalled;

    public FakeTuneSmartWhereEvent() {
        title = null;
        variables = null;
        hasGetTitleBeenCalled = false;
        hasGetVariablesBeenCalled = false;
        hasSetTitleBeenCalled = false;
    }

    @SuppressWarnings("unused")
    public HashMap<String, String> getVariables() {
        return variables;
    }

    @SuppressWarnings("unused")
    public String getTitle() {
        return title;
    }

    @SuppressWarnings("unused")
    public void setTitle(String title) {
        FakeTuneSmartWhereEvent.title = title;
    }
}
