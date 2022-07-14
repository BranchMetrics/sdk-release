package com.tune;

import androidx.test.ext.junit.runners.AndroidJUnit4;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.assertTrue;

/**
 * Created by johng on 6/3/16.
 */
@RunWith(AndroidJUnit4.class)
public class PreloadedAppTests extends TuneUnitTest {
    @Before
    public void setUp() throws Exception {
        super.setUp();

        tune.setOnline(false);
    }

    @After
    public void tearDown() throws Exception {
        tune.setOnline(true);

        super.tearDown();
    }

    @Test
    public void testPreloadedAppAttribution() {
        String expectedPublisherId              = "test_publisher_id";
        String expectedOfferId                  = "test_offer_id";
        String expectedAgencyId                 = "test_agency_id";
        String expectedPublisherReferenceId     = "test_publisher_reference_id";
        String expectedPublisherSub1            = "test_publisher_sub1";
        String expectedPublisherSub2            = "test_publisher_sub2";
        String expectedPublisherSub3            = "test_publisher_sub3";
        String expectedPublisherSub4            = "test_publisher_sub4";
        String expectedPublisherSub5            = "test_publisher_sub5";
        String expectedPublisherSubAd           = "test_publisher_sub_ad";
        String expectedPublisherSubAdgroup      = "test_publisher_sub_adgroup";
        String expectedPublisherSubCampaign     = "test_publisher_sub_campaign";
        String expectedPublisherSubKeyword      = "test_publisher_sub_keyword";
        String expectedPublisherSubPublisher    = "test_publisher_sub_publisher";
        String expectedPublisherSubSite         = "test_publisher_sub_site";
        String expectedAdvertiserSubAd          = "test_advertiser_sub_ad";
        String expectedAdvertiserSubAdgroup     = "test_advertiser_sub_adgroup";
        String expectedAdvertiserSubCampaign    = "test_advertiser_sub_campaign";
        String expectedAdvertiserSubKeyword     = "test_advertiser_sub_keyword";
        String expectedAdvertiserSubPublisher   = "test_advertiser_sub_publisher";
        String expectedAdvertiserSubSite        = "test_advertiser_sub_site";

        TunePreloadData preloadData = new TunePreloadData(expectedPublisherId);
        preloadData.withOfferId(expectedOfferId);
        preloadData.withAgencyId(expectedAgencyId);
        preloadData.withPublisherReferenceId(expectedPublisherReferenceId);
        preloadData.withPublisherSub1(expectedPublisherSub1);
        preloadData.withPublisherSub2(expectedPublisherSub2);
        preloadData.withPublisherSub3(expectedPublisherSub3);
        preloadData.withPublisherSub4(expectedPublisherSub4);
        preloadData.withPublisherSub5(expectedPublisherSub5);
        preloadData.withPublisherSubAd(expectedPublisherSubAd);
        preloadData.withPublisherSubAdgroup(expectedPublisherSubAdgroup);
        preloadData.withPublisherSubCampaign(expectedPublisherSubCampaign);
        preloadData.withPublisherSubKeyword(expectedPublisherSubKeyword);
        preloadData.withPublisherSubPublisher(expectedPublisherSubPublisher);
        preloadData.withPublisherSubSite(expectedPublisherSubSite);
        preloadData.withAdvertiserSubAd(expectedAdvertiserSubAd);
        preloadData.withAdvertiserSubAdgroup(expectedAdvertiserSubAdgroup);
        preloadData.withAdvertiserSubCampaign(expectedAdvertiserSubCampaign);
        preloadData.withAdvertiserSubKeyword(expectedAdvertiserSubKeyword);
        preloadData.withAdvertiserSubPublisher(expectedAdvertiserSubPublisher);
        preloadData.withAdvertiserSubSite(expectedAdvertiserSubSite);

        tune.setPreloadedAppData(preloadData);
        tune.measureEvent("registration");
        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue("attr_set", "1");
        assertKeyValue(TuneUrlKeys.PUBLISHER_ID, expectedPublisherId);
        assertKeyValue(TuneUrlKeys.OFFER_ID, expectedOfferId);
        assertKeyValue(TuneUrlKeys.AGENCY_ID, expectedAgencyId);
        assertKeyValue(TuneUrlKeys.PUBLISHER_REF_ID, expectedPublisherReferenceId);
        assertKeyValue(TuneUrlKeys.PUBLISHER_SUB1, expectedPublisherSub1);
        assertKeyValue(TuneUrlKeys.PUBLISHER_SUB2, expectedPublisherSub2);
        assertKeyValue(TuneUrlKeys.PUBLISHER_SUB3, expectedPublisherSub3);
        assertKeyValue(TuneUrlKeys.PUBLISHER_SUB4, expectedPublisherSub4);
        assertKeyValue(TuneUrlKeys.PUBLISHER_SUB5, expectedPublisherSub5);
        assertKeyValue(TuneUrlKeys.PUBLISHER_SUB_AD, expectedPublisherSubAd);
        assertKeyValue(TuneUrlKeys.PUBLISHER_SUB_ADGROUP, expectedPublisherSubAdgroup);
        assertKeyValue(TuneUrlKeys.PUBLISHER_SUB_CAMPAIGN, expectedPublisherSubCampaign);
        assertKeyValue(TuneUrlKeys.PUBLISHER_SUB_KEYWORD, expectedPublisherSubKeyword);
        assertKeyValue(TuneUrlKeys.PUBLISHER_SUB_PUBLISHER, expectedPublisherSubPublisher);
        assertKeyValue(TuneUrlKeys.PUBLISHER_SUB_SITE, expectedPublisherSubSite);
        assertKeyValue(TuneUrlKeys.ADVERTISER_SUB_AD, expectedAdvertiserSubAd);
        assertKeyValue(TuneUrlKeys.ADVERTISER_SUB_ADGROUP, expectedAdvertiserSubAdgroup);
        assertKeyValue(TuneUrlKeys.ADVERTISER_SUB_CAMPAIGN, expectedAdvertiserSubCampaign);
        assertKeyValue(TuneUrlKeys.ADVERTISER_SUB_KEYWORD, expectedAdvertiserSubKeyword);
        assertKeyValue(TuneUrlKeys.ADVERTISER_SUB_PUBLISHER, expectedAdvertiserSubPublisher);
        assertKeyValue(TuneUrlKeys.ADVERTISER_SUB_SITE, expectedAdvertiserSubSite);
    }
}
