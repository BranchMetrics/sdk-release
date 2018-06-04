package com.tune.ma.eventbus.event.campaign;

import com.tune.ma.campaign.model.TuneCampaign;

/**
 * Created by charlesgilliam on 2/10/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneCampaignViewed {
    TuneCampaign campaign;

    public TuneCampaignViewed(TuneCampaign campaign) {
        this.campaign = campaign;
    }

    public TuneCampaign getCampaign() {
        return campaign;
    }
}
