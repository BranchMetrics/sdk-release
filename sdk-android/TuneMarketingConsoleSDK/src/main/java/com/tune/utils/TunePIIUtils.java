package com.tune.utils;

import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Created by kristine on 2/4/16.
 */
public class TunePIIUtils {

    public static boolean check(String value, List<Pattern> filtersAsPatterns) {
        if (value == null) {
            return false;
        }

        for (Pattern pattern : filtersAsPatterns) {
            Matcher matcher = pattern.matcher(value);
            if (matcher.find()) {
                return true;
            }
        }
        return false;
    }
}
