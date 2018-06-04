package com.tune.ma.analytics.model;

import android.text.TextUtils;

import com.tune.TuneConstants;
import com.tune.TuneDebugLog;
import com.tune.TuneLocation;
import com.tune.TuneUtils;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.constants.TuneHashType;
import com.tune.ma.analytics.model.constants.TuneVariableType;
import com.tune.ma.utils.TuneJsonUtils;
import com.tune.ma.utils.TunePIIUtils;
import com.tune.ma.utils.TuneStringUtils;

import org.json.JSONException;
import org.json.JSONObject;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.TimeZone;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Deprecated
public class TuneAnalyticsVariable {
    public static final String IOS_BOOLEAN_TRUE = "YES";
    public static final String IOS_BOOLEAN_FALSE = "NO";

    public static final String NAME = "name";
    public static final String VALUE = "value";
    public static final String TYPE = "type";
    public static final String HASH = "hash";
    public static final String SHOULD_AUTO_HASH = "shouldAutoHash";
    public static final String DID_HAVE_VALUE_MANUALLY_SET = "didHaveValueManuallySet";

    private String name;
    private String value;
    private TuneVariableType type;
    private TuneHashType hashType;
    private boolean shouldAutoHash;
    private boolean didHaveValueManuallySet;

    private TuneAnalyticsVariable() {}

    public TuneAnalyticsVariable(String name, String value) {
        this(name, value, TuneVariableType.STRING);
    }

    public TuneAnalyticsVariable(String name, boolean value) {
        this(name, value ? TuneConstants.PREF_SET : TuneConstants.PREF_UNSET, TuneVariableType.BOOLEAN);
    }

    public TuneAnalyticsVariable(String name, int value) {
        this(name, Integer.toString(value), TuneVariableType.FLOAT);
    }

    public TuneAnalyticsVariable(String name, double value) {
        this(name, Double.toString(value), TuneVariableType.FLOAT);
    }

    public TuneAnalyticsVariable(String name, float value) {
        this(name, Float.toString(value), TuneVariableType.FLOAT);
    }

    public TuneAnalyticsVariable(String name, Date value) {
        this(name, dateToString(value), TuneVariableType.DATETIME);
    }

    public TuneAnalyticsVariable(String name, TuneLocation value) {
        this(name, geolocationToString(value), TuneVariableType.GEOLOCATION);
    }

    public TuneAnalyticsVariable(String name, String value, TuneVariableType type) {
        this(name, value, type, TuneHashType.NONE, false);
    }

    public TuneAnalyticsVariable(String name, String value, TuneVariableType type, TuneHashType hashType, boolean shouldAutohash) {
        this.name = name;
        this.value = value;
        this.type = type;
        this.hashType = hashType;
        this.shouldAutoHash = shouldAutohash;
        this.didHaveValueManuallySet = false;
    }

    public TuneAnalyticsVariable(TuneAnalyticsVariable var) {
        this.name = var.getName();
        this.value = var.getValue();
        this.type = var.getType();
        this.hashType = var.getHashType();
        this.shouldAutoHash = var.getShouldAutoHash();
    }

    public String getName() {
        return name;
    }

    public String getValue() {
        return value;
    }

    public TuneVariableType getType() {
        return type;
    }

    public TuneHashType getHashType() {
        return hashType;
    }


    public boolean didHaveValueManuallySet() {
        return didHaveValueManuallySet;
    }

    public List<JSONObject> toListOfJsonObjectsForDispatch() {
        List<JSONObject> arrayOfJsonVariables = new ArrayList<JSONObject>();
        boolean hasPII = TunePIIUtils.check(value, TuneManager.getInstance().getConfigurationManager().getPIIFiltersAsPatterns());
        if (shouldAutoHash || hasPII) {
            arrayOfJsonVariables.add(toJsonWithHashType(TuneHashType.MD5, false));
            arrayOfJsonVariables.add(toJsonWithHashType(TuneHashType.SHA1, false));
            arrayOfJsonVariables.add(toJsonWithHashType(TuneHashType.SHA256, false));
        } else {
            arrayOfJsonVariables.add(toJsonWithHashType(TuneHashType.NONE, false));
        }
        return arrayOfJsonVariables;
    }

    public boolean getShouldAutoHash() {
        return shouldAutoHash;
    }

    public JSONObject toJsonForLocalStorage() {
        return toJsonWithHashType(TuneHashType.NONE, true);
    }

    private JSONObject toJsonWithHashType(TuneHashType hashWith, boolean forLocalStorage) {
        JSONObject object = new JSONObject();
        try {
            object.put(NAME, name);

            // If the value is null we always store it as a null regardless of hash type
            if (value == null) {
                object.put(VALUE, JSONObject.NULL);
            } else if (hashWith == TuneHashType.NONE) {
                object.put(VALUE, value);
            } else if (hashWith == TuneHashType.MD5) {
                object.put(VALUE, TuneUtils.md5(value));
            } else if (hashWith == TuneHashType.SHA1) {
                object.put(VALUE, TuneUtils.sha1(value));
            } else if (hashWith == TuneHashType.SHA256) {
                object.put(VALUE, TuneUtils.sha256(value));
            }

            object.put(TYPE, type.toString().toLowerCase(Locale.ENGLISH));

            if (forLocalStorage) {
                if (hashType != TuneHashType.NONE) {
                    object.put(HASH, hashType.toString().toLowerCase(Locale.ENGLISH));
                }
                object.put(SHOULD_AUTO_HASH, shouldAutoHash);
                object.put(DID_HAVE_VALUE_MANUALLY_SET, didHaveValueManuallySet);
            } else {
                if (hashWith != TuneHashType.NONE) {
                    object.put(HASH, hashWith.toString().toLowerCase(Locale.ENGLISH));
                }
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return object;
    }

    /**
     * Instantiates a TuneAnalyticsVariable object from JSON representation
     * @param json JSON representation of an analytics variable
     * @return TuneAnalyticsVariable deserialized from JSON
     */
    public static TuneAnalyticsVariable fromJson(String json) {
        TuneAnalyticsVariable var = null;
        try {
            JSONObject object = new JSONObject(json);

            String name = TuneJsonUtils.getString(object, NAME);

            String value = null;
            if (!object.isNull(VALUE)) {
                value = TuneJsonUtils.getString(object, VALUE);
            }

            TuneVariableType type = TuneVariableType.valueOf(TuneJsonUtils.getString(object, TYPE).toUpperCase(Locale.ENGLISH));

            TuneHashType hash = TuneHashType.NONE;
            if (object.has(HASH)) {
                hash = TuneHashType.valueOf(TuneJsonUtils.getString(object, HASH).toUpperCase(Locale.ENGLISH));
            }

            var = new TuneAnalyticsVariable();
            var.name = name;
            var.value = value;
            var.type = type;
            var.hashType = hash;
            var.shouldAutoHash = object.optBoolean(SHOULD_AUTO_HASH, false);
            var.didHaveValueManuallySet = object.getBoolean(DID_HAVE_VALUE_MANUALLY_SET);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return var;
    }

    /**
     * Validates that an analytics variable name is alphanumeric
     * @param name Analytics variable name
     * @return Whether name is valid to send to the pipeline
     */
    public static boolean validateName(String name) {
        if (TextUtils.isEmpty(name)) {
            TuneDebugLog.IAMConfigError("Attempted to use a variable with name of null or empty string.");
            return false;
        }

        String prettyName = cleanVariableName(name);
        if (!name.equals(prettyName)) {
            TuneDebugLog.IAMConfigError("Variable name " + name + " had special characters and was automatically changed to " + prettyName);
        }
        if (prettyName.isEmpty()) {
            TuneDebugLog.IAMConfigError("Cannot set variable with name " + name + ", characters exclusively not in [a-zA-Z0-9_-].");
            return false;
        }
        return true;
    }

    /**
     * Strips non-alphanumeric, underscore or hyphen characters
     * @param name Analytics variable name
     * @return Analytics variable name with non-valid characters removed
     */
    public static String cleanVariableName(String name) {
        if (name == null) {
            return null;
        }
        // Strip non-alphanumeric, underscore or hyphen characters from name
        name = name.replaceAll("[^a-zA-Z0-9_\\-]", "");
        return name;
    }

    /**
     * Validates than an analytics variable is an accepted version format
     * @param version Analytics variable version value
     * @return Whether version value is valid to send to the pipeline
     */
    public static boolean validateVersion(String version) {
        if (TextUtils.isEmpty(version)) {
            return true;
        }

        Pattern versionPattern = Pattern.compile("^(0|[1-9]\\d*)(\\.(0|[1-9]\\d*)){0,2}(\\-.*)?$");
        Matcher matcher = versionPattern.matcher(version);
        return matcher.matches();
    }

    public static String dateToString(Date date) {
        if (date == null) {
            return null;
        }

        SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZZ", Locale.US);
        TimeZone tz = TimeZone.getTimeZone("UTC");
        df.setTimeZone(tz);
        String dateString = df.format(date).replaceAll("\\+0000", "Z");
        return dateString;
    }

    public static Date stringToDate(String s) {
        if (s == null) {
            return null;
        }

        SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US);
        TimeZone tz = TimeZone.getTimeZone("UTC");
        df.setTimeZone(tz);
        Date d = null;
        try {
            d = df.parse(s);
        } catch (ParseException e) {
            e.printStackTrace();
        }
        return d;
    }

    public static String geolocationToString(TuneLocation loc) {
        if (loc == null) {
            return null;
        }
        return TuneStringUtils.format("%.9f,%.9f", loc.getLongitude(), loc.getLatitude());
    }

    public static TuneLocation stringToGeolocation(String s) {
        if (s == null) {
            return null;
        }
        String[] foo = TextUtils.split(s, ",");
        if (foo.length == 2) {
            return new TuneLocation(Double.valueOf(foo[0]), Double.valueOf(foo[1]));
        } else {
            return null;
        }
    }

    public static TuneAnalyticsVariableBuilder Builder(String variableName) {
        return new TuneAnalyticsVariableBuilder(variableName);
    }

    /**
     * Created by charlesgilliam on 1/26/16.
     * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
     */
    @Deprecated
    public static class TuneAnalyticsVariableBuilder {
        private String name;
        private String value;
        private TuneVariableType type;
        private TuneHashType hashType;
        private boolean shouldAutoHash;
        private boolean didHaveValueManuallySet;

        private boolean manuallySetType = false;

        public TuneAnalyticsVariableBuilder(String name) {
            this.name = name;

            // Default Options
            this.value = null;
            this.type = TuneVariableType.STRING;
            this.hashType = TuneHashType.NONE;
            this.shouldAutoHash = false;
            this.didHaveValueManuallySet = false;
        }

        public TuneAnalyticsVariableBuilder withNullValue() {
            this.value = null;
            return this;
        }

        public TuneAnalyticsVariableBuilder withValue(String value) {
            this.value = value;
            return this;
        }

        public TuneAnalyticsVariableBuilder withValue(boolean value) {
            if (value) {
                this.value = "1";
            } else {
                this.value = "0";
            }
            if (!manuallySetType) {
                type = TuneVariableType.BOOLEAN;
            }
            return this;
        }

        public TuneAnalyticsVariableBuilder withValue(int value) {
            this.value = Integer.toString(value);
            if (!manuallySetType) {
                this.type = TuneVariableType.FLOAT;
            }
            return this;
        }

        public TuneAnalyticsVariableBuilder withValue(double value) {
            this.value = Double.toString(value);
            if (!manuallySetType) {
                this.type = TuneVariableType.FLOAT;
            }
            return this;
        }

        public TuneAnalyticsVariableBuilder withValue(float value) {
            this.value = Float.toString(value);
            if (!manuallySetType) {
                this.type = TuneVariableType.FLOAT;
            }
            return this;
        }

        public TuneAnalyticsVariableBuilder withValue(Date value) {
            this.value = dateToString(value);
            if (!manuallySetType) {
                this.type = TuneVariableType.DATETIME;
            }
            return this;
        }

        public TuneAnalyticsVariableBuilder withValue(TuneLocation value) {
            this.value = geolocationToString(value);
            if (!manuallySetType) {
                this.type = TuneVariableType.GEOLOCATION;
            }
            return this;
        }

        public TuneAnalyticsVariableBuilder withType(TuneVariableType type) {
            this.type = type;
            manuallySetType = true;
            return this;
        }

        public TuneAnalyticsVariableBuilder withHash(TuneHashType hash) {
            this.hashType = hash;
            return this;
        }

        public TuneAnalyticsVariableBuilder withShouldAutoHash(boolean shouldAutoHash) {
            this.shouldAutoHash = shouldAutoHash;
            return this;
        }

        public TuneAnalyticsVariableBuilder withValueManuallySet(boolean didHaveValueManuallySet) {
            this.didHaveValueManuallySet = didHaveValueManuallySet;
            return this;
        }

        public TuneAnalyticsVariable build() {
            TuneAnalyticsVariable var = new TuneAnalyticsVariable();
            var.name = name;
            var.value = value;
            var.type = type;
            var.hashType = hashType;
            var.shouldAutoHash = shouldAutoHash;
            var.didHaveValueManuallySet = didHaveValueManuallySet;
            return var;
        }

    }
}
