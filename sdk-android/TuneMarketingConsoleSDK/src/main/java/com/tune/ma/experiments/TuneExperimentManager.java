package com.tune.ma.experiments;

import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TunePlaylistManagerCurrentPlaylistChanged;
import com.tune.ma.eventbus.event.TuneSessionVariableToSet;
import com.tune.ma.experiments.model.TuneExperimentDetails;
import com.tune.ma.experiments.model.TuneInAppMessageExperimentDetails;
import com.tune.ma.experiments.model.TunePowerHookExperimentDetails;
import com.tune.ma.playlist.model.TunePlaylist;
import com.tune.ma.powerhooks.model.TunePowerHookValue;
import com.tune.ma.utils.TuneJsonUtils;

import org.json.JSONObject;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

/**
 * Created by gowie on 1/26/16.
 */
public class TuneExperimentManager {

    public static final String TUNE_ACTIVE_VARIATION_ID = "TUNE_ACTIVE_VARIATION_ID";

    private Map<String, TunePowerHookExperimentDetails> phookExperimentDetails;
    private Map<String, TuneInAppMessageExperimentDetails> inAppExperimentDetails;
    private Set<String> addedActiveVariations;

    public TuneExperimentManager() {
        phookExperimentDetails = new HashMap<String, TunePowerHookExperimentDetails>();
        inAppExperimentDetails = new HashMap<String, TuneInAppMessageExperimentDetails>();
        addedActiveVariations = new HashSet<String>();
    }

    public void onEvent(TunePlaylistManagerCurrentPlaylistChanged event) {
        TunePlaylist activePlaylist = event.getNewPlaylist();

        Map<String, TunePowerHookExperimentDetails> phookExperimentDetailsTemp = new HashMap<String, TunePowerHookExperimentDetails>();
        Map<String, TuneInAppMessageExperimentDetails> inAppMessageExperimentDetailsTemp = new HashMap<String, TuneInAppMessageExperimentDetails>();

        JSONObject experimentDetails = activePlaylist.getExperimentDetails();
        if (experimentDetails == null) {
            return;
        }

        Iterator<String> experimentDetailsIter = experimentDetails.keys();
        String experimentId;
        while (experimentDetailsIter.hasNext()) {
            experimentId = experimentDetailsIter.next();
            JSONObject experiment = TuneJsonUtils.getJSONObject(experimentDetails, experimentId);
            String type = TuneJsonUtils.getString(experiment, TuneExperimentDetails.DETAIL_EXPERIMENT_TYPE_KEY);

            if (type != null && type.equals(TuneExperimentDetails.DETAIL_TYPE_POWER_HOOK)) {
                JSONObject hooks = activePlaylist.getPowerHooks();
                Iterator<String> hooksIter = hooks.keys();
                String hookId;
                while (hooksIter.hasNext()) {
                    hookId = hooksIter.next();
                    // Create the PowerHookValue temporarily so we can get some information from it.
                    TunePowerHookValue hookValue = new TunePowerHookValue();
                    hookValue.mergeWithPlaylistJson(TuneJsonUtils.getJSONObject(hooks, hookId));
                    if (experimentId.equals(hookValue.getExperimentId())){
                        TunePowerHookExperimentDetails details = new TunePowerHookExperimentDetails(experiment, hookValue);
                        phookExperimentDetailsTemp.put(hookId, details);

                        if (addedActiveVariations.contains(details.getCurrentVariantId())) {
                            break;
                        } else {
                            addedActiveVariations.add(details.getCurrentVariantId());
                        }

                        TuneEventBus.post(new TuneSessionVariableToSet(TUNE_ACTIVE_VARIATION_ID, details.getCurrentVariantId(), TuneSessionVariableToSet.SaveTo.PROFILE));
                        break;
                    }
                }
            } else if (type != null && type.equals(TuneExperimentDetails.DETAIL_TYPE_IN_APP)) {
                TuneInAppMessageExperimentDetails details = new TuneInAppMessageExperimentDetails(experiment);
                inAppMessageExperimentDetailsTemp.put(TuneJsonUtils.getString(experiment, TuneExperimentDetails.DETAIL_EXPERIMENT_NAME_KEY), details);
            }
        }

        setPhookExperimentDetails(new HashMap<String, TunePowerHookExperimentDetails>(phookExperimentDetailsTemp));
        setInAppExperimentDetails(new HashMap<String, TuneInAppMessageExperimentDetails>(inAppMessageExperimentDetailsTemp));
    }

    private synchronized void setPhookExperimentDetails(Map<String, TunePowerHookExperimentDetails> phookExperimentDetails) {
        this.phookExperimentDetails = phookExperimentDetails;
    }

    private synchronized void setInAppExperimentDetails(Map<String, TuneInAppMessageExperimentDetails> inAppExperimentDetails) {
        this.inAppExperimentDetails = inAppExperimentDetails;
    }

    public synchronized Map<String, TunePowerHookExperimentDetails> getPhookExperimentDetails() {
        return new HashMap<String, TunePowerHookExperimentDetails>(phookExperimentDetails);
    }

    public synchronized Map<String, TuneInAppMessageExperimentDetails> getInAppExperimentDetails() {
        return new HashMap<String, TuneInAppMessageExperimentDetails>(inAppExperimentDetails);
    }

}
