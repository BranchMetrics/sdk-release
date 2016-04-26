package com.tune.ma.utils;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.TimeZone;

/**
 * Created by gowie on 1/26/16.
 */
public class TuneDateUtils {

    public static SimpleDateFormat getTuneDateFormatter() {
        SimpleDateFormat tuneDateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ");
        tuneDateFormatter.setTimeZone(TimeZone.getTimeZone("UTC"));
        return tuneDateFormatter;
    }

    public static Date getNowUTC() {
        Calendar cal = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        return cal.getTime();
    }

    public static boolean doesNowFallBetweenDates(Date startDate, Date endDate) {
        Date now = getNowUTC();
        return now.equals(startDate) || now.equals(endDate) || (now.after(startDate) && now.before(endDate));
    }

    /** Transform ISO 8601 string to Date. */
    public static Date parseIso8601(final String iso8601String) {
        if (iso8601String == null) {
            return null;
        }

        String utcString = iso8601String.replace("Z", "+00:00");

        try {
            utcString = utcString.substring(0, 22) + utcString.substring(23);  // to get rid of the ":"
        } catch (IndexOutOfBoundsException e) {
            TuneDebugLog.e("TuneDateUtils", "Error building Date String: " + iso8601String);
            return null;
        }

        try {
            return getTuneDateFormatter().parse(utcString);
        } catch (ParseException e) {
            TuneDebugLog.e("TuneDateUtils", "Error parsing Date: " + iso8601String);
            return null;
        }
    }
}
