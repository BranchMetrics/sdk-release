package com.tune.ma.eventbus.event.userprofile;

import java.util.List;
import java.util.Set;

/**
 * Created by charlesgilliam on 1/21/16.
 */
public class TuneCustomProfileVariablesCleared {
    List<String> vars;

    public TuneCustomProfileVariablesCleared(List<String> vars) {
        this.vars = vars;
    }

    public List<String> getVars() {
        return vars;
    }
}
