package com.tune.utils;

import android.support.test.runner.AndroidJUnit4;

import com.tune.TuneUnitTest;

import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.assertEquals;

/**
 * Created by gowie on 1/26/16.
 */
@RunWith(AndroidJUnit4.class)
public class TuneStringUtilsTests extends TuneUnitTest {

    @Test
    public void testScrubNameForMongoRemovesAllUnwantedCharacters() {
        assertEquals("NoChange", TuneStringUtils.scrubStringForMongo("NoChange"));
        assertEquals("__NoDollars__", TuneStringUtils.scrubStringForMongo("$$NoDollars$$"));
        assertEquals("__NoPeriods__", TuneStringUtils.scrubStringForMongo("..NoPeriods.."));
        assertEquals("NoTrailingWhitespace", TuneStringUtils.scrubStringForMongo("  NoTrailingWhitespace  "));
    }
}
