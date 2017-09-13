package com.tune.ma.utils;

import com.tune.TuneUnitTest;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.constants.TuneHashType;
import com.tune.ma.analytics.model.constants.TuneVariableType;
import com.tune.ma.configuration.TuneConfiguration;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Created by kristine on 2/5/16.
 */
public class TunePIIUtilsTests extends TuneUnitTest {

    @Override
    protected void setUp() throws Exception {
        super.setUp();
        List<String> piiFilters = new ArrayList<String>();
        piiFilters.add("^[1-9][0-9]{5,50}$");
        piiFilters.add("^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$");

        TuneConfiguration config = new TuneConfiguration();
        config.setPIIFiltersAsStrings(piiFilters);
        TuneManager.getInstance().getConfigurationManager().updateConfigurationFromTuneConfigurationObject(config);
    }

    @Override
    protected void tearDown() throws Exception {
        super.tearDown();
    }

    public void testPIIFilterWithValueNumbersAsString() {
        TuneAnalyticsVariable variable = new TuneAnalyticsVariable("foobar", "123456789");
        List<JSONObject> converted = variable.toListOfJsonObjectsForDispatch();
        JSONObject md5expected = new JSONObject();
        JSONObject sha1expected = new JSONObject();
        JSONObject sha256expected = new JSONObject();
        try {
            md5expected.put(TuneAnalyticsVariable.NAME, "foobar");
            md5expected.put(TuneAnalyticsVariable.VALUE, "25f9e794323b453885f5181f1b624d0b");
            md5expected.put(TuneAnalyticsVariable.TYPE, TuneVariableType.STRING.toString().toLowerCase(Locale.ENGLISH));
            md5expected.put(TuneAnalyticsVariable.HASH, TuneHashType.MD5.toString().toLowerCase(Locale.ENGLISH));

            assertEquals(md5expected.toString(), converted.get(0).toString());

            sha1expected.put(TuneAnalyticsVariable.NAME, "foobar");
            sha1expected.put(TuneAnalyticsVariable.VALUE, "f7c3bc1d808e04732adf679965ccc34ca7ae3441");
            sha1expected.put(TuneAnalyticsVariable.TYPE, TuneVariableType.STRING.toString().toLowerCase(Locale.ENGLISH));
            sha1expected.put(TuneAnalyticsVariable.HASH, TuneHashType.SHA1.toString().toLowerCase(Locale.ENGLISH));

            assertEquals(sha1expected.toString(), converted.get(1).toString());

            sha256expected.put(TuneAnalyticsVariable.NAME, "foobar");
            sha256expected.put(TuneAnalyticsVariable.VALUE, "15e2b0d3c33891ebb0f1ef609ec419420c20e320ce94c65fbc8c3312448eb225");
            sha256expected.put(TuneAnalyticsVariable.TYPE, TuneVariableType.STRING.toString().toLowerCase(Locale.ENGLISH));
            sha256expected.put(TuneAnalyticsVariable.HASH, TuneHashType.SHA256.toString().toLowerCase(Locale.ENGLISH));

            assertEquals(sha256expected.toString(), converted.get(2).toString());

        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void testPIIFilterWithValueFloat() {
        TuneAnalyticsVariable variable = new TuneAnalyticsVariable("foobar", 123456789);
        List<JSONObject> converted = variable.toListOfJsonObjectsForDispatch();
        JSONObject md5expected = new JSONObject();
        JSONObject sha1expected = new JSONObject();
        JSONObject sha256expected = new JSONObject();
        try {
            md5expected.put(TuneAnalyticsVariable.NAME, "foobar");
            md5expected.put(TuneAnalyticsVariable.VALUE, "25f9e794323b453885f5181f1b624d0b");
            md5expected.put(TuneAnalyticsVariable.TYPE, TuneVariableType.FLOAT.toString().toLowerCase(Locale.ENGLISH));
            md5expected.put(TuneAnalyticsVariable.HASH, TuneHashType.MD5.toString().toLowerCase(Locale.ENGLISH));

            assertEquals(md5expected.toString(), converted.get(0).toString());

            sha1expected.put(TuneAnalyticsVariable.NAME, "foobar");
            sha1expected.put(TuneAnalyticsVariable.VALUE, "f7c3bc1d808e04732adf679965ccc34ca7ae3441");
            sha1expected.put(TuneAnalyticsVariable.TYPE, TuneVariableType.FLOAT.toString().toLowerCase(Locale.ENGLISH));
            sha1expected.put(TuneAnalyticsVariable.HASH, TuneHashType.SHA1.toString().toLowerCase(Locale.ENGLISH));

            assertEquals(sha1expected.toString(), converted.get(1).toString());

            sha256expected.put(TuneAnalyticsVariable.NAME, "foobar");
            sha256expected.put(TuneAnalyticsVariable.VALUE, "15e2b0d3c33891ebb0f1ef609ec419420c20e320ce94c65fbc8c3312448eb225");
            sha256expected.put(TuneAnalyticsVariable.TYPE, TuneVariableType.FLOAT.toString().toLowerCase(Locale.ENGLISH));
            sha256expected.put(TuneAnalyticsVariable.HASH, TuneHashType.SHA256.toString().toLowerCase(Locale.ENGLISH));

            assertEquals(sha256expected.toString(), converted.get(2).toString());

        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void testPIIFilterWithValueEmail() {
        TuneAnalyticsVariable variable = new TuneAnalyticsVariable("foobar", "jim@tune.com");
        List<JSONObject> converted = variable.toListOfJsonObjectsForDispatch();
        JSONObject md5expected = new JSONObject();
        JSONObject sha1expected = new JSONObject();
        JSONObject sha256expected = new JSONObject();
        try {
            md5expected.put(TuneAnalyticsVariable.NAME, "foobar");
            md5expected.put(TuneAnalyticsVariable.VALUE, "bb128b6d08dcaf039590d759e16422a8");
            md5expected.put(TuneAnalyticsVariable.TYPE, TuneVariableType.STRING.toString().toLowerCase(Locale.ENGLISH));
            md5expected.put(TuneAnalyticsVariable.HASH, TuneHashType.MD5.toString().toLowerCase(Locale.ENGLISH));

            assertEquals(md5expected.toString(), converted.get(0).toString());

            sha1expected.put(TuneAnalyticsVariable.NAME, "foobar");
            sha1expected.put(TuneAnalyticsVariable.VALUE, "8fb1db891bea45aab362b50560677461b74a6bb5");
            sha1expected.put(TuneAnalyticsVariable.TYPE, TuneVariableType.STRING.toString().toLowerCase(Locale.ENGLISH));
            sha1expected.put(TuneAnalyticsVariable.HASH, TuneHashType.SHA1.toString().toLowerCase(Locale.ENGLISH));

            assertEquals(sha1expected.toString(), converted.get(1).toString());

            sha256expected.put(TuneAnalyticsVariable.NAME, "foobar");
            sha256expected.put(TuneAnalyticsVariable.VALUE, "6c74f7487195814eaabde0b45566f69a517223d9b404470085828bc2f74602c9");
            sha256expected.put(TuneAnalyticsVariable.TYPE, TuneVariableType.STRING.toString().toLowerCase(Locale.ENGLISH));
            sha256expected.put(TuneAnalyticsVariable.HASH, TuneHashType.SHA256.toString().toLowerCase(Locale.ENGLISH));

            assertEquals(sha256expected.toString(), converted.get(2).toString());

        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void testPIIFilterWithNoPII() {
        TuneAnalyticsVariable variable = new TuneAnalyticsVariable("foobar", "No PII Here");
        List<JSONObject> converted = variable.toListOfJsonObjectsForDispatch();
        JSONObject expected = new JSONObject();
        assertEquals(1, converted.size());
        try {
            expected.put(TuneAnalyticsVariable.NAME, "foobar");
            expected.put(TuneAnalyticsVariable.VALUE, "No PII Here");
            expected.put(TuneAnalyticsVariable.TYPE, TuneVariableType.STRING.toString().toLowerCase(Locale.ENGLISH));

            assertEquals(expected.toString(), converted.get(0).toString());
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void testPIIFilterOnNull() {
        String nullString = null;
        TuneAnalyticsVariable variable = new TuneAnalyticsVariable("foobar", nullString);
        List<JSONObject> converted = variable.toListOfJsonObjectsForDispatch();
        JSONObject expected = new JSONObject();
        assertEquals(1, converted.size());
        try {
            expected.put(TuneAnalyticsVariable.NAME, "foobar");
            expected.put(TuneAnalyticsVariable.VALUE, JSONObject.NULL);
            expected.put(TuneAnalyticsVariable.TYPE, TuneVariableType.STRING.toString().toLowerCase(Locale.ENGLISH));

            assertEquals(expected.toString(), converted.get(0).toString());
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

}
