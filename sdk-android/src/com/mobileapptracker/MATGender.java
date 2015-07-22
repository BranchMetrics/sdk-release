package com.mobileapptracker;

import java.util.Locale;

/**
 * Gender enum for user
 */
public enum MATGender {
    MALE,
    FEMALE,
    UNKNOWN;

    public static MATGender forValue(final String value) {
        final String enumName = value.toUpperCase(Locale.ENGLISH);
        return MATGender.valueOf(enumName);
    }

    public String value() {
        return name();
    }
}
