package com.tune.ma.experiments.model;

/**
 * Created by gowie on 1/26/16.
 */

import com.tune.ma.powerhooks.model.TunePowerHookValue;
import com.tune.ma.utils.TuneDateUtils;
import com.tune.ma.utils.TuneJsonUtils;

import org.json.JSONObject;

import java.util.Date;

/**
 * An object containing useful information about a Power Hook experiment.
 **/
public class TunePowerHookExperimentDetails extends TuneExperimentDetails {

    private Date experimentStartDate;
    private Date experimentEndDate;

    public TunePowerHookExperimentDetails(String experimentId, String experimentName, String experimentType, String currentVariantId, String currentVariantName, String currentVariantLetter, String hookId, Date experimentStartDate, Date experimentEndDate) {
        super(experimentId, experimentName, experimentType, currentVariantId, currentVariantName, currentVariantLetter);
        this.experimentStartDate = experimentStartDate;
        this.experimentEndDate = experimentEndDate;
    }

    public TunePowerHookExperimentDetails(JSONObject experimentDetails, TunePowerHookValue powerHookValue) {
        super(experimentDetails);
        this.experimentStartDate = powerHookValue.getStartDate();
        this.experimentEndDate = powerHookValue.getEndDate();
    }

    public boolean isRunning() {
        Date now = TuneDateUtils.getNowUTC();
        if (experimentEndDate == null || experimentStartDate == null) {
            return false;
        } else {
            return now.after(experimentStartDate) && now.before(experimentEndDate);
        }
    }

    public Date getExperimentStartDate() {
        return experimentStartDate;
    }

    public Date getExperimentEndDate() {
        return experimentEndDate;
    }
}
