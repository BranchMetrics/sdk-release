package com.tune;

public class GetterTests extends TuneUnitTest {
    public void testAction() {
        String action = tune.getAction();
        assertNull( "action was not null, was " + action, action );
    }
    
    public void testMatId() {
        String matId = tune.getMatId();
        assertNotNull( "MAT ID was null", matId );
    }

    /* TODO: test these too
     * 

    public String getAction() {

    public String getAdvertiserId() {

    public int getAge() {

    public double getAltitude() {

    public String getAndroidId() {

    public String getAndroidIdMd5() {
        
    public String getAndroidIdSha1() {

    public String getAndroidIdSha256() {

    public boolean getAppAdTrackingEnabled() {

    public String getAppName() {

    public int getAppVersion() {

    public String getConnectionType() {

    public String getCountryCode() {

    public String getDeviceBrand() {

    public String getDeviceId() {

    public String getDeviceModel() {

    public String getCurrencyCode() {

    public String getDeviceCarrier() {

    public String getEventAttribute1() {

    public String getEventAttribute2() {

    public String getEventAttribute3() {

    public String getEventAttribute4() {

    public String getEventAttribute5() {

    public String getEventId() {

    public String getEventName() {

    public boolean getExistingUser() {

    public String getFacebookUserId() {

    public int getGender() {

    public String getGoogleAdvertisingId() {

    public boolean getGoogleAdTrackingLimited() {

    public String getGoogleUserId() {

    public long getInstallDate() {

    public String getInstallLogId() {

    public String getInstallReferrer() {

    public boolean getIsPayingUser() {

    public String getLanguage() {

    public String getLastOpenLogId() {

    public double getLatitude() {

    public double getLongitude() {

    public String getMacAddress() {

    public String getMatId() {

    public String getMCC() {

    public String getMNC() {

    public String getOpenLogId() {

    public String getOsVersion() {

    public String getPackageName() {

    public String getPluginName() {

    public String getReferralSource() {

    public String getReferralUrl() {

    public String getRefId() {

    public Double getRevenue() {

    public String getScreenDensity() {

    public String getScreenSize() {

    public String getSDKVersion() {

    public String getSiteId() {

    public String getTRUSTeId() {

    public String getTwitterUserId() {

    public String getUpdateLogId() {

    public String getUserAgent() {

    public String getUserEmail() {

    public String getUserId() {

    public String getUserName() {
*/
}
