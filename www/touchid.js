var argscheck = require('cordova/argscheck'),
               exec = require('cordova/exec');

/**
* @namespace window.plugins
*/

/**
* @exports touchid
*/

var touchid = {

  ErrorCodes : {
    BIOMETRIC_NOT_AVAILBALE : "-1",
    BIOMETRIC_NOT_ENROLLED : "-2",
    GENERIC_ERROR : "-3",
    VALUE_COULD_NOT_BE_SAVED  : "-5",
    VALUE_COULD_NOT_BE_DELETED : "-6",
    KEY_NOT_FOUND : "-7",
    USER_CANCELED : "-8",
    AUTHENTICATION_FAILED : "-9",
    BIOMETRIC_LOCKED_OUT : "-10",
    USER_FALLBACK  : "-20"
  },

  /**
   * @typedef module:touchid.ErrorExt
   * @type {Object}
   * @property {string} OS  the current Operative System
   * @property {string} code  the native error code
   * @property {string} desc   the native error description
   * @description The Error object original from native depending on OS
   */

  /**
   * @typedef module:touchid.Error
   * @type {Object}
   * @property {string} errCode  the error code
   * @property {string} errMsg   the default error message
   * @property [{module:touchid.ErrorExt}] ext   the native error source
   * @description The Error object returned in all error callbacks
   */

   // ==========================================================================================================================================

  /**
   * @callback module:touchid.isAvailableSuccess}
   * @description isAvailable Success callback
   */

  /**
   *
   * @callback module:touchid.isAvailableFail
   * @param {module:touchid.Error} reason fail reason
   * @description Fail callback
   */

  /**
   * Check if the biometric sensor is available and ready to use
   *
   * @param  {module:touchid.isAvailableSuccess} successCallback    callback for success
   * @param  {module:touchid.isAvailableFail}    errorCallback      callback for fail
   *
   * Possible error codes:
   *    ErrorCodes.BIOMETRIC_NOT_AVAILBALE (-1)     Biometric sensor not availble on this device
   *    ErrorCodes.BIOMETRIC_NOT_ENROLLED (-2)      Biometric sensor available on this device but not enrolled
   *    ErrorCodes.GENERIC_ERROR (-3)               Generic Error
   *    ErrorCodes.BIOMETRIC_LOCKED_OUT (-10)       Biometric sensor is locked out
   *
   */
	isAvailable: function(successCallback, errorCallback){
		exec(successCallback, errorCallback, "TouchID", "isAvailable", []);
	},

  // ==========================================================================================================================================

  /**
   * @callback module:touchid.saveSuccess}
   * @description save Success callback
   */

  /**
   *
   * @callback module:touchid.saveFail
   * @param {module:touchid.Error} reason fail reason
   * @description Fail callback
   */

  /**
   * Save a value for the given key
   *
   * @param  {String}                       key                         the key
   * @param  {String}                       value                       the value to store
   * @param  {boolean}                      userAuthenticationRequired  for future use (always true)
   * @param  {module:touchid.saveSuccess}   successCallback             callback for success
   * @param  {module:touchid.saveFail}      errorCallback               callback for fail
   *
   * Possible error codes:
   *    ErrorCodes.VALUE_COULD_NOT_BE_SAVED (-5)     The value could not be deleted
   *
   */
	save: function(key,value, userAuthenticationRequired, successCallback, errorCallback) {
		exec(successCallback, errorCallback, "TouchID", "save", [key,value, userAuthenticationRequired]);
	},

  // ==========================================================================================================================================

  /**
   * @callback module:touchid.verifySuccess}
   * @description verify Success callback
   * @param {string} value    a value for the given key
   */

  /**
   *
   * @callback module:touchid.verifyFail
   * @param {module:touchid.Error} reason fail reason
   * @description Fail callback
   */

  /**
   * Get a value for the given key with fingerprint authorization
   *
   * @param  {String}                         key               the key
   * @param  {module:touchid.verifySuccess}   successCallback    callback for success
   * @param  {module:touchid.verifyFail}      errorCallback      callback for fail
   *
   * Possible error codes:
   *    ErrorCodes.KEY_NOT_FOUND (-7)               Key not found
   *    ErrorCodes.GENERIC_ERROR (-3)               Generic Error
   *    ErrorCodes.USER_CANCELED (-8)               Canceled by user
   *    ErrorCodes.AUTHENTICATION_FAILED (-9)       Authentication failed
   *    ErrorCodes.BIOMETRIC_LOCKED_OUT (-10)       Biometric sensor is locked out
   *    ErrorCodes.USER_FALLBACK (-20)              Canceled by user for fallback authentication
   *
   */
	verify: function(key,message,successCallback, errorCallback){
		exec(successCallback, errorCallback, "TouchID", "verify", [key,message]);
	},

  // ==========================================================================================================================================

  /**
   * @callback module:touchid.hasSuccess}
   * @description has Success callback
   */

  /**
   *
   * @callback module:touchid.hasFail
   * @param {module:touchid.Error} reason fail reason
   * @description Fail callback
   */

  /**
   * Check if the given key is available
   *
   * @param  {String}                      key                the key
   * @param  {module:touchid.hasSuccess}   successCallback    callback for success
   * @param  {module:touchid.hasFail}      errorCallback      callback for fail
   */
  has: function(key,successCallback, errorCallback){
		exec(successCallback, errorCallback, "TouchID", "has", [key]);
	},

  // ==========================================================================================================================================

  /**
   * @callback module:touchid.deleteSuccess}
   * @description delete Success callback
   */

  /**
   *
   * @callback module:touchid.deleteFail
   * @param {module:touchid.Error} reason fail reason
   * @description Fail callback
   */

  /**
   * Delete value for the given key
   *
   * @param  {String}                         key                the key
   * @param  {module:touchid.deleteSuccess}   successCallback    callback for success
   * @param  {module:touchid.deleteFail}      errorCallback      callback for fail
   *
   * Possible error codes:
   *    ErrorCodes.VALUE_COULD_NOT_BE_DELETED (-6)     The value could not be deleted
   *
   */
  delete: function(key,successCallback, errorCallback){
		exec(successCallback, errorCallback, "TouchID", "delete", [key]);
	},

  // ==========================================================================================================================================


  didFingerprintDatabaseChange: function (successCallback, errorCallback) {
  		exec(successCallback, errorCallback, "TouchID", "didFingerprintDatabaseChange", []);
  },

  biometricType: function(successCallback, errorCallback){
		exec(successCallback, errorCallback, "TouchID", "biometricType", []);
	}

};

module.exports = touchid;
