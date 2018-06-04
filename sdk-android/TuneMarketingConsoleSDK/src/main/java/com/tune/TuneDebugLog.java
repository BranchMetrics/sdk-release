package com.tune;

import android.util.Log;

import com.tune.ma.TuneIAMConfigurationException;

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

        private Integer level;

        Level(Integer level) {
            this.level = level;
        }

        public Boolean greaterThan(Level other) {
            return this.level > other.level;
        }
    }

    /**
     * Enable or Disable Logging
     */
    private static boolean enableLog = true;

    /**
     * All logs &gt;= logLevel will be printed
     */
    private static Level logLevel = Level.WARN;

    public static void i(String msg) {
        i(getTag(), msg);
    }

    public static void i(String msg, Throwable tr) {
        i(getTag(), msg, tr);
    }

    public static void i(String tag, String msg) {
        if (!isEnabled() || logLevel.greaterThan(Level.INFO))
            return;

        Log.i(TUNE_NAMESPACE + tag, msg);
    }

    public static void i(String tag, String msg, Throwable tr) {
        if (!isEnabled() || logLevel.greaterThan(Level.INFO))
            return;

        Log.i(TUNE_NAMESPACE + tag, msg, tr);
    }

    public static void v(String msg) {
        v(getTag(), msg);
    }

    public static void v(String msg, Throwable tr) {
        v(getTag(), msg, tr);
    }

    public static void v(String tag, String msg) {
        if (!isEnabled() || logLevel.greaterThan(Level.VERBOSE))
            return;

        Log.d(TUNE_NAMESPACE + tag, msg);
    }

    public static void v(String tag, String msg, Throwable tr) {
        if (!isEnabled() || logLevel.greaterThan(Level.VERBOSE))
            return;

        Log.d(TUNE_NAMESPACE + tag, msg, tr);
    }

    public static void d(String msg) {
        d(getTag(), msg);
    }

    public static void d(String msg, Throwable tr) {
        d(getTag(), msg, tr);
    }

    public static void d(String tag, String msg) {
        if (!isEnabled() || logLevel.greaterThan(Level.DEBUG))
            return;

        Log.d(TUNE_NAMESPACE + tag, msg);
    }

    public static void d(String tag, String msg, Throwable tr) {
        if (!isEnabled() || logLevel.greaterThan(Level.DEBUG))
            return;

        Log.d(TUNE_NAMESPACE + tag, msg, tr);
    }

    public static void w(String msg) {
        w(getTag(), msg);
    }

    public static void w(String msg, Throwable tr) {
        w(getTag(), msg, tr);
    }

    public static void w(String tag, String msg) {
        if (!isEnabled() || logLevel.greaterThan(Level.WARN))
            return;

        Log.w(TUNE_NAMESPACE + tag, msg);
    }

    public static void w(String tag, String msg, Throwable tr) {
        if (!isEnabled() || logLevel.greaterThan(Level.WARN))
            return;

        Log.w(TUNE_NAMESPACE + tag, msg, tr);
    }

    public static void e(String msg) {
        e(getTag(), msg);
    }

    public static void e(String msg, Throwable tr) {
        e(getTag(), msg, tr);
    }

    public static void e(String tag, String msg) {
        if (!isEnabled() || logLevel.greaterThan(Level.ERROR))
            return;

        Log.e(TUNE_NAMESPACE + tag, msg);
    }

    public static void e(String tag, String msg, Throwable tr) {
        if (!isEnabled() || logLevel.greaterThan(Level.ERROR))
            return;

        Log.e(TUNE_NAMESPACE + tag, msg, tr);
    }

    private static final int ENTRY_MAX_LEN = 4000;
    public static void alwaysLog(String msg) {
        // Logcat can only print out a certain number of bytes this a problem when we print out really long lines like analytics events
        // This solution comes from: http://stackoverflow.com/a/17308948/2336149
        while (!msg.isEmpty()) {
            int lastNewLine = msg.lastIndexOf('\n', ENTRY_MAX_LEN);
            int nextEnd = lastNewLine != -1 ? lastNewLine : Math.min(ENTRY_MAX_LEN, msg.length());
            String next = msg.substring(0, nextEnd /*exclusive*/);
            Log.i(TUNE_NAMESPACE + getTag(), next);
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
     * Helper for this class' log methods that don't have the tag passed in. The levels it goes up are:
     * 0) com.tune.ma.utils.TuneDebugLog.getTag() [This method]
     * 1) com.tune.ma.utils.TuneDebugLog.v/d/i/w/e with no tag
     * 2) The method calling TuneDebugLog.v/d/i/w/e with no tag
     *
     * @return The formatted tag for (5)
     */
    private static String getTag() {
        return getTag(2);
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
            // 2) com.tune.ma.utils.TuneDebugLog.getTag(int) [current method]
            // 3) callerOfGetTag()
            level += 3;
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

    public static boolean isEnabled() {
        // TODO: checkConfig();
        return TuneDebugLog.enableLog;
    }

    public static void enableLog() {
        enableLog = true;
    }

    public static void disableLog() {
        enableLog = false;
    }

    public static void setLogLevel(Level level) {
        logLevel = level;
    }

    @Deprecated
    public static void IAMConfigError(String message) {
        if (Tune.getInstance() != null && Tune.getInstance().isInDebugMode()) {
            throw new TuneIAMConfigurationException(message);
        } else {
            e(getTag(2), message);
        }
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
}
