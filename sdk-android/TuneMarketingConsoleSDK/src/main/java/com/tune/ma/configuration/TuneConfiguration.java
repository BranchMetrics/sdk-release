package com.tune.ma.configuration;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by kristine on 1/26/16.
 */
public class TuneConfiguration {

    private boolean debugLoggingOn;
    private boolean debugMode;

    private String playlistHostPort;
    private String configurationHostPort;
    private String analyticsHostPort;
    private String connectedModeHostPort;
    private String staticContentHostPort;

    private boolean echoAnalytics;
    private boolean echoFiveline;
    private boolean echoPlaylists;
    private boolean echoConfigurations;
    private boolean echoPushes;

    private boolean usePlaylistPlayer;
    private List<String> playlistPlayerFilenames;
    private boolean useConfigurationPlayer;
    private List<String> configurationPlayerFilenames;

    private boolean autoCollectDeviceLocation;
    private boolean sendScreenViews;
    private boolean pollForPlaylist;

    //analytics properties
    private int analyticsDispatchPeriod;
    private int analyticsMessageStorageLimit;
    private int playlistRequestPeriod;

    private List<String> PIIFiltersAsStrings;
    private String pluginName;

    public TuneConfiguration() {
        setDefaultConfiguration();
    }

    public void setDefaultConfiguration() {
        debugLoggingOn = false;
        debugMode = false;
        echoAnalytics = false;
        echoFiveline = false;
        echoPlaylists = false;
        echoConfigurations = false;
        echoPushes = false;
        usePlaylistPlayer = false;

        playlistHostPort = "https://playlist.ma.tune.com";
        configurationHostPort = "https://configuration.ma.tune.com";
        analyticsHostPort = "https://analytics.ma.tune.com/analytics";
        staticContentHostPort = "https://s3.amazonaws.com/uploaded-assets-production";
        connectedModeHostPort = "https://connected.ma.tune.com";

        autoCollectDeviceLocation = true;
        sendScreenViews = false;
        pollForPlaylist = false;

        analyticsDispatchPeriod = 120;
        analyticsMessageStorageLimit = 250;

        playlistRequestPeriod = 180;

        pluginName = null;
        PIIFiltersAsStrings = new ArrayList<>();

    }

    /**
     * Enables debug output from TUNE in LogCat
     * @param debugLoggingOn Whether to enable debug mode
     * @see <a href="https://developers.tune.com/sdk/advanced-configuration/#code-platform-android">Advanced Configuration</a>
     */
    public void setDebugLoggingOn(boolean debugLoggingOn) {
        this.debugLoggingOn = debugLoggingOn;
    }

    public boolean debugLoggingOn() {
        return debugLoggingOn;
    }

    public boolean debugMode() {
        return debugMode;
    }

    /**
     * Enables debug output from TUNE in LogCat
     * @param debugMode Whether to enable debug mode
     */
    public void setDebugMode(boolean debugMode) {
        this.debugMode = debugMode;
    }

    public String getPlaylistHostPort() {
        return playlistHostPort;
    }

    public void setPlaylistHostPort(String playlistHostPort) {
        this.playlistHostPort = playlistHostPort;
    }

    public String getConfigurationHostPort() {
        return configurationHostPort;
    }

    public void setConfigurationHostPort(String configurationHostPort) {
        this.configurationHostPort = configurationHostPort;
    }

    public String getAnalyticsHostPort() {
        return analyticsHostPort;
    }

    public void setAnalyticsHostPort(String analyticsHostPort) {
        this.analyticsHostPort = analyticsHostPort;
    }

    public String getConnectedModeHostPort() {
        return connectedModeHostPort;
    }

    public void setConnectedModeHostPort(String connectedModeHostPort) {
        this.connectedModeHostPort = connectedModeHostPort;
    }

    public boolean echoAnalytics() {
        return echoAnalytics;
    }

    public void setEchoAnalytics(boolean echoAnalytics) {
        this.echoAnalytics = echoAnalytics;
    }

    public boolean echoFiveline() {
        return echoFiveline;
    }

    public void setEchoFiveline(boolean echoFiveline) {
        this.echoFiveline = echoFiveline;
    }

    public boolean echoPlaylists() {
        return echoPlaylists;
    }

    public void setEchoPlaylists(boolean echoPlaylists) {
        this.echoPlaylists = echoPlaylists;
    }

    public boolean echoConfigurations() {
        return echoConfigurations;
    }

    public void setEchoConfigurations(boolean echoConfigurations) {
        this.echoConfigurations = echoConfigurations;
    }

    public boolean echoPushes() {
        return echoPushes;
    }

    public void setEchoPushes(boolean echoPushes) {
        this.echoPushes = echoPushes;
    }

    public boolean usePlaylistPlayer() {
        return usePlaylistPlayer;
    }

    public void setUsePlaylistPlayer(boolean usePlaylistPlayer) {
        this.usePlaylistPlayer = usePlaylistPlayer;
    }

    public List<String> getPlaylistPlayerFilenames() {
        return playlistPlayerFilenames;
    }

    public void setPlaylistPlayerFilenames(List<String> playlistPlayerFilenames) {
        this.playlistPlayerFilenames = playlistPlayerFilenames;
    }

    public boolean useConfigurationPlayer() {
        return useConfigurationPlayer;
    }

    public void setUseConfigurationPlayer(boolean useConfigurationPlayer) {
        this.useConfigurationPlayer = useConfigurationPlayer;
    }

    public List<String> getConfigurationPlayerFilenames() {
        return configurationPlayerFilenames;
    }

    public void setConfigurationPlayerFilenames(List<String> configurationPlayerFilenames) {
        this.configurationPlayerFilenames = configurationPlayerFilenames;
    }

    public boolean shouldAutoCollectDeviceLocation() {
        return autoCollectDeviceLocation;
    }

    /**
     * Set whether to autocollect device location if location is enabled
     * @param shouldAutoCollectDeviceLocation Autocollect device location, default is true
     * @see <a href="https://developers.tune.com/sdk/advanced-configuration/#code-platform-android">Advanced Configuration</a>
     */
    public void setShouldAutoCollectDeviceLocation(boolean shouldAutoCollectDeviceLocation) {
        this.autoCollectDeviceLocation = shouldAutoCollectDeviceLocation;
    }

    public boolean shouldSendScreenViews() {
        return sendScreenViews;
    }

    /**
     * Set whether to collect screen views
     * @param shouldSendScreenViews Collect names of screens (Activities) seen, default is false
     * @see <a href="https://developers.tune.com/sdk/advanced-configuration/#code-platform-android">Advanced Configuration</a>
     */
    public void setShouldSendScreenViews(boolean shouldSendScreenViews) {
        this.sendScreenViews = shouldSendScreenViews;
    }

    public boolean getPollForPlaylist() {
        return pollForPlaylist;
    }

    public void setPollForPlaylist(boolean pollForPlaylist) {
        this.pollForPlaylist = pollForPlaylist;
    }

    public int getAnalyticsDispatchPeriod() {
        return analyticsDispatchPeriod;
    }

    public void setAnalyticsDispatchPeriod(int analyticsDispatchPeriod) {
        this.analyticsDispatchPeriod = analyticsDispatchPeriod;
    }

    public int getAnalyticsMessageStorageLimit() {
        return analyticsMessageStorageLimit;
    }

    public void setAnalyticsMessageStorageLimit(int analyticsMessageStorageLimit) {
        this.analyticsMessageStorageLimit = analyticsMessageStorageLimit;
    }

    public int getPlaylistRequestPeriod() {
        return playlistRequestPeriod;
    }

    public void setPlaylistRequestPeriod(int playlistRequestPeriod) {
        this.playlistRequestPeriod = playlistRequestPeriod;
    }

    public List<String> getPIIFiltersAsStrings() {
        return PIIFiltersAsStrings;
    }

    /**
     * Set filters for PII (Personally Identifiable Information) to not be sent from SDK
     * @param PIIFiltersAsStrings Regular expressions for data that should be redacted before sending
     * @see <a href="https://developers.tune.com/sdk/advanced-configuration/#code-platform-android">Advanced Configuration</a>
     */
    public void setPIIFiltersAsStrings(List<String> PIIFiltersAsStrings) {
        this.PIIFiltersAsStrings = PIIFiltersAsStrings;
    }

    public String getPluginName() {
        return pluginName;
    }

    public void setPluginName(String pluginName) {
        this.pluginName = pluginName;
    }

    public String getStaticContentHostPort() {
        return staticContentHostPort;
    }

    public void setStaticContentHostPort(String staticContentHostPort) {
        this.staticContentHostPort = staticContentHostPort;
    }
}
