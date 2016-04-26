package com.tune.ma.experiments.model;

/**
 * Created by gowie on 1/26/16.
 */

import com.tune.ma.utils.TuneJsonUtils;

import org.json.JSONObject;

/**
 * An object containing useful information about an experiment
 **/
public class TuneExperimentDetails {

    public static final String  DETAIL_EXPERIMENT_NAME_KEY = "name";
    public static final String  DETAIL_EXPERIMENT_ID_KEY = "id";
    public static final String  DETAIL_EXPERIMENT_TYPE_KEY = "type";
    public static final String  DETAIL_CURRENT_VARIATION_KEY = "current_variation";
    public static final String  DETAIL_CURRENT_VARIATION_ID_KEY = "id";
    public static final String  DETAIL_CURRENT_VARIATION_NAME_KEY = "name";
    public static final String  DETAIL_CURRENT_VARIATION_LETTER_KEY = "letter";

    public static final String  DETAIL_TYPE_POWER_HOOK = "power_hook";
    public static final String  DETAIL_TYPE_IN_APP = "in_app";

    private String experimentId;
    private String experimentName;
    private String experimentType;
    private String currentVariantId;
    private String currentVariantName;
    private String currentVariantLetter;

    public TuneExperimentDetails(String experimentId, String experimentName, String experimentType, String currentVariantId, String currentVariantName, String currentVariantLetter) {
        this.experimentId = experimentId;
        this.experimentName = experimentName;
        this.experimentType = experimentType;
        this.currentVariantId = currentVariantId;
        this.currentVariantName = currentVariantName;
        this.currentVariantLetter = currentVariantLetter;
    }

    public TuneExperimentDetails(JSONObject experimentDetailsJson) {
        this.experimentId = TuneJsonUtils.getString(experimentDetailsJson, TuneExperimentDetails.DETAIL_EXPERIMENT_ID_KEY);
        this.experimentName = TuneJsonUtils.getString(experimentDetailsJson, TuneExperimentDetails.DETAIL_EXPERIMENT_NAME_KEY);
        this.experimentType = TuneJsonUtils.getString(experimentDetailsJson, TuneExperimentDetails.DETAIL_EXPERIMENT_TYPE_KEY);
        JSONObject currentVariationJson = TuneJsonUtils.getJSONObject(experimentDetailsJson, TuneExperimentDetails.DETAIL_CURRENT_VARIATION_KEY);
        this.currentVariantId = TuneJsonUtils.getString(currentVariationJson, TuneExperimentDetails.DETAIL_CURRENT_VARIATION_ID_KEY);
        this.currentVariantName = TuneJsonUtils.getString(currentVariationJson, TuneExperimentDetails.DETAIL_CURRENT_VARIATION_NAME_KEY);
        this.currentVariantLetter = TuneJsonUtils.getString(currentVariationJson, TuneExperimentDetails.DETAIL_CURRENT_VARIATION_LETTER_KEY);
    }

    /**
     * The id of the experiment.
     *
     * The experiment id is a unique identifier for an experiment.
     */
    public String getExperimentId() {
        return experimentId;
    }

    /**
     * The name of the experiment.
     *
     * The experiment name is the same that you would see in Tune Marketing Automation Tools.
     */
    public String getExperimentName() {
        return experimentName;
    }

    /**
     * The type of the experiment.
     */
    public String getExperimentType() {
        return experimentType;
    }

    /**
     * The current variant id for the experiment.
     *
     * The variant id is a unique identifier for the variation of an Tune Marketing Automation Experiment.
     */
    public String getCurrentVariantId() {
        return currentVariantId;
    }

    /**
     * The current variant name for the experiment.
     *
     * The variant name is the same that you would see in Tune Marketing Automation Tools. Unless the names were edited in Artisan tools they are "Control", "B", "C", etc.
     */
    public String getCurrentVariantName() {
        return currentVariantName;
    }

    /**
     * The current variant letter for the experiment.
     *
     * This will the be same as 'currentVariantName' unless you gave it a new name. Otherwise it will give the associated variation letter to the name.
     */
    public String getCurrentVariantLetter() {
        return currentVariantLetter;
    }

}
