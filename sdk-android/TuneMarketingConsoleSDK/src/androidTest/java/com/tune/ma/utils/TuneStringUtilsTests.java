package com.tune.ma.utils;

import com.tune.TuneUnitTest;

/**
 * Created by gowie on 1/26/16.
 */
public class TuneStringUtilsTests extends TuneUnitTest {

    public void testScrubNameForMongoRemovesAllUnwantedCharacters() {
        assertEquals("NoChange", TuneStringUtils.scrubStringForMongo("NoChange"));
        assertEquals("__NoDollars__", TuneStringUtils.scrubStringForMongo("$$NoDollars$$"));
        assertEquals("__NoPeriods__", TuneStringUtils.scrubStringForMongo("..NoPeriods.."));
        assertEquals("NoTrailingWhitespace", TuneStringUtils.scrubStringForMongo("  NoTrailingWhitespace  "));
    }
}
