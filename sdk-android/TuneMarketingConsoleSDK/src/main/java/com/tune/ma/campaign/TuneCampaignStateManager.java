package com.tune.ma.campaign;

import android.content.Context;

import com.tune.ma.campaign.model.TuneCampaign;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.TuneSessionVariableToSet;
import com.tune.ma.eventbus.event.campaign.TuneCampaignViewed;
import com.tune.ma.utils.TuneSharedPrefsDelegate;

import org.greenrobot.eventbus.Subscribe;

import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Created by charlesgilliam on 2/9/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneCampaignStateManager {
    private static final String TUNE_CAMPAIGN_PREFS = "com.tune.ma.campaign";
    
    protected ConcurrentHashMap<String, TuneCampaign> viewedCampaigns;
    protected Set<String> campaignIdsRecordedThisSession;
    protected Set<String> variationIdsRecordedThisSession;
    protected TuneSharedPrefsDelegate sharedPrefs;

    public TuneCampaignStateManager(Context context) {
        viewedCampaigns = new ConcurrentHashMap<>();
        campaignIdsRecordedThisSession = new HashSet<>();
        variationIdsRecordedThisSession = new HashSet<>();
        sharedPrefs = new TuneSharedPrefsDelegate(context, TUNE_CAMPAIGN_PREFS);

        retrieveViewedCampaigns();
        campaignHouseKeeping();
    }

    @Subscribe(priority = TuneEventBus.PRIORITY_FIRST)
    public synchronized void onEvent(TuneAppForegrounded event) {
        campaignHouseKeeping();
        for (Map.Entry<String, TuneCampaign> e: viewedCampaigns.entrySet()) {
            String campaignId = e.getValue().getCampaignId();
            addViewedCampaignIdToSession(campaignId);

            String variationId = e.getKey();
            addViewedVariationIdToSession(variationId);
        }
    }

    @Subscribe(priority = TuneEventBus.PRIORITY_FIRST)
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
            viewedCampaigns = new ConcurrentHashMap<>();
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
