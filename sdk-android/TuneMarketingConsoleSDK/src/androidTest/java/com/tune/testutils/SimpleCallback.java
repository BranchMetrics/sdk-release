package com.tune.testutils;

import com.tune.ma.model.TuneCallback;

/**
 * Created by gowie on 2/2/16.
 */
public class SimpleCallback implements TuneCallback {

    private boolean callbackExecuted;
    private long executeTime;

    public SimpleCallback() {
        callbackExecuted = false;
    }

    @Override
    public void execute() {
        callbackExecuted = true;
        executeTime = System.currentTimeMillis();
    }

    public boolean getCallbackExecuted() {
        return callbackExecuted;
    }

    public long getExecutedTime() {
        return executeTime;
    }
}
