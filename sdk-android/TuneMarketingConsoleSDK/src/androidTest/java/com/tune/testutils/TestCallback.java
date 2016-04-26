package com.tune.testutils;

import com.tune.ma.model.TuneCallback;

/**
 * Created by gowie on 2/1/16.
 */
public class TestCallback implements TuneCallback {

    private int callbackCount;

    public TestCallback() {
        callbackCount = 0;
    }

    @Override
    public void execute() {
        callbackCount += 1;
    }

    public int getCallbackCount() {
        return callbackCount;
    }
}
