package com.tune.ma.experiments.model;

import org.json.JSONObject;

/**
 * Created by gowie on 1/26/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneInAppMessageExperimentDetails extends TuneExperimentDetails {

    public TuneInAppMessageExperimentDetails(String experimentId, String experimentName, String experimentType, String currentVariantId, String currentVariantName, String currentVariantLetter) {
        super(experimentId, experimentName, experimentType, currentVariantId, currentVariantName, currentVariantLetter);
    }

    public TuneInAppMessageExperimentDetails(JSONObject experimentDetails) {
        super(experimentDetails);
    }
}
