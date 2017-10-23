package com.tune.smartwhere;

import android.content.Context;

@SuppressWarnings("WeakerAccess")
public class TuneSmartWhereFakeTrackingAttribute {
    static TuneSmartWhereFakeTrackingAttribute instance;

    public static Object getInstance(Context context) {
        return instance;
    }

    public void setAttributeValue(String name, String value) {
    }

    public void removeAttributeValue(String name) {
    }
}
