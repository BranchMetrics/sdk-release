package com.tune.ma;

/**
 * Created by charlesgilliam on 2/16/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneIAMNotEnabledException extends RuntimeException {
    public TuneIAMNotEnabledException(String message) {
        super(message);
    }
}
