package com.tune.testutils;

/**
 * Created by gowie on 2/1/16.
 */
public class TuneTestUtils {

    public static void assertEventually(int timeoutInMilliseconds, Runnable assertion) {
        long begin = System.currentTimeMillis();
        long now = begin;
        Throwable lastException = null;

        while((now - begin) < timeoutInMilliseconds) {
            try{
                assertion.run();
                return;
            } catch(RuntimeException e) {
                lastException = e;
            } catch(AssertionError e) {
                lastException = e;
            }

            now = System.currentTimeMillis();
        }

        throw new RuntimeException(lastException);
    }
}
