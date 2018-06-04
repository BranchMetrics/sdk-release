package com.tune.ma.profile;

import android.support.test.runner.AndroidJUnit4;

import com.tune.TuneConstants;
import com.tune.TuneLocation;
import com.tune.TuneParameters;
import com.tune.TuneTestConstants;
import com.tune.TuneTestWrapper;
import com.tune.TuneUnitTest;
import com.tune.TuneUrlKeys;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.constants.TuneVariableType;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.userprofile.TuneCustomProfileVariablesCleared;
import com.tune.ma.eventbus.event.userprofile.TuneUpdateUserProfile;

import org.greenrobot.eventbus.Subscribe;
import org.json.JSONArray;
import org.json.JSONException;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Set;

import static android.support.test.InstrumentationRegistry.getContext;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

/**
 * Created by charlesgilliam on 1/25/16.
 */
@RunWith(AndroidJUnit4.class)
public class TuneUserProfileTests extends TuneUnitTest {
    Integer clearCalledCount = 0;
    TuneUserProfile profile;

    @Before
    public void setUp() throws Exception {
        super.setUp();
        profile = TuneManager.getInstance().getProfileManager();
        clearCalledCount = 0;
        TuneEventBus.register(this);

        profile.deleteSharedPrefs();
    }

    @After
    public void tearDown() throws Exception {
        super.tearDown();
        TuneEventBus.unregister(this);
    }

    @Subscribe
    public void onEvent(TuneCustomProfileVariablesCleared event) {
        clearCalledCount += 1;
    }

    @Test
    public void testRegisterCustomProfileVariableShouldAddToUserProfile() {
        profile.registerCustomProfileVariable(new TuneAnalyticsVariable("test", "initial"));

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("test");

        assertTrue(var != null);
        assertTrue("test".equalsIgnoreCase(var.getName()));
        assertTrue("initial".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    @Test
    public void testSetCustomVariableValueShouldUpdateValue() {
        profile.registerCustomProfileVariable(new TuneAnalyticsVariable("test", (String)null));
        profile.setCustomProfileVariable(new TuneAnalyticsVariable("test", "updated"));

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("test");

        assertTrue(var != null);
        assertTrue("test".equalsIgnoreCase(var.getName()));
        assertTrue("updated".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        profile.setCustomProfileVariable(new TuneAnalyticsVariable("test", "latest"));

        var = profile.getCustomProfileVariable("test");

        assertTrue(var != null);
        assertTrue("test".equalsIgnoreCase(var.getName()));
        assertTrue("latest".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    @Test
    public void testSetCustomVariableValueToNullIsOkay() {
        profile.registerCustomProfileVariable(new TuneAnalyticsVariable("test", "not null"));
        profile.setCustomProfileVariable(new TuneAnalyticsVariable("test", (String)null));

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("test");

        assertTrue(var != null);
        assertTrue("test".equalsIgnoreCase(var.getName()));
        assertTrue(var.getValue() == null);
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    @Test
    public void testCannotChangeCustomVariableTypeOnceRegistered() {
        profile.registerCustomProfileVariable(new TuneAnalyticsVariable("test", 2));
        profile.setCustomProfileVariable(new TuneAnalyticsVariable("test", "Not a number!"));

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("test");

        assertTrue(var != null);
        assertTrue("test".equalsIgnoreCase(var.getName()));
        assertTrue("2".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.FLOAT);
    }

    @Test
    public void testDefaultValueShouldBeNull() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("testString");

        assertTrue(var != null);
        assertTrue("testString".equalsIgnoreCase(var.getName()));
        assertTrue(var.getValue() == null);
        assertTrue(var.getType() == TuneVariableType.STRING);

        TuneTestWrapper.getInstance().registerCustomProfileDate("testDate");

        var = profile.getCustomProfileVariable("testDate");

        assertTrue(var != null);
        assertTrue("testDate".equalsIgnoreCase(var.getName()));
        assertTrue(var.getValue() == null);
        assertTrue(var.getType() == TuneVariableType.DATETIME);

        TuneTestWrapper.getInstance().registerCustomProfileNumber("testNumber");

        var = profile.getCustomProfileVariable("testNumber");

        assertTrue(var != null);
        assertTrue("testNumber".equalsIgnoreCase(var.getName()));
        assertTrue(var.getValue() == null);
        assertTrue(var.getType() == TuneVariableType.FLOAT);

        TuneTestWrapper.getInstance().registerCustomProfileGeolocation("testLocation");

        var = profile.getCustomProfileVariable("testLocation");

        assertTrue(var != null);
        assertTrue("testLocation".equalsIgnoreCase(var.getName()));
        assertTrue(var.getValue() == null);
        assertTrue(var.getType() == TuneVariableType.GEOLOCATION);

        // NOTE: We aren't exposing these setter types yet, so we are setting them directly.

        profile.registerCustomProfileVariable(new TuneAnalyticsVariable("testBoolean", null, TuneVariableType.BOOLEAN));

        var = profile.getCustomProfileVariable("testBoolean");

        assertTrue(var != null);
        assertTrue("testBoolean".equalsIgnoreCase(var.getName()));
        assertTrue(var.getValue() == null);
        assertTrue(var.getType() == TuneVariableType.BOOLEAN);

        profile.registerCustomProfileVariable(new TuneAnalyticsVariable("testVersion", null, TuneVariableType.VERSION));

        var = profile.getCustomProfileVariable("testVersion");

        assertTrue(var != null);
        assertTrue("testVersion".equalsIgnoreCase(var.getName()));
        assertTrue(var.getValue() == null);
        assertTrue(var.getType() == TuneVariableType.VERSION);
    }

    @Test
    public void testRegisterWithDefault() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString", "defaultString");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("testString");

        assertTrue(var != null);
        assertTrue("testString".equalsIgnoreCase(var.getName()));
        assertTrue("defaultString".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        Date d = new Date(0);
        TuneTestWrapper.getInstance().registerCustomProfileDate("testDate", d);

        var = profile.getCustomProfileVariable("testDate");

        assertTrue(var != null);
        assertTrue("testDate".equalsIgnoreCase(var.getName()));
        assertTrue(TuneAnalyticsVariable.dateToString(d).equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.DATETIME);

        TuneTestWrapper.getInstance().registerCustomProfileNumber("testNumber", 7.999);

        var = profile.getCustomProfileVariable("testNumber");

        assertTrue(var != null);
        assertTrue("testNumber".equalsIgnoreCase(var.getName()));
        assertTrue("7.999".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.FLOAT);

        TuneLocation l = new TuneLocation(7.00, 8.00);
        TuneTestWrapper.getInstance().registerCustomProfileGeolocation("testLocation", l);

        var = profile.getCustomProfileVariable("testLocation");

        assertTrue(var != null);
        assertTrue("testLocation".equalsIgnoreCase(var.getName()));
        assertTrue(TuneAnalyticsVariable.geolocationToString(l).equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.GEOLOCATION);

        // NOTE: We aren't exposing these setter types yet, so we are setting them directly.

        profile.registerCustomProfileVariable(new TuneAnalyticsVariable("testBoolean", true));

        var = profile.getCustomProfileVariable("testBoolean");

        assertTrue(var != null);
        assertTrue("testBoolean".equalsIgnoreCase(var.getName()));
        assertTrue("1".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.BOOLEAN);

        profile.registerCustomProfileVariable(new TuneAnalyticsVariable("testVersion", "1.0.1", TuneVariableType.VERSION));

        var = profile.getCustomProfileVariable("testVersion");

        assertTrue(var != null);
        assertTrue("testVersion".equalsIgnoreCase(var.getName()));
        assertTrue("1.0.1".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.VERSION);
    }

    @Test
    public void testRegisterWithWeirdName() {
        TuneTestWrapper.getInstance().registerCustomProfileString("&&&foo***()bar", "bingbang");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("foobar");

        assertTrue(var != null);
        assertTrue("foobar".equalsIgnoreCase(var.getName()));
        assertTrue("bingbang".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    @Test
    public void testRegisterWithSpaces() {
        TuneTestWrapper.getInstance().registerCustomProfileString("I HAVE SPACES", "bingbang");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("IHAVESPACES");

        assertTrue(var != null);
        assertTrue("IHAVESPACES".equalsIgnoreCase(var.getName()));
        assertTrue("bingbang".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    @Test
    public void testRegisterStringWithNonUSNumbers() {
        TuneTestWrapper.getInstance().registerCustomProfileString("bingbang", "١٢٣٤٥٦-٧.٨.٩ ٠");

        TuneAnalyticsVariable var = profile.getProfileVariableFromPrefs("bingbang");

        assertTrue(var != null);
        assertTrue("bingbang".equalsIgnoreCase(var.getName()));
        assertTrue("١٢٣٤٥٦-٧.٨.٩ ٠".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    @Test
    public void testRegisterLocationWithNonUSLocale() {
        // Spoof a locale, e.g. Arabic
        Locale locale = new Locale("ar");
        Locale.setDefault(locale);
        getContext().getResources().getConfiguration().locale = locale;

        TuneLocation location = new TuneLocation(111.11, -222.22);
        TuneTestWrapper.getInstance().registerCustomProfileGeolocation("location", location);
        TuneAnalyticsVariable var = profile.getProfileVariableFromPrefs("location");

        assertTrue(var != null);
        assertTrue("location".equalsIgnoreCase(var.getName()));
        assertTrue("111.110000000,-222.220000000".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.GEOLOCATION);

        // Revert to US locale
        locale = new Locale("us");
        Locale.setDefault(locale);
        getContext().getResources().getConfiguration().locale = locale;
    }

    @Test
    public void testRegisterWithOnlyWeirdChars() {
        TuneTestWrapper.getInstance().registerCustomProfileString("$()*())#$()", "bingbang");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("");
        TuneAnalyticsVariable var2 = profile.getCustomProfileVariable("$()*())#$()");

        assertTrue(var == null);
        assertTrue(var2 == null);
    }

    @Test
    public void testRegisterWithGreekChars() {
        String key = "Greek";
        String defaultValue = "Εμπρός";

        tune.registerCustomProfileString(key, defaultValue);
        String test = tune.getCustomProfileString(key);

        assertEquals(defaultValue, test);
    }

    @Test
    public void testSetWithWeirdName() {
        TuneTestWrapper.getInstance().registerCustomProfileString("foobar");
        TuneTestWrapper.getInstance().setCustomProfileStringValue(")*(#&(*foobar*)(*()", "bingbang");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("foobar");

        assertTrue(var != null);
        assertTrue("foobar".equalsIgnoreCase(var.getName()));
        assertTrue("bingbang".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    @Test
    public void testSetWithOnlyWeirdChars() {
        TuneTestWrapper.getInstance().registerCustomProfileString("foobar");
        TuneTestWrapper.getInstance().setCustomProfileStringValue(")*(#&(**)(*()", "bingbang");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("foobar");
        TuneAnalyticsVariable var2 = profile.getCustomProfileVariable("");

        assertTrue(var != null);
        assertTrue("foobar".equalsIgnoreCase(var.getName()));
        assertTrue(var.getValue() == null);
        assertTrue(var.getType() == TuneVariableType.STRING);

        assertTrue(var2 == null);
    }

    @Test
    public void testRegisterSystemVariable() {
        TuneTestWrapper.getInstance().registerCustomProfileString("google_aid", "not null");

        // NOTE: Since we clear out the sharedprefs before running this should be null
        TuneAnalyticsVariable var = profile.getProfileVariable("google_aid");

        assertFalse(var.getValue().equals("not null"));
    }

    @Test
    public void testSetSystemVariable() {
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable("google_aid", "99111")));
        TuneTestWrapper.getInstance().setCustomProfileStringValue("google_aid", "not null");

        TuneAnalyticsVariable var = profile.getProfileVariable("google_aid");

        assertTrue(var != null);
        assertTrue("google_aid".equalsIgnoreCase(var.getName()));
        assertTrue("99111".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    // Test to make sure checks of custom variables are case-insensitive when registering them
    @Test
    public void testPreventsCollisionOfCustomVariableWithProfileVariable() {
        TuneTestWrapper.getInstance().registerCustomProfileString("Language", "Dravanian");
        TuneTestWrapper.getInstance().registerCustomProfileString("Device Token", "Knicknack");
        TuneTestWrapper.getInstance().registerCustomProfileString("Butterfly", "Monarch");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("Language");
        TuneAnalyticsVariable var2 = profile.getCustomProfileVariable("Device Token");
        TuneAnalyticsVariable var3 = profile.getCustomProfileVariable("DeviceToken");
        TuneAnalyticsVariable var4 = profile.getCustomProfileVariable("Butterfly");

        assertNull(var);
        assertNull(var2);
        assertNull(var3);
        assertEquals("Butterfly", var4.getName());
        assertEquals("Monarch", var4.getValue());
    }

    @Test
    public void testPreventAddingCustomProfileVariablesStartingWithTUNE() {
        TuneTestWrapper.getInstance().registerCustomProfileString("TUNE_whatever", "bingbang");
        TuneTestWrapper.getInstance().registerCustomProfileString("Tune_whatever", "bingbang");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("TUNE_whatever");
        TuneAnalyticsVariable var2 = profile.getCustomProfileVariable("Tune_whatever");

        assertTrue(var == null);
        assertTrue(var2 != null);
        assertTrue("Tune_whatever".equalsIgnoreCase(var2.getName()));
        assertTrue("bingbang".equalsIgnoreCase(var2.getValue()));
        assertTrue(var2.getType() == TuneVariableType.STRING);
    }

    @Test
    public void testPublicGettersNoDefault() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString");
        assertNull(TuneTestWrapper.getInstance().getCustomProfileString("testString"));

        TuneTestWrapper.getInstance().registerCustomProfileDate("testDate");
        assertNull(TuneTestWrapper.getInstance().getCustomProfileDate("testDate"));

        TuneTestWrapper.getInstance().registerCustomProfileNumber("testNumber");
        assertNull(TuneTestWrapper.getInstance().getCustomProfileNumber("testNumber"));

        TuneTestWrapper.getInstance().registerCustomProfileGeolocation("testLocation");
        assertNull(TuneTestWrapper.getInstance().getCustomProfileGeolocation("testLocation"));
    }

    @Test
    public void testPublicGettersWithDefault() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString", "default");
        assertTrue("default".equalsIgnoreCase(TuneTestWrapper.getInstance().getCustomProfileString("testString")));

        Date d = new Date(0);
        TuneTestWrapper.getInstance().registerCustomProfileDate("testDate", d);
        assertTrue(d.equals(TuneTestWrapper.getInstance().getCustomProfileDate("testDate")));

        TuneTestWrapper.getInstance().registerCustomProfileNumber("testNumber", 7.987);
        assertTrue(TuneTestWrapper.getInstance().getCustomProfileNumber("testNumber").doubleValue() == 7.987);

        TuneLocation l = new TuneLocation(9, 8);
        TuneTestWrapper.getInstance().registerCustomProfileGeolocation("testLocation", l);
        TuneLocation gotten = TuneTestWrapper.getInstance().getCustomProfileGeolocation("testLocation");
        assertTrue(gotten != null);
        assertTrue(l.getLatitude() == gotten.getLatitude());
        assertTrue(l.getLongitude() == gotten.getLongitude());
    }

    @Test
    public void testPublicGettersWithDefault_ThenSettersWithNoValue() {
        // Shortcut to register some variables
        testPublicGettersNoDefault();

        String nullString = null;
        TuneTestWrapper.getInstance().setCustomProfileStringValue("testString", nullString);
        assertEquals(null, TuneTestWrapper.getInstance().getCustomProfileString("testString"));

        Date nullDate = null;
        TuneTestWrapper.getInstance().setCustomProfileDate("testDate", nullDate);
        assertEquals(null, TuneTestWrapper.getInstance().getCustomProfileDate("testDate"));

        TuneLocation nullLocation = null;
        TuneTestWrapper.getInstance().setCustomProfileGeolocation("testLocation", nullLocation);
        assertEquals(null, TuneTestWrapper.getInstance().getCustomProfileGeolocation("testLocation"));
    }

    @Test
    public void testPublicClearCustomProfileVariable_WithNoValue() {
        String nullString = null;

        // This should just log, but not do anything else
        TuneTestWrapper.getInstance().clearCustomProfileVariable(nullString);

        // With debugMode on, this should throw an exception
        TuneTestWrapper.getInstance().setDebugMode(true);
        boolean caughtException = false;
        try {
            TuneTestWrapper.getInstance().clearCustomProfileVariable(nullString);
            assertFalse(true);
        } catch (IllegalArgumentException e) {
            // This is expected
            caughtException = true;
        }

        assertTrue(caughtException);
    }

    @Test
    public void testPublicGettersBeforeRegistration() {
        assertNull(TuneTestWrapper.getInstance().getCustomProfileString("testString"));
    }

    @Test
    public void testPublicSetters() {
        TuneTestWrapper.getInstance().registerCustomProfileNumber("int", 1);
        TuneAnalyticsVariable varInt = profile.getCustomProfileVariable("int");
        assertTrue("int".equalsIgnoreCase(varInt.getName()));
        assertTrue(varInt.getType() == TuneVariableType.FLOAT);
        assertEquals(1, Integer.parseInt(varInt.getValue()));

        TuneTestWrapper.getInstance().setCustomProfileNumber("int", 5);
        varInt = profile.getCustomProfileVariable("int");
        assertTrue("int".equalsIgnoreCase(varInt.getName()));
        assertTrue(varInt.getType() == TuneVariableType.FLOAT);
        assertEquals(5, Integer.parseInt(varInt.getValue()));

        TuneTestWrapper.getInstance().registerCustomProfileNumber("double", 0.99);
        TuneAnalyticsVariable varDouble = profile.getCustomProfileVariable("double");
        assertTrue("double".equalsIgnoreCase(varDouble.getName()));
        assertTrue(varDouble.getType() == TuneVariableType.FLOAT);
        assertEquals(0.99, Double.parseDouble(varDouble.getValue()), 0);

        TuneTestWrapper.getInstance().setCustomProfileNumber("double", 1.99);
        varDouble = profile.getCustomProfileVariable("double");
        assertTrue("double".equalsIgnoreCase(varDouble.getName()));
        assertTrue(varDouble.getType() == TuneVariableType.FLOAT);
        assertEquals(1.99, Double.parseDouble(varDouble.getValue()), 0);

        TuneTestWrapper.getInstance().registerCustomProfileNumber("float", 0.99f);
        TuneAnalyticsVariable varFloat = profile.getCustomProfileVariable("float");
        assertTrue("float".equalsIgnoreCase(varFloat.getName()));
        assertTrue(varFloat.getType() == TuneVariableType.FLOAT);
        assertEquals(0.99f, Float.parseFloat(varFloat.getValue()), 0);

        TuneTestWrapper.getInstance().setCustomProfileNumber("float", 1.99f);
        varFloat = profile.getCustomProfileVariable("float");
        assertTrue("float".equalsIgnoreCase(varFloat.getName()));
        assertTrue(varFloat.getType() == TuneVariableType.FLOAT);
        assertEquals(1.99f, Float.parseFloat(varFloat.getValue()), 0);

        Date expectedDate = new Date();
        TuneTestWrapper.getInstance().registerCustomProfileDate("date", expectedDate);
        TuneAnalyticsVariable varDate = profile.getCustomProfileVariable("date");
        assertTrue("date".equalsIgnoreCase(varDate.getName()));
        assertTrue(varDate.getType() == TuneVariableType.DATETIME);
        assertEquals(TuneAnalyticsVariable.dateToString(expectedDate), varDate.getValue());

        Date expectedDate2 = new Date();
        TuneTestWrapper.getInstance().setCustomProfileDate("date", expectedDate2);
        varDate = profile.getCustomProfileVariable("date");
        assertTrue("date".equalsIgnoreCase(varDate.getName()));
        assertTrue(varDate.getType() == TuneVariableType.DATETIME);
        assertEquals(TuneAnalyticsVariable.dateToString(expectedDate2), varDate.getValue());

        TuneLocation expectedLocation = new TuneLocation(1, 2);
        TuneTestWrapper.getInstance().registerCustomProfileGeolocation("location", expectedLocation);
        TuneAnalyticsVariable varLocation = profile.getCustomProfileVariable("location");
        assertTrue("location".equalsIgnoreCase(varLocation.getName()));
        assertTrue(varLocation.getType() == TuneVariableType.GEOLOCATION);
        assertEquals(TuneAnalyticsVariable.geolocationToString(expectedLocation), varLocation.getValue());

        TuneLocation expectedLocation2 = new TuneLocation(3, 4);
        TuneTestWrapper.getInstance().setCustomProfileGeolocation("location", expectedLocation2);
        varLocation = profile.getCustomProfileVariable("location");
        assertTrue("location".equalsIgnoreCase(varLocation.getName()));
        assertTrue(varLocation.getType() == TuneVariableType.GEOLOCATION);
        assertEquals(TuneAnalyticsVariable.geolocationToString(expectedLocation2), varLocation.getValue());
    }

    @Test
    public void testClearVariableAndSet() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString", "defaultString");
        TuneAnalyticsVariable var = profile.getCustomProfileVariable("testString");

        assertTrue(var != null);
        assertTrue("testString".equalsIgnoreCase(var.getName()));
        assertTrue("defaultString".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        TuneTestWrapper.getInstance().clearCustomProfileVariable("testString");
        var = profile.getCustomProfileVariable("testString");

        assertTrue(var == null);

        TuneTestWrapper.getInstance().setCustomProfileStringValue("testString", "new");
        var = profile.getCustomProfileVariable("testString");

        assertTrue(var != null);
        assertTrue("testString".equalsIgnoreCase(var.getName()));
        assertTrue("new".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    @Test
    public void testCantClearSystemVariables() {
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable("google_aid", "99111")));
        TuneTestWrapper.getInstance().clearCustomProfileVariable("google_aid");

        TuneAnalyticsVariable var = profile.getProfileVariable("google_aid");

        assertTrue(var != null);
        assertTrue("google_aid".equalsIgnoreCase(var.getName()));
        assertTrue("99111".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    @Test
    public void testClearCustomVariables() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString", "defaultString");
        TuneTestWrapper.getInstance().registerCustomProfileString("testString2", "defaultString2");
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable("google_aid", "99111")));

        TuneAnalyticsVariable var = profile.getProfileVariable("testString");
        assertTrue(var != null);
        assertTrue("testString".equalsIgnoreCase(var.getName()));
        assertTrue("defaultString".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        var = profile.getProfileVariable("testString2");
        assertTrue(var != null);
        assertTrue("testString2".equalsIgnoreCase(var.getName()));
        assertTrue("defaultString2".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        var = profile.getProfileVariable("google_aid");
        assertTrue(var != null);
        assertTrue("google_aid".equalsIgnoreCase(var.getName()));
        assertTrue("99111".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        // Remove a valid custom variable, an unregistered variable, and a non-custom variable.
        TuneTestWrapper.getInstance().clearCustomProfileVariable("testString");
        TuneTestWrapper.getInstance().clearCustomProfileVariable("not_valid");
        TuneTestWrapper.getInstance().clearCustomProfileVariable("google_aid");

        var = profile.getCustomProfileVariable("testString");
        assertNull(var);

        var = profile.getCustomProfileVariable("testString2");
        assertNotNull(var);

        var = profile.getProfileVariable("google_aid");
        assertNotNull(var);

        assertTrue(clearCalledCount == 1);
    }

    @Test
    public void testClearCustomVariableThenGet() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString", "defaultString");

        TuneTestWrapper.getInstance().clearCustomProfileVariable("testString");

        String s = TuneTestWrapper.getInstance().getCustomProfileString("testString");
        assertNull(s);
    }

    @Test
    public void testClearCustomVariablesInvalidName() {
        TuneTestWrapper.getInstance().registerCustomProfileString("valid__valid", "foobar");

        TuneAnalyticsVariable var = profile.getProfileVariable("valid__valid");
        assertTrue(var != null);
        assertTrue("valid__valid".equalsIgnoreCase(var.getName()));
        assertTrue("foobar".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        TuneTestWrapper.getInstance().clearCustomProfileVariable("$$#$&^");
        TuneTestWrapper.getInstance().clearCustomProfileVariable("valid_$#$_valid");

        var = profile.getCustomProfileVariable("valid__valid");
        assertNull(var);

        assertTrue(clearCalledCount == 1);
    }

    @Test
    public void testAllowCustomVariableValuesToBeSetRegardlessOfNameCase() {
        TuneTestWrapper.getInstance().registerCustomProfileString("Cat", "Tabby");
        TuneTestWrapper.getInstance().registerCustomProfileString("cat", "Siamese");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("Cat");
        TuneAnalyticsVariable var2 = profile.getCustomProfileVariable("cat");

        TuneTestWrapper.getInstance().setCustomProfileStringValue("Cat", "Mink");
        TuneTestWrapper.getInstance().setCustomProfileStringValue("cat", "Burmese");

        TuneAnalyticsVariable var3 = profile.getCustomProfileVariable("Cat");
        TuneAnalyticsVariable var4 = profile.getCustomProfileVariable("cat");

        assertEquals("Cat", var.getName());
        assertEquals("Tabby", var.getValue());
        assertEquals("cat", var2.getName());
        assertEquals("Siamese", var2.getValue());

        assertEquals("Cat", var3.getName());
        assertEquals("Mink", var3.getValue());
        assertEquals("cat", var4.getName());
        assertEquals("Burmese", var4.getValue());
    }

    @Test
    public void testClearCustomProfile() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString", "defaultString");
        TuneTestWrapper.getInstance().registerCustomProfileString("testString2", "defaultString2");
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable("google_aid", "99111")));

        TuneAnalyticsVariable var = profile.getProfileVariable("testString");
        assertTrue(var != null);
        assertTrue("testString".equalsIgnoreCase(var.getName()));
        assertTrue("defaultString".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        var = profile.getProfileVariable("testString2");
        assertTrue(var != null);
        assertTrue("testString2".equalsIgnoreCase(var.getName()));
        assertTrue("defaultString2".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        var = profile.getProfileVariable("google_aid");
        assertTrue(var != null);
        assertTrue("google_aid".equalsIgnoreCase(var.getName()));
        assertTrue("99111".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        // Remove a valid custom variable, an unregistered variable, and a non-custom variable.
        TuneTestWrapper.getInstance().clearAllCustomProfileVariables();

        var = profile.getCustomProfileVariable("testString");
        assertNull(var);

        var = profile.getCustomProfileVariable("testString2");
        assertNull(var);

        var = profile.getProfileVariable("google_aid");
        assertNotNull(var);

        assertTrue(clearCalledCount == 1);
    }

    public boolean checkJSON(JSONArray json, String name, String value) throws JSONException {
        for (int i = 0; i < json.length(); i++) {
            TuneAnalyticsVariable var = TuneAnalyticsVariable.fromJson(json.get(i).toString());
            if (var.getName().equalsIgnoreCase(name) &&
                    ((var.getValue() == null && var.getValue() == value) || (var.getValue() != null && var.getValue().equalsIgnoreCase(value)))) {
                return true;
            }
        }
        return false;
    }

    @Test
    public void testToJson() throws JSONException {
        TuneTestWrapper.getInstance().registerCustomProfileString("in1", "foobar");
        TuneTestWrapper.getInstance().registerCustomProfileString("in2", null);
        TuneTestWrapper.getInstance().registerCustomProfileString("in3");

        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable("profileVar1", "not_empty")));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable("profileVar2", "")));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable("profileVar3", (String) null)));
        JSONArray output = profile.toJson();

        assertTrue(checkJSON(output, "in1", "foobar"));
        assertTrue(checkJSON(output, "in2", null));
        assertTrue(checkJSON(output, "in3", null));

        assertTrue(checkJSON(output, "profileVar1", "not_empty"));
        assertTrue(checkJSON(output, "profileVar2", ""));
        assertTrue(checkJSON(output, "profileVar3", null));
    }

    @Test
    public void testReRegisterCustomVariablesNotSet() {
        TuneTestWrapper.getInstance().registerCustomProfileString("my_name");

        assertNull(TuneTestWrapper.getInstance().getCustomProfileString("my_name"));

        TuneManager.destroy();
        TuneManager.init(getContext(), TuneTestWrapper.getTestingConfig(Arrays.asList("")));

        TuneTestWrapper.getInstance().registerCustomProfileString("my_name", "has default now");

        assertEquals("has default now", TuneTestWrapper.getInstance().getCustomProfileString("my_name"));
    }

    @Test
    public void testReRegisterCustomVariablesSet() {
        TuneTestWrapper.getInstance().registerCustomProfileString("my_name");

        assertNull(TuneTestWrapper.getInstance().getCustomProfileString("my_name"));

        TuneTestWrapper.getInstance().setCustomProfileStringValue("my_name", "new value");

        TuneManager.destroy();
        TuneManager.init(getContext(), TuneTestWrapper.getTestingConfig(Arrays.asList("")));

        TuneTestWrapper.getInstance().registerCustomProfileString("my_name", "has default now");

        assertEquals("new value", TuneTestWrapper.getInstance().getCustomProfileString("my_name"));
    }

    @Test
    public void testUserEmailNotStored() {
        TuneTestWrapper.getInstance().setUserEmail("test_email");

        sleep( TuneTestConstants.PARAMTEST_SLEEP );

        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_EMAIL_MD5));
        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_EMAIL_SHA1));
        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_EMAIL_SHA256));
    }

    @Test
    public void testUserNameNotStored() {
        TuneTestWrapper.getInstance().setUserName("test_username");

        sleep( TuneTestConstants.PARAMTEST_SLEEP );

        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_NAME_MD5));
        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_NAME_SHA1));
        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_NAME_SHA256));
    }

    @Test
    public void testPhoneNumberNotStored() {
        TuneTestWrapper.getInstance().setPhoneNumber("test_phone_number");

        sleep( TuneTestConstants.PARAMTEST_SLEEP );

        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_PHONE_MD5));
        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_PHONE_SHA1));
        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_PHONE_SHA256));
    }

    @Test
    public void testCustomProfileVariablesPersistBetweenSessions() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString", "defaultStringValue");

        sleep( TuneTestConstants.PARAMTEST_SLEEP );

        // Trigger a save of the custom variable names
        TuneEventBus.post(new TuneAppBackgrounded());

        sleep( TuneTestConstants.SERVERTEST_SLEEP );

        // Re-init TuneManager and TuneUserProfile, to simulate app getting killed and started
        TuneManager.destroy();
        // The eventbus always starts out enabled then becomes disabled
        TuneEventBus.enable();
        TuneManager.init(getContext(), TuneTestWrapper.getTestingConfig(Arrays.asList("configuration_enabled.json")));

        TuneEventBus.post(new TuneAppForegrounded("123", 0L));

        // Check that custom profile variable is repopulated after app foreground
        assertEquals("defaultStringValue", profile.getCustomProfileVariable("testString").getValue());
    }

    @Test
    public void testBooleanValuesSetCorrectly() {
        // Test setExistingUser sends "1" when set to true
        TuneTestWrapper.getInstance().setExistingUser(true);
        sleep( TuneTestConstants.PARAMTEST_SLEEP );

        assertEquals("1", profile.getProfileVariableValue(TuneUrlKeys.EXISTING_USER));


        // Test setIsPayingUser sends "1" when set to true
        TuneTestWrapper.getInstance().setIsPayingUser(true);
        sleep( TuneTestConstants.PARAMTEST_SLEEP );

        assertEquals("1", profile.getProfileVariableValue(TuneUrlKeys.IS_PAYING_USER));
    }

    // Test a smattering of different cases directly against the system keys
    @Test
    public void testIsSystemVariable() {
        assertTrue(TuneProfileKeys.isSystemVariable(TuneProfileKeys.SESSION_ID.toUpperCase(Locale.ENGLISH)));
        assertTrue(TuneProfileKeys.isSystemVariable(TuneProfileKeys.SCREEN_HEIGHT.toUpperCase(Locale.ENGLISH)));

        assertTrue(TuneProfileKeys.isSystemVariable(TuneUrlKeys.PUBLISHER_ID.toUpperCase(Locale.ENGLISH)));
        assertTrue(TuneProfileKeys.isSystemVariable(TuneUrlKeys.REFERRAL_URL.toUpperCase(Locale.ENGLISH)));
    }

    @Test
    public void testRedactedProfileKeys() {
        Set<String> setA = TuneProfileKeys.getAllProfileKeys();
        assertTrue(setA.contains(TuneProfileKeys.SESSION_ID));
        assertTrue(setA.contains(TuneProfileKeys.SCREEN_HEIGHT));

        setA.removeAll(TuneProfileKeys.getRedactedProfileKeys());

        assertTrue(setA.contains(TuneProfileKeys.SESSION_ID));
        assertFalse(setA.contains(TuneProfileKeys.SCREEN_HEIGHT));  // Should be redacted
    }

    @Test
    public void testRedactedURLKeys() {
        Set<String> setA = TuneUrlKeys.getAllUrlKeys();
        assertTrue(setA.contains(TuneUrlKeys.PUBLISHER_ID));
        assertTrue(setA.contains(TuneUrlKeys.REFERRAL_URL));

        setA.removeAll(TuneUrlKeys.getRedactedUrlKeys());

        assertTrue(setA.contains(TuneUrlKeys.PUBLISHER_ID));
        assertFalse(setA.contains(TuneUrlKeys.REFERRAL_URL));  // Should be redacted
    }

    /**
     * This test checks COPPA Redaction when using {@link com.tune.Tune#setAge(int)}
     * This test uses SCREEN_WIDTH as it is one that should be redacted.
     */
    @Test
    public void testIsCOPPA_RedactedOnAge() {
        ProfileChangedReceiver receiver = new ProfileChangedReceiver(TuneUrlKeys.IS_COPPA);
        TuneEventBus.register(receiver);

        boolean found = false;
        List<TuneAnalyticsVariable> profile = TuneManager.getInstance().getProfileManager().getCopyOfNonRedactedVars(TuneParameters.getRedactedKeys());
        for (TuneAnalyticsVariable variable : profile) {
            if (variable.getName().equals(TuneProfileKeys.SCREEN_WIDTH)) {
                found = true;
                break;
            }
        }
        assertTrue(found);

        // COPPA should not be set, and should not exist yet
        assertNull(getCOPPAValueFromProfileList(profile));

        // Now get the Keys when COPPA is true
        tune.setAge(TuneConstants.COPPA_MINIMUM_AGE - 1);

        receiver.doWait(TuneTestConstants.PARAMTEST_SLEEP);
        profile = TuneManager.getInstance().getProfileManager().getCopyOfNonRedactedVars(TuneParameters.getRedactedKeys());
        for (TuneAnalyticsVariable variable : profile) {
            assertFalse(variable.getName().equals(TuneProfileKeys.SCREEN_WIDTH));
        }

        // COPPA should be set now
        assertEquals(TuneConstants.PREF_SET, getCOPPAValueFromProfileList(profile));

        // remove the COPPA privacy restriction and test unset
        tune.setAge(TuneConstants.COPPA_MINIMUM_AGE + 1);
        receiver.doWait(TuneTestConstants.PARAMTEST_SLEEP);
        profile = TuneManager.getInstance().getProfileManager().getCopyOfNonRedactedVars(TuneParameters.getRedactedKeys());
        assertEquals(TuneConstants.PREF_UNSET, getCOPPAValueFromProfileList(profile));

        TuneEventBus.unregister(receiver);
    }

    /**
     * This test checks COPPA Redaction when using {@link com.tune.Tune#setPrivacyProtectedDueToAge(boolean)}
     * This test uses SCREEN_WIDTH as it is one that should be redacted.
     */
    @Test
    public void testIsCOPPA_RedactedOnPrivacyProtected() {
        ProfileChangedReceiver receiver = new ProfileChangedReceiver(TuneUrlKeys.IS_COPPA);
        TuneEventBus.register(receiver);

        boolean found = false;
        List<TuneAnalyticsVariable> profile = TuneManager.getInstance().getProfileManager().getCopyOfNonRedactedVars(TuneParameters.getRedactedKeys());
        for (TuneAnalyticsVariable variable : profile) {
            if (variable.getName().equals(TuneProfileKeys.SCREEN_WIDTH)) {
                found = true;
                break;
            }
        }
        assertTrue(found);

        // COPPA should not be set, and should not exist yet
        assertNull(getCOPPAValueFromProfileList(profile));

        // Now get the Keys when COPPA is true
        tune.setPrivacyProtectedDueToAge(true);

        receiver.doWait(TuneTestConstants.PARAMTEST_SLEEP);
        profile = TuneManager.getInstance().getProfileManager().getCopyOfNonRedactedVars(TuneParameters.getRedactedKeys());
        for (TuneAnalyticsVariable variable : profile) {
            assertFalse(variable.getName().equals(TuneProfileKeys.SCREEN_WIDTH));
        }

        // COPPA should be set now
        assertEquals(TuneConstants.PREF_SET, getCOPPAValueFromProfileList(profile));

        // remove the COPPA privacy restriction and test unset
        tune.setPrivacyProtectedDueToAge(false);
        receiver.doWait(TuneTestConstants.PARAMTEST_SLEEP);
        profile = TuneManager.getInstance().getProfileManager().getCopyOfNonRedactedVars(TuneParameters.getRedactedKeys());
        assertEquals(TuneConstants.PREF_UNSET, getCOPPAValueFromProfileList(profile));

        TuneEventBus.unregister(receiver);
    }

    private String getCOPPAValueFromProfileList(List<TuneAnalyticsVariable> profile) {
        String coppaFound = null;

        for (TuneAnalyticsVariable variable : profile) {
            if (variable.getName().equals(TuneUrlKeys.IS_COPPA)) {
                coppaFound = variable.getValue();
                break;
            }
        }

        return coppaFound;
    }

    /**
     * Helper class to wait for UserProfile keys to show up
     */
    class ProfileChangedReceiver {
        private String mProfileKey;
        private Object mWaitObject;

        public ProfileChangedReceiver(String profileKey) {
            mProfileKey = profileKey;
            mWaitObject = new Object();
        }

        @Subscribe
        public void onEvent(TuneUpdateUserProfile event) {
            // Notify when the key comes in
            if (event.getVariable().getName().equals(mProfileKey)) {
                synchronized (mWaitObject) {
                    mWaitObject.notify();
                }
            }
        }

        public final void doWait(long millis) {
            synchronized (mWaitObject) {
                try {
                    mWaitObject.wait(millis);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    }

}
