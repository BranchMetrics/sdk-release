package com.tune.crosspromo;

import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.TimeZone;

import android.location.Location;

import com.mobileapptracker.MATGender;

/**
 * A TuneAdMetadata object contains user information about the ad to fetch. The
 * request object contains targeting info and its testing flag
 */
public class TuneAdMetadata {
    private MATGender mGender;
    private Date mBirthDate;
    private Location mLocation;
    private double mLatitude, mLongitude;
    private Set<String> mKeywords;
    private Map<String, String> mCustomTargets;
    private boolean mDebugMode;

    /**
     * Default TuneAdMetadata Object with gender : UNKNOWN, birthDate : null,
     * location: null, keywords : empty,
     * customTargets: empty, debugMode : false
     */
    public TuneAdMetadata() {
        mGender = MATGender.UNKNOWN;
        mBirthDate = null;
        mLocation = null;
        mKeywords = null;
        mCustomTargets = null;
        mDebugMode = false;
    }

    /**
     * 
     * Checks if the request is for debug
     * 
     * @return debug mode enabled
     */
    public boolean isInDebugMode() {
        return mDebugMode;
    }

    /**
     * 
     * Sets the request to be in debug mode
     * 
     * @param debugMode
     *            debug enabled
     */
    public TuneAdMetadata withDebugMode(boolean debugMode) {
        mDebugMode = debugMode;
        return this;
    }

    /**
     * Gets user's birthdate
     * 
     * @return birthdate
     */
    public Date getBirthDate() {
        return mBirthDate;
    }

    /**
     * 
     * Sets user's birthdate for targeting purpose
     * 
     * @param year
     * @param month
     *            range from 1 to 12
     * @param day
     */
    public TuneAdMetadata withBirthDate(int year, int month, int day) {
        GregorianCalendar gc = new GregorianCalendar(
                TimeZone.getTimeZone("UTC"));
        gc.clear();
        gc.set(year, month - 1, day);
        mBirthDate = gc.getTime();
        return this;
    }

    /**
     * 
     * Sets user's birthdate for targeting purpose
     * 
     * @param birthDate
     *            birthdate
     */
    public TuneAdMetadata withBirthDate(Date birthDate) {
        mBirthDate = birthDate;
        return this;
    }

    /**
     * Gets custom targeting key-values
     * 
     * @return custom targeting key-values
     */
    public Map<String, String> getCustomTargets() {
        return mCustomTargets;
    }

    /**
     * Sets custom key-value pairs to use for targeting
     * 
     * @param customTargets
     *            map of key-value pairs for additional targeting
     */
    public TuneAdMetadata withCustomTargets(Map<String, String> customTargets) {
        mCustomTargets = customTargets;
        return this;
    }

    /**
     * 
     * Gets the user's gender
     * 
     * @return gender
     */
    public MATGender getGender() {
        return mGender;
    }

    /**
     * 
     * Sets the user's gender for targeting purpose
     * 
     * @param gender
     *            user's gender
     */
    public TuneAdMetadata withGender(MATGender gender) {
        mGender = gender;
        return this;
    }

    /**
     * 
     * Gets ad keywords
     * 
     * @return Set of ad keywords
     */
    public Set<String> getKeywords() {
        return mKeywords;
    }

    /**
     * 
     * Sets user's keywords for targeting purpose
     * 
     * @param keywords
     */
    public TuneAdMetadata withKeywords(Set<String> keywords) {
        mKeywords = keywords;
        return this;
    }

    /**
     * Add user's keyword for targeting purpose
     * 
     * @param keyword
     * @return if keyword was added
     */
    public boolean addKeyword(String keyword) {
        if (mKeywords == null) {
            mKeywords = new HashSet<String>();
        }

        return mKeywords.add(keyword);
    }

    /**
     * Remove a keyword
     * 
     * @param keyword
     * @return if keyword was removed
     */
    public boolean removeKeyword(String keyword) {
        if (mKeywords == null) {
            mKeywords = new HashSet<String>();
            return false;
        }
        return mKeywords.remove(keyword);
    }

    /**
     * Gets user's location
     * 
     * @return location
     */
    public Location getLocation() {
        return mLocation;
    }

    /**
     * Set user's location for targeting purpose
     * 
     * @param location
     */
    public TuneAdMetadata withLocation(Location location) {
        mLocation = location;
        return this;
    }

    /**
     * Gets user's latitude
     * @return latitude
     */
    public double getLatitude() {
        return mLatitude;
    }

    /**
     * Gets user's longitude
     * @return longitude
     */
    public double getLongitude() {
        return mLongitude;
    }

    /**
     * Set user's location latitude/longitude for targeting purpose
     * @param latitude
     */
    public TuneAdMetadata withLocation(double latitude, double longitude) {
        mLatitude = latitude;
        mLongitude = longitude;
        return this;
    }
}
