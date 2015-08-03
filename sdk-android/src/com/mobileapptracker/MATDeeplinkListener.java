package com.mobileapptracker;

public interface MATDeeplinkListener {
    public abstract void didReceiveDeeplink(String deeplink);
    
    public abstract void didFailDeeplink(String error);
}
