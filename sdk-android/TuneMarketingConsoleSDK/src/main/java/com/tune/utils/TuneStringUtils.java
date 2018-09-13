package com.tune.utils;

import android.net.Uri;

import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Locale;
import java.util.Set;

/**
 * Created by gowie on 1/26/16.
 */
public class TuneStringUtils {

    /**
     * Creates a new trimmed string by replacing each Mongo-unsupported character with an underscore.
     * e.g. '.', '$'
     *
     * @param input string to be cleaned up
     * @return a new string object that is valid in Mongo
     */
    public static String scrubStringForMongo(String input) {
        String trimmed = input.trim();
        String noPeriods = trimmed.replaceAll("\\.", "_");
        String noDollars = noPeriods.replaceAll("\\$", "_");
        return noDollars;
    }

    public static String format(String format, Object... args) {
        return String.format(Locale.US, format, args);
    }

    /**
     * Check to see if a String is Null or Empty
     * @param str String to test
     * @return true if the string is null or empty.
     */
    public static boolean isNullOrEmpty(String str) {
        return (str == null || str.length() == 0);
    }
}
