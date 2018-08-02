package com.tune;

/**
 * Tune Deeplink Listener interface.
 */
public interface TuneDeeplinkListener {
    void didReceiveDeeplink(String deeplink);
    
    void didFailDeeplink(String error);
}
