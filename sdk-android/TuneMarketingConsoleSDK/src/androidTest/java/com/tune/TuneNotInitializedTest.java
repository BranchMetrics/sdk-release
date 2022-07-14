package com.tune;

import androidx.test.ext.junit.runners.AndroidJUnit4;

import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.assertNull;

/**
 * Created by audrey on 3/8/18.
 */
@RunWith(AndroidJUnit4.class)
public class TuneNotInitializedTest {

    @Test
    public void testTuneIsNullWhenTuneNotInitialized() {
        assertNull(Tune.getInstance());
    }

}
