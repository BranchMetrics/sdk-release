package com.tune.ma.utils;

import android.support.test.runner.AndroidJUnit4;

import com.tune.TuneUnitTest;

import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.Calendar;
import java.util.Date;
import java.util.TimeZone;

import static org.hamcrest.CoreMatchers.anyOf;
import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertThat;
import static org.junit.Assert.assertTrue;

/**
 * Created by gowie on 1/27/16.
 */
@RunWith(AndroidJUnit4.class)
public class TuneDateUtilsTests extends TuneUnitTest {

    @Test
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
        assertThat(parsedCal.getTimeZone().getDisplayName(), anyOf(is("UTC"), is("GMT+00:00")));
    }

    @Test
    public void testNowFallsBetweenDates() {
        Date start = TuneDateUtils.parseIso8601("2015-01-25T19:12:45Z");
        Date end = TuneDateUtils.parseIso8601("2047-01-25T19:12:45Z");

        assertTrue(TuneDateUtils.doesNowFallBetweenDates(start, end));
    }

    @Test
    public void testNowDoesNotFallBetweenDates() {
        Date start = TuneDateUtils.parseIso8601("2046-01-25T19:12:45Z");
        Date end = TuneDateUtils.parseIso8601("2047-01-25T19:12:45Z");

        assertFalse(TuneDateUtils.doesNowFallBetweenDates(start, end));
    }

    @Test
    public void testNowDoesFallBeforeDate() {
        // Create Date 2 days later
        Calendar cdate = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        cdate.add(Calendar.DATE, 2);
        Date twoDaysLater = cdate.getTime();

        assertTrue(TuneDateUtils.doesNowFallBeforeDate(twoDaysLater));
    }

    @Test
    public void testNowDoesFallAfterDate() {
        // Create Date 2 days earlier
        Calendar cdate = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        cdate.add(Calendar.DATE, -2);
        Date twoDaysEarlier = cdate.getTime();

        assertTrue(TuneDateUtils.doesNowFallAfterDate(twoDaysEarlier));
    }

    @Test
    public void testNowDoesFallBeforeToday() {
        // Add small time buffer since "now" is initialized later than the param
        // We'll use 5s since emulators can be really slow
        Calendar calendar = Calendar.getInstance();
        calendar.add(Calendar.SECOND, 5);
        assertTrue(TuneDateUtils.doesNowFallBeforeDate(calendar.getTime()));
    }

    @Test
    public void testNowDoesFallAfterToday() {
        assertTrue(TuneDateUtils.doesNowFallAfterDate(new Date()));
    }

    @Test
    public void testDaysSinceDate() {
        // Create Date 2 days earlier
        Calendar cdate = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        cdate.add(Calendar.DATE, -2);
        Date twoDaysEarlier = cdate.getTime();

        // Create Date 28 days later
        cdate.add(Calendar.DATE, 30);
        Date twentyEightDaysLater = cdate.getTime();

        assertEquals(2, TuneDateUtils.daysSinceDate(twoDaysEarlier));
        assertEquals(-28, TuneDateUtils.daysSinceDate(twentyEightDaysLater));
    }

    @Test
    public void testSecondsBetweenDates() {
        // Create Date 5 seconds later
        Calendar cdate = Calendar.getInstance(TimeZone.getTimeZone("UTC"));

        Date now = cdate.getTime();

        cdate.add(Calendar.SECOND, 5);
        Date fiveSecondsLater = cdate.getTime();

        assertEquals(5, TuneDateUtils.secondsBetweenDates(now, fiveSecondsLater));
        assertEquals(5, TuneDateUtils.secondsBetweenDates(fiveSecondsLater, now));
    }
}
