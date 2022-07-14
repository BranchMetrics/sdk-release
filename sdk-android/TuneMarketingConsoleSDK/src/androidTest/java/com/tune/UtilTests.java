package com.tune;

import androidx.test.ext.junit.runners.AndroidJUnit4;

import com.tune.utils.TuneUtils;

import java.io.ByteArrayInputStream;
import java.io.InputStream;

import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.assertEquals;

@RunWith(AndroidJUnit4.class)
public class UtilTests {

    private static final String TEST_TYPICAL = "The quick brown fox jumps over the lazy dog";

    private static final String TEST_CRLF_A = "\nThe quick brown fox jumps over the lazy dog";
    private static final String TEST_CRLF_B = "The quick brown fox\njumps over the lazy dog";
    private static final String TEST_CRLF_C = "The quick brown fox jumps over the lazy dog\n";

    private static final String TEST_EMPTY = "";

    @Test
    public void testReadStream() throws Exception {
        // Test the typical case
        assertEquals(TEST_TYPICAL, TuneUtils.readStream(createInputStream(TEST_TYPICAL)));

        // Test CRLF in the front
        assertEquals(TEST_CRLF_A, TuneUtils.readStream(createInputStream(TEST_CRLF_A)));

        // Test CRLF in the middle
        assertEquals(TEST_CRLF_B, TuneUtils.readStream(createInputStream(TEST_CRLF_B)));

        // The Trailing CRLF is stripped, which is ok.
        assertEquals(TEST_TYPICAL, TuneUtils.readStream(createInputStream(TEST_CRLF_C)));

        // Empty Strings should remain empty
        assertEquals(TEST_EMPTY, TuneUtils.readStream(createInputStream(TEST_EMPTY)));
    }

    private InputStream createInputStream(String str) {
        return new ByteArrayInputStream(str.getBytes());
    }
}
