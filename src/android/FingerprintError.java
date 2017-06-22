package com.cordova.plugin.android.fingerprintauth;


import android.util.Log;

import org.apache.cordova.LOG;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by enrico on 21/06/17.
 */


public enum FingerprintError {

    FingerprintNotAvailable("-1","Fingerprint is not available on this device"),
    FingerprintAvailableButNotEnrolled("-2","Fingerprint is available but not enrolled"),
    FingerprintGenericError("-3","An error has occued"),
    FingerprintSecretKeyNotFound("-7","Key not found"),
    FingerprintCancelledByUser("-8","canceled by user"),
    FingerprintLockedOut("-10","Fingerprint is locked out"),
    FingerprintSaveIllegalBlockSize("-4", "Unable to save value"),
    FingerprintInvalidateKey("-15", "Key has been invalidated");


    private String errorCode;
    private String errorMessage;
    FingerprintError(String errorCode,String errorMessage){
        this.errorCode=errorCode;
        this.errorMessage= errorMessage;
    }

    public JSONObject toJSON() {
        JSONObject resultJson = new JSONObject();
        try {
            //resultJson.put(OS, ANDROID);
            resultJson.put("errorCode", errorCode);
            resultJson.put("errorMessage", errorMessage);
            return resultJson;
        } catch (JSONException e) {
            LOG.e("FingerprintError", e.getMessage(),e);
        }
        return resultJson;
    }
}
