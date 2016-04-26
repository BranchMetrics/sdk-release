package com.tune.ma.utils;

import com.tune.TuneUnitTest;

import java.util.Calendar;
import java.util.Date;
import java.util.TimeZone;

/**
 * Created by gowie on 1/27/16.
 */
public class TuneDateUtilsTests extends TuneUnitTest {

    public void testParseIso8610ToDate() {
        String dateToParse = "2016-01-25T19:12:45Z";

        Date parsedDate = TuneDateUtils.parseIso8601(dateToParse);
        Calendar parsedCal = Calendar.getInstance();
        parsedCal.setTimeZone(TimeZone.getTimeZone("UTC"));
        parsedCal.setTime(parsedDate);

        assertEquals(2016, parsedCal.get(Calendar.YEAR));
        assertEquals(Calendar.JANUARY, parsedCal.get(Calendar.MONTH));
        assertEquals(25, parsedCal.get(Calendar.DAY_OF_MONTH));
        assertEquals(19, parsedCal.get(Calendar.HOUR_OF_DAY));
        assertEquals(12, parsedCal.get(Calendar.MINUTE));
        assertEquals(45, parsedCal.get(Calendar.SECOND));
        assertEquals("UTC", parsedCal.getTimeZone().getDisplayName());
    }

    public void testNowFallsBetweenDates() {
        Date start = TuneDateUtils.parseIso8601("2015-01-25T19:12:45Z");
        Date end = TuneDateUtils.parseIso8601("2047-01-25T19:12:45Z");

        assertTrue(TuneDateUtils.doesNowFallBetweenDates(start, end));
    }

    public void testNowDoesNotFallBetweenDates() {
        Date start = TuneDateUtils.parseIso8601("2046-01-25T19:12:45Z");
        Date end = TuneDateUtils.parseIso8601("2047-01-25T19:12:45Z");

        assertFalse(TuneDateUtils.doesNowFallBetweenDates(start, end));
    }
}
