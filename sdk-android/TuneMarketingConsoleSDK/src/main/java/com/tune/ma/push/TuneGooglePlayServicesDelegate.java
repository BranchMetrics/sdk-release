package com.tune.ma.push;

import android.content.Context;
import android.content.Intent;

import java.lang.reflect.Method;

/**
 * Created by charlesgilliam on 2/9/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneGooglePlayServicesDelegate {
    /*
     * Private Helpers
     */

    private static Class getGoogleCloudMessaging() throws Exception {
        return getClass("com.google.android.gms.gcm.GoogleCloudMessaging");
    }

    private static Class getGooglePlayServicesUtil() throws Exception {
        return getClass("com.google.android.gms.common.GooglePlayServicesUtil");
    }

    private static Class getConnectionResult() throws Exception {
        return getClass("com.google.android.gms.common.ConnectionResult");
    }

    private static Class getGoogleApiAvailability() throws Exception {
        return getClass("com.google.android.gms.common.GoogleApiAvailability");
    }

    private static Class getClass(String className) throws Exception {
        return Class.forName(className);
    }

    /*
     * Public Delegated Calls
     */

    public static Object getGCMInstance(Context context) throws Exception {
        // Performs: GoogleCloudMessaging gcm = GoogleCloudMessaging.getInstance(context);.
        Method gcmGetter = getGoogleCloudMessaging().getMethod("getInstance", Context.class);
        Object[] gcmGetterArgs = new Object[1];
        gcmGetterArgs[0] = context;
        Object result = gcmGetter.invoke(null, gcmGetterArgs);

        return result;
    }

    public static String registerGCM(Object gcm, String pushSenderId) throws Exception {
        // Performs: registrationId = gcm.register(notificationSettings.getPushSenderId());
        Method gcmRegister = getGoogleCloudMessaging().getMethod("register", String[].class);
        Object[] gcmRegisterArgs = new Object[1];
        gcmRegisterArgs[0] = new String[]{pushSenderId};
        return (String) gcmRegister.invoke(gcm, gcmRegisterArgs);
    }

    public static void unregisterGCM(Object gcm) throws Exception {
        // Performs: gcm.unregister();
        Method gcmUnregister = getGoogleCloudMessaging().getMethod("unregister");
        // TODO: Using gcm.unregister() is deprecated
        gcmUnregister.invoke(gcm);
    }

    public static String getMessageType(Object gcm, Intent intent) throws Exception {
        // Performs: String messageType = gcm.getMessageType(intent);
        Method gcmGetMessageType = getGoogleCloudMessaging().getMethod("getMessageType", Intent.class);
        Object[] gcmGetMessageTypeArgs = new Object[1];
        gcmGetMessageTypeArgs[0] = intent;
        return (String) gcmGetMessageType.invoke(gcm, gcmGetMessageTypeArgs);
    }

    public static String getGoogleCloudMessagingMessageTypeMessageField() throws Exception {
        // Performs: String gcmMessageType = GoogleCloudMessaging.MESSAGE_TYPE_MESSAGE;
        // We can do '.get(null)' because the field is static so the argument is ignored
        // TODO: Using GoogleCloudMessaging.MESSAGE_TYPE_MESSAGE is deprecated
        return (String) getGoogleCloudMessaging().getField("MESSAGE_TYPE_MESSAGE").get(null);
    }

    private static Object getGoogleApiAvailabilityInstance() throws Exception {
        // Performs: GoogleApiAvailability result = GoogleApiAvailability.getInstance();.
        Method gcmGetter = getGoogleApiAvailability().getMethod("getInstance");
        Object result = gcmGetter.invoke(null);

        return result;
    }

    public static boolean isUserRecoverable(int error) throws Exception {
        // Performs: Boolean result = googleApiAvailabilityInstance.isUserRecoverableError(errorCode);
        Method method = getGooglePlayServicesUtil().getMethod("isUserRecoverableError", int.class);
        Object[] args = new Object[1];
        args[0] = error;
        Boolean result = (Boolean) method.invoke(getGoogleApiAvailabilityInstance(), args);
        return result.booleanValue();
    }

    private static Object getAppOpsManager(Context context) throws Exception {
        // NOTE: The annotation on the argument for "getSystemService" treats the string like an enum, so since we are getting the
        //       argument reflexively, we need to call the method reflexively.
        Method method = Context.class.getMethod("getSystemService", String.class);
        Object[] args = new Object[1];
        args[0] = Context.class.getField("APP_OPS_SERVICE").get(null);
        Object mAppOps = method.invoke(context, args);
        return mAppOps;
    }

    public static int isNotificationEnabled(Context context) throws Exception {
        Method checkOpNoThrowMethod = Class.forName("android.app.AppOpsManager").getMethod("checkOpNoThrow", Integer.TYPE, Integer.TYPE, String.class);
        Object[] args = new Object[3];
        args[0] = Class.forName("android.app.AppOpsManager").getDeclaredField("OP_POST_NOTIFICATION").get(Integer.class);
        args[1] = context.getApplicationInfo().uid;
        args[2] = context.getApplicationContext().getPackageName();

        return (int)checkOpNoThrowMethod.invoke(getAppOpsManager(context), args);
    }

    public static int getAppOpsManagerModeAllowed() throws Exception {
        int result = (int) Class.forName("android.app.AppOpsManager").getField("MODE_ALLOWED").get(null);
        return result;
    }
}
