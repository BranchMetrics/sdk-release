package com.tune.ma.eventbus.event;

/**
 * Created by kristine on 2/8/16.
 */
public class TuneSessionVariableToSet {

    public enum SaveTo { PROFILE, TAGS, BOTH }

    String variableName;
    String variableValue;
    SaveTo variableSaveType;

    public TuneSessionVariableToSet(String variableName, String variableValue, SaveTo variableSaveType) {
        this.variableName = variableName;
        this.variableValue = variableValue;
        this.variableSaveType = variableSaveType;
    }

    public String getVariableName() {
        return variableName;
    }

    public String getVariableValue() {
        return variableValue;
    }

    public boolean saveToProfile() {
        return variableSaveType == SaveTo.BOTH || variableSaveType == SaveTo.PROFILE;
    }

    public boolean saveToAnalyticsManager() {
        return variableSaveType == SaveTo.BOTH || variableSaveType == SaveTo.TAGS;
    }
}
