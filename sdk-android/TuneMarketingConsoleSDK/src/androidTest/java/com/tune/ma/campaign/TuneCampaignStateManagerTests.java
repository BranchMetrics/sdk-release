package com.tune.ma.campaign;

import android.content.Context;

import com.tune.TuneUnitTest;
import com.tune.ma.TuneManager;
import com.tune.ma.campaign.model.TuneCampaign;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.TuneSessionVariableToSet;
import com.tune.ma.eventbus.event.campaign.TuneCampaignViewed;
import com.tune.ma.session.TuneSessionManager;

/**
 * Created by charlesgilliam on 2/10/16.
 */
public class TuneCampaignStateManagerTests extends TuneUnitTest {
    private int campaignVariableUpdateCount;
    private TuneCampaignStateManager campaignStateManager;

    @Override
    protected void setUp() throws Exception {
        super.setUp();
        // These tests expect nothing else to be running in the background
        TuneManager.destroy();

        campaignStateManager = new TuneCampaignStateManager(getContext());
        TuneEventBus.register(campaignStateManager);

        campaignVariableUpdateCount = 0;
    }

    @Override
    protected void tearDown() throws Exception {
        campaignStateManager.sharedPrefs.clearSharedPreferences();

        super.tearDown();
    }

    public void onEvent(TuneSessionVariableToSet event) {
        campaignVariableUpdateCount += 1;
    }

    public void testStateManagerOnlyAddsSessionVariablesOnceForEachView() {
        TuneCampaign campaign = new TuneCampaign("CAMP_ID", "VAR_ID", 100000);
        assert(campaignVariableUpdateCount == 0);
        TuneEventBus.post(new TuneCampaignViewed(campaign));

        // Two more times to test that it only posts the session variables skyhook once per session.
        TuneEventBus.post(new TuneCampaignViewed(campaign));
        TuneEventBus.post(new TuneCampaignViewed(campaign));

        assert(campaignVariableUpdateCount == 2);
    }

    public void testStateManagerAddsSessionVariablesBackOnNewSession() {
        assert(campaignVariableUpdateCount == 0);
        TuneEventBus.post(new TuneAppForegrounded("session_id", 1999L));
        assert(campaignVariableUpdateCount == 0);

        TuneCampaign campaign = new TuneCampaign("CAMP_ID", "VAR_ID", 100000);
        TuneEventBus.post(new TuneCampaignViewed(campaign));

        assert(campaignVariableUpdateCount == 2);
        TuneEventBus.post(new TuneAppForegrounded("session_id", 1999L));
        assert(campaignVariableUpdateCount == 4);
    }

    public void testStateManagerStopsAddingCampaignVariablesIfReportingTimeExpires() {
        assert(campaignVariableUpdateCount == 0);
        TuneEventBus.post(new TuneAppForegrounded("session_id", 1999L));
        assert(campaignVariableUpdateCount == 0);

        TuneCampaign campaign = new TuneCampaign("CAMP_ID", "VAR_ID", 1);
        TuneEventBus.post(new TuneCampaignViewed(campaign));

        assert(campaignVariableUpdateCount == 2);
        sleep(1000);
        TuneEventBus.post(new TuneAppForegrounded("session_id", 1999L));
        assert(campaignVariableUpdateCount == 2);
    }
}
