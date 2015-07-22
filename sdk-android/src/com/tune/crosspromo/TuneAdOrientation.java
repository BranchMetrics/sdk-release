package com.tune.crosspromo;

import java.util.Locale;

/**
 * Orientation of requested ads
 */
public enum TuneAdOrientation {
    ALL, PORTRAIT_ONLY, LANDSCAPE_ONLY;

    public static TuneAdOrientation forValue(final String value) {
        final String enumName = value.toUpperCase(Locale.ENGLISH);
        return TuneAdOrientation.valueOf(enumName);
    }

    public String value() {
        return name();
    }
}
