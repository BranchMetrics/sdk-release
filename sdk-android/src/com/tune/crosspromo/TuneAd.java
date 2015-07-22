package com.tune.crosspromo;

/**
 * 
 * Interface to implement for all ad types
 */
public interface TuneAd {
    /**
     * Display an ad for given placement and metadata
     * 
     * @param placement
     *            placement of the ad
     * @param metadata
     *            metadata to associate with ad
     */
    public void show(String placement, TuneAdMetadata metadata);

    /**
     * Display an ad for given placement
     * @param placement
     *            placement of the ad
     */
    public void show(String placement);

    /**
     * Sets the TuneAdListener to receive ad load status events
     * 
     * @param listener
     *            The TuneAdListener to receive ad status events
     */
    public void setListener(TuneAdListener listener);

    /**
     * Free ad resources
     */
    public void destroy();
}
