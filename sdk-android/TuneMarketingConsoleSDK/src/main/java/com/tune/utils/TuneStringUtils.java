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

    public static String reduceUrlToPath(String originalUrl) {
        // Only keep up to the path of the url
        Uri uri = Uri.parse(originalUrl);
        Uri.Builder builder = new Uri.Builder();
        builder.scheme(uri.getScheme())
                .authority(uri.getEncodedAuthority())
                .path(uri.getPath());
        return builder.build().toString();
    }

    // Got this method from Android source: http://grepcode.com/file/repository.grepcode.com/java/ext/com.google.android/android/5.1.1_r1/android/net/Uri.java?av=f
    // Since this method was introduced in API 11 and we support 9
    public static Set<String> getQueryParameterNames(Uri uri) {
        String query = uri.getEncodedQuery();
        if (query == null) {
            return Collections.emptySet();
        }

        Set<String> names = new LinkedHashSet<>();
        int start = 0;
        do {
            int next = query.indexOf('&', start);
            int end = (next == -1) ? query.length() : next;

            int separator = query.indexOf('=', start);
            if (separator > end || separator == -1) {
                separator = end;
            }

            String name = query.substring(start, separator);
            names.add(Uri.decode(name));

            // Move start to end of name.
            start = end + 1;
        } while (start < query.length());

        return Collections.unmodifiableSet(names);
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
