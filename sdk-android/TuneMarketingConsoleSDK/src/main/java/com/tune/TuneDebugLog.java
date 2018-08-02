package com.tune;

import android.util.Log;

public class TuneDebugLog {
    private static final String TUNE_NAMESPACE = "TUNE::";
    private static final String NO_TAG = "NO_TAG";

    public enum Level {
        VERBOSE(Log.VERBOSE),
        DEBUG(Log.DEBUG),
        INFO(Log.INFO),
        WARN(Log.WARN),
        ERROR(Log.ERROR),
        ASSERT(Log.ASSERT);

        final Integer level;

        Level(Integer level) {
            this.level = level;
        }

        Boolean greaterThan(Level other) {
            return this.level > other.level;
        }
    }

    /**
     * Enable or Disable Logging
     */
    private static boolean loggingEnabled;

    /**
     * All logs &gt;= logLevel will be printed
     */
    private static Level logLevel = Level.WARN;

    public static void i(String msg) {
        i(getTag(Log.INFO), msg);
    }

    public static void i(String msg, Throwable tr) {
        i(getTag(Log.INFO), msg, tr);
    }

    public static void i(String tag, String msg) {
        if (canLog(Level.INFO)) {
            Log.i(tag, msg);
        }
    }

    public static void i(String tag, String msg, Throwable tr) {
        if (canLog(Level.INFO)) {
            Log.i(tag, msg, tr);
        }
    }

    public static void v(String msg) {
        v(getTag(Log.VERBOSE), msg);
    }

    public static void v(String msg, Throwable tr) {
        v(getTag(Log.VERBOSE), msg, tr);
    }

    public static void v(String tag, String msg) {
        if (canLog(Level.VERBOSE)) {
            Log.v(tag, msg);
        }
    }

    public static void v(String tag, String msg, Throwable tr) {
        if (canLog(Level.VERBOSE)) {
            Log.v(tag, msg, tr);
        }
    }

    public static void d(String msg) {
        d(getTag(Log.DEBUG), msg);
    }

    public static void d(String msg, Throwable tr) {
        d(getTag(Log.DEBUG), msg, tr);
    }

    public static void d(String tag, String msg) {
        if (canLog(Level.DEBUG)) {
            Log.d(tag, msg);
        }
    }

    public static void d(String tag, String msg, Throwable tr) {
        if (canLog(Level.DEBUG)) {
            Log.d(tag, msg, tr);
        }
    }

    public static void w(String msg) {
        w(getTag(Log.WARN), msg);
    }

    public static void w(String msg, Throwable tr) {
        w(getTag(Log.WARN), msg, tr);
    }

    public static void w(String tag, String msg) {
        if (canLog(Level.WARN)) {
            Log.w(tag, msg);
        }
    }

    public static void w(String tag, String msg, Throwable tr) {
        if (canLog(Level.WARN)) {
            Log.w(tag, msg, tr);
        }
    }

    public static void e(String msg) {
        e(getTag(Log.ERROR), msg);
    }

    public static void e(String msg, Throwable tr) {
        e(getTag(Log.ERROR), msg, tr);
    }

    public static void e(String tag, String msg) {
        if (canLog(Level.ERROR)) {
            Log.e(tag, msg);
        }
    }

    public static void e(String tag, String msg, Throwable tr) {
        if (canLog(Level.ERROR)) {
            Log.e(tag, msg, tr);
        }
    }

    private static final int ENTRY_MAX_LEN = 4000;
    public static void alwaysLog(String msg) {
        // Logcat can only print out a certain number of bytes this a problem when we print out really long lines like analytics events
        // This solution comes from: http://stackoverflow.com/a/17308948/2336149
        while (!msg.isEmpty()) {
            int lastNewLine = msg.lastIndexOf('\n', ENTRY_MAX_LEN);
            int nextEnd = lastNewLine != -1 ? lastNewLine : Math.min(ENTRY_MAX_LEN, msg.length());
            String next = msg.substring(0, nextEnd /*exclusive*/);

            // Always Log bypasses any level checks
            Log.i(TUNE_NAMESPACE + getTag(Log.INFO), next);

            if (lastNewLine != -1) {
                // Don't print out the \n twice.
                msg = msg.substring(nextEnd+1);
            } else {
                msg = msg.substring(nextEnd);
            }
        }
    }

    /**
     * Log with Timestamp
     * @param message Message to log
     * @param last (Optional) Last Timestamp for logging elapsed time
     * @return now, in milliseconds.  Use this for subsequent Timestamp logging
     */
    public static long logTimestamp(String message, long... last) {
        long now = System.currentTimeMillis();
        StringBuilder sb = new StringBuilder();
        sb.append("TIMESTAMP");
        sb.append("(");
        sb.append(now);
        sb.append(")");

        if (last.length > 0) {
            sb.append("\tELAPSED[");
            sb.append(now - last[0]);
        }
        for (int i = 1; i < last.length; i++) {
            sb.append("],");
            sb.append(now - last[i]);
        }
        if (last.length > 0) {
            sb.append("]");
        }
        sb.append("\t");
        sb.append(message);

        TuneDebugLog.d(sb.toString());
        return now;
    }

    /**
     * E.g. Let's say that foo() called this method, then level to tag will be:
     * 0) foo()
     * 1) callerOfFoo()
     * 2) callerOfCallerOfFoo()
     * etc.
     *
     * @param level The number of stack frames to go up above the caller's context, or 0 for the caller's context
     * @return An automatically formatted tag.
     */
    private static String getTag(int level) {
        try {
            // Add 3 to the level to skip over to
            // 0) dalvik.system.VMStack.getThreadStackTrace(Native Method)
            // 1) java.lang.Thread.getStackTrace()
            // 2) com.tune.utils.TuneDebugLog.getTag(int) [current method]
            // 3) callerOfGetTag()
            level += Log.DEBUG;
            StackTraceElement[] trace = Thread.currentThread().getStackTrace();

            if (level >= trace.length) {
                return NO_TAG;
            }

            String fullClassName = trace[level].getClassName();
            String className = fullClassName.substring(fullClassName.lastIndexOf(".") + 1);
            int lineNumber = trace[level].getLineNumber();
            if (trace[level].toString().contains("EventHandler_")) {
                return className + " @ line: " + lineNumber;
            } else {
                String methodName = trace[level].getMethodName();
                return className + "#" + methodName + "():" + lineNumber;
            }
        } catch(Exception e) {
            return NO_TAG;
        }
    }

    private static boolean isEnabled() {
        // TODO: checkConfig();
        return TuneDebugLog.loggingEnabled;
    }

    public static void enableLog() {
        loggingEnabled = true;
    }

    public static void disableLog() {
        loggingEnabled = false;
    }

    public static void setLogLevel(Level level) {
        logLevel = level;
    }

    /**
     * @param level The string to convert to the associated log level
     * @return The associated log level in {@link android.util.Log}. If not found, the current log level
     */
    public static Level stringToLevel(String level) {
        try {
            return Level.valueOf(level);
        } catch (Exception e) {
            e("Received invalid level: " + level);
            return logLevel;
        }
    }

    private static boolean canLog(Level priority) {
        return (isEnabled() && !logLevel.greaterThan(priority));
    }
}
