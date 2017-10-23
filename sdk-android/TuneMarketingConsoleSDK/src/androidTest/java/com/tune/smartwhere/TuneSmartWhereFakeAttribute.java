package com.tune.smartwhere;

import android.content.Context;

import java.util.HashMap;

@SuppressWarnings("WeakerAccess")
public class  TuneSmartWhereFakeAttribute{
    static TuneSmartWhereFakeAttribute instance;

    public static Object getInstance(Context context) {
        return instance;
    }

    @SuppressWarnings("unused")
    public void setAttributeValue(String name, String value) {
    }

    @SuppressWarnings("unused")
    public void removeAttributeValue(String name) {
    }

    @SuppressWarnings("unused")
    public HashMap<String, String> getAttributes() {
        return null;
    }
}


