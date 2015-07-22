package com.tune.crosspromo;

/**
 * A simple interface for receiving notifications on the status of ad requests
 */
public interface TuneAdListener {
    /**
     * Called when inventory is loaded with a ad
     * 
     * @param ad
     *            Ad that generated this notification
     */
    public void onAdLoad(TuneAd ad);

    /**
     * 
     * Called when inventory failed to load a ad
     * 
     * @param ad
     *            Ad that generated this notification
     * @param error
     *            The error stating why an ad was not loaded
     */
    public void onAdLoadFailed(TuneAd ad, String error);

    /**
     * 
     * Called when Ad is shown
     * 
     * @param ad
     *            Ad that generated this notification
     */
    public void onAdShown(TuneAd ad);

    /**
     * Called when Ad is clicked
     * 
     * @param ad
     *            Ad that generated this notification
     * 
     */
    public void onAdClick(TuneAd ad);
}
