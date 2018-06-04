package com.tune.ma;

import com.tune.TuneConfigurationException;

/**
 * Created by charlesgilliam on 2/11/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneIAMConfigurationException extends TuneConfigurationException {
    public TuneIAMConfigurationException(String message) {
        super(message);
    }
}
