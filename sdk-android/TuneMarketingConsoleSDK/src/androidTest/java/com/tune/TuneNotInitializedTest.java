package com.tune;

import android.test.AndroidTestCase;

/**
 * Created by audrey on 3/8/18.
 */
public class TuneNotInitializedTest extends AndroidTestCase {

    public void testTuneIsNullWhenTuneNotInitialized() {
        assertNull(Tune.getInstance());
    }

}
