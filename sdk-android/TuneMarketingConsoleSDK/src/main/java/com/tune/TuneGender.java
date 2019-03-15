package com.tune;

/**
 * Gender enum for user.
 * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
 */
@Deprecated
public enum TuneGender {
    MALE,
    FEMALE,
    UNKNOWN;

    static final String MALE_STRING_VAL = "0";
    static final String FEMALE_STRING_VAL = "1";
}