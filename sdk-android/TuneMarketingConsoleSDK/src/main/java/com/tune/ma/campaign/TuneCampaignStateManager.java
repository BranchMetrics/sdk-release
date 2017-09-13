package com.tune.ma.campaign;

import android.content.Context;

import com.tune.ma.campaign.model.TuneCampaign;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.TuneSessionVariableToSet;
import com.tune.ma.eventbus.event.campaign.TuneCampaignViewed;
import com.tune.ma.utils.TuneSharedPrefsDelegate;

import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Created by charlesgilliam on 2/9/16.
 */
public class TuneCampaignStateManager {
    private final String TUNE_CAMPAIGN_PREFS = "com.tune.ma.campaign";
    
    protected ConcurrentHashMap<String, TuneCampaign> viewedCampaigns;
    protected Set<String> campaignIdsRecordedThisSession;
    protected Set<String> variationIdsRecordedThisSession;
    protected TuneSharedPrefsDelegate sharedPrefs;

    public TuneCampaignStateManager(Context context) {
        viewedCampaigns = new ConcurrentHashMap<String, TuneCampaign>();
        campaignIdsRecordedThisSession = new HashSet<String>();
        variationIdsRecordedThisSession = new HashSet<String>();
        sharedPrefs = new TuneSharedPrefsDelegate(context, TUNE_CAMPAIGN_PREFS);

        retrieveViewedCampaigns();
        campaignHouseKeeping();
    }

    public synchronized void onEvent(TuneAppForegrounded event) {
        campaignHouseKeeping();
        for (Map.Entry<String, TuneCampaign> e: viewedCampaigns.entrySet()) {
            String campaignId = e.getValue().getCampaignId();
            addViewedCampaignIdToSession(campaignId);

            String variationId = e.getKey();
            addViewedVariationIdToSession(variationId);
        }
    }

    public synchronized void onEvent(TuneCampaignViewed event) {
        TuneCampaign campaign = event.getCampaign();

        if (campaign != null && campaign.hasCampaignId() && campaign.hasVariationId()) {
            campaign.markCampaignViewed();
            if (!viewedCampaigns.containsKey(campaign.getVariationId())) {
                addViewedCampaignIdToSession(campaign.getCampaignId());
                addViewedVariationIdToSession(campaign.getVariationId());
            }

            // This will overwrite the existing campaign information under the same variation id (it could have been updated)
            viewedCampaigns.put(campaign.getVariationId(), campaign);
        }
        storeViewedCampaigns();
    }

    private synchronized void campaignHouseKeeping() {
        boolean needToStoreChanges = false;

        for (Map.Entry<String, TuneCampaign> e: viewedCampaigns.entrySet()) {
            if (!e.getValue().needToReportCampaignAnalytics()) {
                viewedCampaigns.remove(e.getKey());
                needToStoreChanges = true;
            }
        }

        if (needToStoreChanges) {
            storeViewedCampaigns();
        }
    }

    private void addViewedCampaignIdToSession(String campaignId) {
        if (!campaignIdsRecordedThisSession.contains(campaignId)) {
            TuneEventBus.post(new TuneSessionVariableToSet(TuneCampaign.TUNE_CAMPAIGN_IDENTIFIER, campaignId, TuneSessionVariableToSet.SaveTo.PROFILE));
            campaignIdsRecordedThisSession.add(campaignId);
        }
    }

    private void addViewedVariationIdToSession(String variationId) {
        if (!variationIdsRecordedThisSession.contains(variationId)) {
            TuneEventBus.post(new TuneSessionVariableToSet(TuneCampaign.TUNE_CAMPAIGN_VARIATION_IDENTIFIER, variationId, TuneSessionVariableToSet.SaveTo.PROFILE));
            variationIdsRecordedThisSession.add(variationId);
        }
    }

    private void storeViewedCampaigns() {
        for (Map.Entry<String, TuneCampaign> entry: viewedCampaigns.entrySet()) {
            try {
                TuneCampaign campaign = entry.getValue();
                sharedPrefs.saveToSharedPreferences(entry.getKey(), campaign.toStorage());
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    private synchronized void retrieveViewedCampaigns() {
        if (viewedCampaigns == null) {
            viewedCampaigns = new ConcurrentHashMap<String, TuneCampaign>();
        }
        for (Map.Entry<String, ?> entry: sharedPrefs.getAll().entrySet()) {
            try {
                String storedCampaign = (String)entry.getValue();
                viewedCampaigns.put(entry.getKey(), TuneCampaign.fromStorage(storedCampaign));
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
