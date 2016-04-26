package com.tune.ma.utils;

import android.util.Log;

import com.tune.Tune;
import com.tune.ma.TuneIAMConfigurationException;

public class TuneDebugLog {
    // In order of Log Level
    // Log Level- VERBOSE; use TuneDebugLog.v()
    public static final int VERBOSE = 0;

    // Log Level- DEBUG; use TuneDebugLog.d()
    public static final int DEBUG = 1;

    // Log Level- INFO; use TuneDebugLog.i()
    public static final int INFO = 2;

    // Log Level- WARN; use TuneDebugLog.w()
    public static final int WARN = 3;

    // Log Level- ERROR; use TuneDebugLog.e()
    public static final int ERROR = 4;

    /**
     * Enable or Disable Logging
     */
    private static boolean enableLog = true;

    private static final String STARS = "*******";

    /**
     * All logs >= logLevel will be printed
     */
    public static int logLevel = ERROR;

    // Log an important message with *'s as an identifier
    public static void important(String msg) {
        d(getTag(), STARS + " " + msg + " " + STARS);
    }

    public static void i(String msg) {
        i(getTag(), msg);
    }

    public static void i(String msg, Throwable tr) {
        i(getTag(), msg, tr);
    }

    public static void i(String tag, String msg) {
        if (!enableLog || logLevel > INFO)
            return;

        // Add our tag also
        tag = tag + getTag();

        Log.i(tag, msg);
    }

    public static void i(String tag, String msg, Throwable tr) {
        if (!enableLog || logLevel > INFO)
            return;

        // Add our tag also
        tag = tag + getTag();

        Log.i(tag, msg, tr);
    }

    public static void v(String msg) {
        v(getTag(), msg);
    }

    public static void v(String msg, Throwable tr) {
        v(getTag(), msg, tr);
    }

    public static void v(String tag, String msg) {
        if (!enableLog || logLevel > VERBOSE)
            return;

        // Add our tag also
        tag = tag + getTag();

        Log.v(tag, msg);
    }

    public static void v(String tag, String msg, Throwable tr) {
        if (!enableLog || logLevel > VERBOSE)
            return;

        // Add our tag also
        tag = tag + getTag();
        Log.v(tag, msg, tr);
    }

    public static void d(String msg) {
        d(getTag(), msg);
    }

    public static void d(String msg, Throwable tr) {
        d(getTag(), msg, tr);
    }

    public static void d(String tag, String msg) {
        if (!enableLog || logLevel > DEBUG)
            return;

        // Add our tag also
        tag = tag + getTag();

        Log.d(tag, msg);
    }

    public static void d(String tag, String msg, Throwable tr) {
        if (!enableLog || logLevel > DEBUG)
            return;

        // Add our tag also
        tag = tag + getTag();

        Log.d(tag, msg, tr);
    }

    public static void w(String msg) {
        w(getTag(), msg);
    }

    public static void w(String msg, Throwable tr) {
        w(getTag(), msg, tr);
    }

    public static void w(String tag, String msg) {
        if (!enableLog || logLevel > WARN)
            return;

        // Add our tag also
        tag = tag + getTag();

        Log.w(tag, msg);
    }

    public static void w(String tag, String msg, Throwable tr) {
        if (!enableLog || logLevel > WARN)
            return;

        // Add our tag also
        tag = tag + getTag();

        Log.w(tag, msg, tr);
    }

    public static void e(String msg) {
        e(getTag(), msg);
    }

    public static void e(String msg, Throwable tr) {
        e(getTag(), msg, tr);
    }

    public static void e(String tag, String msg) {
        if (!enableLog || logLevel > ERROR)
            return;

        // Add our tag also
        tag = tag + getTag();

        Log.e(tag, msg);
    }

    public static void e(String tag, String msg, Throwable tr) {
        if (!enableLog || logLevel > ERROR)
            return;

        // Add our tag also
        tag = tag + getTag();

        Log.e(tag, msg, tr);
    }

    private static final int ENTRY_MAX_LEN = 4000;
    public static void alwaysLog(String msg) {
        // Logcat can only print out a certain number of bytes this a problem when we print out really long lines like analytics events
        // This solution comes from: http://stackoverflow.com/a/17308948/2336149
        while (!msg.isEmpty()) {
            int lastNewLine = msg.lastIndexOf('\n', ENTRY_MAX_LEN);
            int nextEnd = lastNewLine != -1 ? lastNewLine : Math.min(ENTRY_MAX_LEN, msg.length());
            String next = msg.substring(0, nextEnd /*exclusive*/);
            Log.i(getTag(), next);
            if (lastNewLine != -1) {
                // Don't print out the \n twice.
                msg = msg.substring(nextEnd+1);
            } else {
                msg = msg.substring(nextEnd);
            }
        }
    }

    static String getTag() {
        return getTag(5);
    }

    static String getTag(int level) {
        StackTraceElement[] trace = Thread.currentThread().getStackTrace();
        String fullClassName = trace[level].getClassName();
        String className = fullClassName.substring(fullClassName.lastIndexOf(".") + 1);
        String methodName = trace[level].getMethodName();
        int lineNumber = trace[level].getLineNumber();
        if (className.equals("TuneDebugLog")) {
            return "";
        } else if (trace[level].toString().contains("EventHandler_")) {
            return className + " @ line: " + lineNumber;
        } else {
            return (className + "#" + methodName + "():" + lineNumber);
        }
    }

    public static boolean isEnableLog() {
        return TuneDebugLog.enableLog;
    }

    public static void enableLog() {
        enableLog = true;
    }

    public static void disableLog() {
        enableLog = false;
    }

    public static void setLogLevel(int level) {
        logLevel = level;
    }

    public static void IAMConfigError(String message) {
        if (Tune.getInstance() != null && Tune.getInstance().isInDebugMode()) {
            throw new TuneIAMConfigurationException(message);
        } else {
            e(getTag(5), message);
        }
    }
}
