package com.tune.testutils;

import com.tune.ma.model.TuneCallback;

/**
 * Created by gowie on 2/2/16.
 */
public class SimpleCallback implements TuneCallback {

    private boolean callbackExecuted;

    public SimpleCallback() {
        callbackExecuted = false;
    }

    @Override
    public void execute() {
        callbackExecuted = true;
    }

    public boolean getCallbackExecuted() {
        return callbackExecuted;
    }
}
