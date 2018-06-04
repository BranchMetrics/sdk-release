package com.tune.ma.eventbus.event.userprofile;

import java.util.List;
import java.util.Set;

/**
 * Created by charlesgilliam on 1/21/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneCustomProfileVariablesCleared {
    List<String> vars;

    public TuneCustomProfileVariablesCleared(List<String> vars) {
        this.vars = vars;
    }

    public List<String> getVars() {
        return vars;
    }
}
