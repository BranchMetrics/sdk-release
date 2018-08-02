package com.tune;

/**
 * Publisher and campaign data to be used for attribution for apps that are pre-loaded on device.
 */
public class TunePreloadData {
    private final String publisherId;
    private String offerId;
    private String agencyId;
    private String publisherReferenceId;
    private String publisherSub1;
    private String publisherSub2;
    private String publisherSub3;
    private String publisherSub4;
    private String publisherSub5;
    private String publisherSubAd;
    private String publisherSubAdgroup;
    private String publisherSubCampaign;
    private String publisherSubKeyword;
    private String publisherSubPublisher;
    private String publisherSubSite;
    private String advertiserSubAd;
    private String advertiserSubAdgroup;
    private String advertiserSubCampaign;
    private String advertiserSubKeyword;
    private String advertiserSubPublisher;
    private String advertiserSubSite;

    /**
     * Constructor.
     * @param publisherId Publisher Id.
     */
    public TunePreloadData(String publisherId) {
        this.publisherId = publisherId;
    }

    /**
     * Add an Offer Id to the Preload Data.
     * @param offerId Offer Id
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withOfferId(String offerId) {
        this.offerId = offerId;
        return this;
    }

    /**
     * Add an Agency Id to the Preload Data.
     * @param agencyId Agency Id
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withAgencyId(String agencyId) {
        this.agencyId = agencyId;
        return this;
    }

    /**
     * Add a Publisher Reference Id to the Preload Data.
     * @param publisherReferenceId Publisher Reference Id
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withPublisherReferenceId(String publisherReferenceId) {
        this.publisherReferenceId = publisherReferenceId;
        return this;
    }

    /**
     * Add a custom Publisher String (1) to the Preload Data.
     * @param publisherSub1 Publisher Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withPublisherSub1(String publisherSub1) {
        this.publisherSub1 = publisherSub1;
        return this;
    }

    /**
     * Add a custom Publisher String (2) to the Preload Data.
     * @param publisherSub2 Publisher Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withPublisherSub2(String publisherSub2) {
        this.publisherSub2 = publisherSub2;
        return this;
    }

    /**
     * Add a custom Publisher String (3) to the Preload Data.
     * @param publisherSub3 Publisher Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withPublisherSub3(String publisherSub3) {
        this.publisherSub3 = publisherSub3;
        return this;
    }

    /**
     * Add a custom Publisher String (4) to the Preload Data.
     * @param publisherSub4 Publisher Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withPublisherSub4(String publisherSub4) {
        this.publisherSub4 = publisherSub4;
        return this;
    }

    /**
     * Add a custom Publisher String (5) to the Preload Data.
     * @param publisherSub5 Publisher Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withPublisherSub5(String publisherSub5) {
        this.publisherSub5 = publisherSub5;
        return this;
    }

    /**
     * Add a custom Publisher Sub Ad String to the Preload Data.
     * @param publisherSubAd Publisher Sub Ad Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withPublisherSubAd(String publisherSubAd) {
        this.publisherSubAd = publisherSubAd;
        return this;
    }

    /**
     * Add a custom Publisher Sub Ad Group String to the Preload Data.
     * @param publisherSubAdgroup Publisher Sub Ad Group Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withPublisherSubAdgroup(String publisherSubAdgroup) {
        this.publisherSubAdgroup = publisherSubAdgroup;
        return this;
    }

    /**
     * Add a custom Publisher Sub Campaign String to the Preload Data.
     * @param publisherSubCampaign Publisher Sub Campaign Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withPublisherSubCampaign(String publisherSubCampaign) {
        this.publisherSubCampaign = publisherSubCampaign;
        return this;
    }

    /**
     * Add a custom Publisher Sub Keyword String to the Preload Data.
     * @param publisherSubKeyword Publisher Sub Keyword Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withPublisherSubKeyword(String publisherSubKeyword) {
        this.publisherSubKeyword = publisherSubKeyword;
        return this;
    }

    /**
     * Add a custom Publisher Sub Publisher String to the Preload Data.
     * @param publisherSubPublisher Publisher Sub Publisher Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withPublisherSubPublisher(String publisherSubPublisher) {
        this.publisherSubPublisher = publisherSubPublisher;
        return this;
    }

    /**
     * Add a custom Publisher Sub Site String to the Preload Data.
     * @param publisherSubSite Publisher Sub Site Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withPublisherSubSite(String publisherSubSite) {
        this.publisherSubSite = publisherSubSite;
        return this;
    }

    /**
     * Add a custom Advertiser Sub Ad String to the Preload Data.
     * @param advertiserSubAd Advertiser Sub Ad Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withAdvertiserSubAd(String advertiserSubAd) {
        this.advertiserSubAd = advertiserSubAd;
        return this;
    }

    /**
     * Add a custom Advertiser Sub Ad Group String to the Preload Data.
     * @param advertiserSubAdgroup Advertiser Sub Ad Group Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withAdvertiserSubAdgroup(String advertiserSubAdgroup) {
        this.advertiserSubAdgroup = advertiserSubAdgroup;
        return this;
    }

    /**
     * Add a custom Advertiser Sub Campaign String to the Preload Data.
     * @param advertiserSubCampaign Advertiser Sub Campaign Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withAdvertiserSubCampaign(String advertiserSubCampaign) {
        this.advertiserSubCampaign = advertiserSubCampaign;
        return this;
    }

    /**
     * Add a custom Advertiser Sub Keyword String to the Preload Data.
     * @param advertiserSubKeyword Advertiser Sub Keyword Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withAdvertiserSubKeyword(String advertiserSubKeyword) {
        this.advertiserSubKeyword = advertiserSubKeyword;
        return this;
    }

    /**
     * Add a custom Advertiser Sub Publisher String to the Preload Data.
     * @param advertiserSubPublisher Advertiser Sub Publisher Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withAdvertiserSubPublisher(String advertiserSubPublisher) {
        this.advertiserSubPublisher = advertiserSubPublisher;
        return this;
    }

    /**
     * Add a custom Advertiser Sub Site String to the Preload Data.
     * @param advertiserSubSite Advertiser Sub Site Data
     * @return this {@link TunePreloadData}
     */
    public TunePreloadData withAdvertiserSubSite(String advertiserSubSite) {
        this.advertiserSubSite = advertiserSubSite;
        return this;
    }

    String getPublisherId() {
        return publisherId;
    }

    String getOfferId() {
        return offerId;
    }

    String getAgencyId() {
        return agencyId;
    }

    String getPublisherReferenceId() {
        return publisherReferenceId;
    }

    String getPublisherSub1() {
        return publisherSub1;
    }

    String getPublisherSub2() {
        return publisherSub2;
    }

    String getPublisherSub3() {
        return publisherSub3;
    }

    String getPublisherSub4() {
        return publisherSub4;
    }

    String getPublisherSub5() {
        return publisherSub5;
    }

    String getPublisherSubAd() {
        return publisherSubAd;
    }

    String getPublisherSubAdgroup() {
        return publisherSubAdgroup;
    }

    String getPublisherSubCampaign() {
        return publisherSubCampaign;
    }

    String getPublisherSubKeyword() {
        return publisherSubKeyword;
    }

    String getPublisherSubPublisher() {
        return publisherSubPublisher;
    }

    String getPublisherSubSite() {
        return publisherSubSite;
    }

    String getAdvertiserSubAd() {
        return advertiserSubAd;
    }

    String getAdvertiserSubAdgroup() {
        return advertiserSubAdgroup;
    }

    String getAdvertiserSubCampaign() {
        return advertiserSubCampaign;
    }

    String getAdvertiserSubKeyword() {
        return advertiserSubKeyword;
    }

    String getAdvertiserSubPublisher() {
        return advertiserSubPublisher;
    }

    String getAdvertiserSubSite() {
        return advertiserSubSite;
    }
}
