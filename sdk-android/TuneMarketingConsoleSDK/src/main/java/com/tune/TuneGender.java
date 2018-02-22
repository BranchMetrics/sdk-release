package com.tune;

import java.util.Locale;

/**
 * Gender enum for user
 */
public enum TuneGender {
    MALE,
    FEMALE,
    UNKNOWN;

    public static TuneGender forValue(final String value) {
        final String enumName = value.toUpperCase(Locale.ENGLISH);
        return TuneGender.valueOf(enumName);
    }
}