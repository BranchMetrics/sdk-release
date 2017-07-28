package com.tune.smartwhere;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;

/**
 * Tune SmartWhere Configuration for granting and revoking integration privileges.
 */
public class TuneSmartWhereConfiguration {
    /**
     * OPT-IN PERMISSION to enable SmartWhere Services.  This permission is required to be set
     * for any SmartWhere integration with Tune to be enabled.
     */
    public static final String GRANT_SMARTWHERE_OPT_IN = "com.tune.smartwhere.permission.OPT_IN";

    /**
     * PERMISSION to allow Tune to send events directly to SmartWhere by default.
     */
    public static final String GRANT_SMARTWHERE_TUNE_EVENTS = "com.tune.smartwhere.permission.TUNE_EVENTS";

    private Map<String, Boolean> mPermissions;

    /**
     * Constructor.
     */
    public TuneSmartWhereConfiguration() {
        mPermissions = new HashMap<>();
    }

    /**
     * Constructor.
     * @param configJson with permissions.  Typically used in conjunction with {@link TuneSmartWhereConfiguration#toString()}
     */
    public TuneSmartWhereConfiguration(String configJson) {
        mPermissions = new HashMap<>();

        try {
            JSONObject jsonObject = new JSONObject(configJson);

            if (jsonObject.has(GRANT_SMARTWHERE_OPT_IN)) {
                setPermission(GRANT_SMARTWHERE_OPT_IN, jsonObject.getBoolean(GRANT_SMARTWHERE_OPT_IN));
            }
            if (jsonObject.has(GRANT_SMARTWHERE_TUNE_EVENTS)) {
                setPermission(GRANT_SMARTWHERE_TUNE_EVENTS, jsonObject.getBoolean(GRANT_SMARTWHERE_TUNE_EVENTS));
            }
        } catch (JSONException e) {
            // TODO: Log Error
        }
    }

    /**
     * @return True if Opt-In has been granted for SmartWhere integration.
     * @see {@link TuneSmartWhereConfiguration#GRANT_SMARTWHERE_OPT_IN}
     */
    public boolean isSmartWhereEnabled() {
        Boolean test = mPermissions.get(GRANT_SMARTWHERE_OPT_IN);
        return (test == null ? false : (TuneSmartWhere.isSmartWhereAvailable() && test));
    }

    /**
     * Return the current configuration state for the given permisison.
     * @param permission Permission to check
     * @return True if the permission is granted, False otherwise
     */
    public boolean isPermissionGranted(String permission) {
        Boolean test = mPermissions.get(permission);
        return isSmartWhereEnabled() && (test == null ? false : test);
    }

    /**
     * Grant a permission for SmartWhere integration.
     * @param permission Permission to grant
     * @return This instance, which can be used for chaining configuration requests.
     */
    public TuneSmartWhereConfiguration grant(String permission) {
        if (isValidPermission(permission)) {
            mPermissions.put(permission, true);
        }

        return this;
    }

    /**
     * Grant all permissions for SmartWhere integration.
     * @return This instance, which can be used for chaining configuration requests.
     */
    public TuneSmartWhereConfiguration grantAll() {
        // **NOTE**  Any additional permissions added must be added here
        grant(GRANT_SMARTWHERE_OPT_IN);
        grant(GRANT_SMARTWHERE_TUNE_EVENTS);

        return this;
    }

    /**
     * Revoke a permission for SmartWhere integration.
     * @param permission Permission to revoke
     * @return This instance, which can be used for chaining configuration requests.
     */
    public TuneSmartWhereConfiguration revoke(String permission) {
        if (isValidPermission(permission)) {
            mPermissions.remove(permission);
        }

        return this;
    }

    /**
     * Revoke all permissions for SmartWhere integration.
     * @return This instance, which can be used for chaining configuration requests.
     */
    public TuneSmartWhereConfiguration revokeAll() {
        mPermissions.clear();
        return this;
    }

    private boolean isValidPermission(String permission) {
        return (permission != null && permission.length() > 0);
    }

    private void setPermission(String permission, boolean grant) {
        if (grant) {
            grant(permission);
        } else {
            revoke(permission);
        }
    }

    @Override
    public String toString() {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put(GRANT_SMARTWHERE_OPT_IN, isPermissionGranted(GRANT_SMARTWHERE_OPT_IN));
            jsonObject.put(GRANT_SMARTWHERE_TUNE_EVENTS, isPermissionGranted(GRANT_SMARTWHERE_TUNE_EVENTS));
        } catch (JSONException e) {
        }

        return jsonObject.toString();
    }


}
