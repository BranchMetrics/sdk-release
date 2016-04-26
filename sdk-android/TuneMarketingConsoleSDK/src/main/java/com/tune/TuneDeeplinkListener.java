package com.tune;

public interface TuneDeeplinkListener {
    public abstract void didReceiveDeeplink(String deeplink);
    
    public abstract void didFailDeeplink(String error);
}
