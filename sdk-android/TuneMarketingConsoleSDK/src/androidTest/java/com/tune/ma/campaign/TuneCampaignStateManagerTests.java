package com.tune.ma.campaign;

import android.support.test.runner.AndroidJUnit4;

import com.tune.TuneUnitTest;
import com.tune.ma.TuneManager;
import com.tune.ma.campaign.model.TuneCampaign;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.TuneSessionVariableToSet;
import com.tune.ma.eventbus.event.campaign.TuneCampaignViewed;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import static android.support.test.InstrumentationRegistry.getContext;

/**
 * Created by charlesgilliam on 2/10/16.
 */
@RunWith(AndroidJUnit4.class)
public class TuneCampaignStateManagerTests extends TuneUnitTest {
    private int campaignVariableUpdateCount;
    private TuneCampaignStateManager campaignStateManager;

    @Before
    public void setUp() throws Exception {
        super.setUp();
        // These tests expect nothing else to be running in the background
        TuneManager.destroy();

        campaignStateManager = new TuneCampaignStateManager(getContext());
        TuneEventBus.register(campaignStateManager);

        campaignVariableUpdateCount = 0;
    }

    @After
    public void tearDown() throws Exception {
        campaignStateManager.sharedPrefs.clearSharedPreferences();

        super.tearDown();
    }

    public void onEvent(TuneSessionVariableToSet event) {
        campaignVariableUpdateCount += 1;
    }

    @Test
    public void testStateManagerOnlyAddsSessionVariablesOnceForEachView() {
        TuneCampaign campaign = new TuneCampaign("CAMP_ID", "VAR_ID", 100000);
        assert(campaignVariableUpdateCount == 0);
        TuneEventBus.post(new TuneCampaignViewed(campaign));

        // Two more times to test that it only posts the session variables skyhook once per session.
        TuneEventBus.post(new TuneCampaignViewed(campaign));
        TuneEventBus.post(new TuneCampaignViewed(campaign));

        assert(campaignVariableUpdateCount == 2);
    }

    @Test
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

    @Test
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
