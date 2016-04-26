package com.tune.ma.eventbus.event.campaign;

import com.tune.ma.campaign.model.TuneCampaign;

/**
 * Created by charlesgilliam on 2/10/16.
 */
public class TuneCampaignViewed {
    TuneCampaign campaign;

    public TuneCampaignViewed(TuneCampaign campaign) {
        this.campaign = campaign;
    }

    public TuneCampaign getCampaign() {
        return campaign;
    }
}
