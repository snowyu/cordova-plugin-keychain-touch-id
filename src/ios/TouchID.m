/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "TouchID.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#import <Cordova/CDV.h>

#define FPP_ERROR_CODE_TOUCHID_NOT_AVAILABLE_ON_THIS_DEVICE     -1
#define FPP_ERROR_MSG_TOUCHID_NOT_AVAILABLE_ON_THIS_DEVICE      @"Touch ID is not available on the device."

#define FPP_ERROR_CODE_NOT_ENROLLED                            -2
#define FPP_ERROR_MSG_NOT_ENROLLED                             @"Touch ID has no enrolled fingers."


#define FPP_ERROR_CODE_GENERIC_ERROR                            -3
#define FPP_ERROR_MSG_GENERIC_ERROR                             @"Touch ID Generic Error."

#define FPP_ERROR_CODE_VALUE_COULD_NOT_BE_SAVED                 -5
#define FPP_ERROR_MSG_VALUE_COULD_NOT_BE_SAVED                  @"Value could not be saved."

#define FPP_ERROR_CODE_VALUE_COULD_NOT_BE_DELETED               -6
#define FPP_ERROR_MSG_VALUE_COULD_NOT_BE_DELETED                 @"Value could not be deleted."

#define FPP_ERROR_CODE_KEY_NOT_FOUND                            -7
#define FPP_ERROR_MSG_KEY_NOT_FOUND                             @"Key not found."

#define FPP_ERROR_CODE_USER_CANCELED                            -8
#define FPP_ERROR_MSG_USER_CANCELED                             @"Canceled by user."

#define FPP_ERROR_CODE_AUTHENTICATION_FAILED                    -9
#define FPP_ERROR_MSG_AUTHENTICATION_FAILED                     @"Authentication failed."

#define FPP_ERROR_CODE_TOUCHID_LOCKED_OUT                       -10
#define FPP_ERROR_MSG_TOUCHID_LOCKED_OUT                         @"Touch ID is locked out."

#define FPP_ERROR_CODE_USER_FALLBACK                            -20
#define FPP_ERROR_MSG_USER_FALLBACK                             @"Canceled by user for fallback authentication."


static NSString *const FingerprintDatabaseStateKey = @"FingerprintDatabaseStateKey";

@implementation TouchID

/**

 isAvailable

 (-1) ERROR - Biometry not availble on this device
 (-2) ERROR - Biometry availble on this device but not enrolled
 (-3) ERROR - Generic Error
 (-10) ERROR - Touch ID is locked out

 SUCCESS - Fingerprint available and enrolled

 Error Object
 {
     errCode: X,
     errMsg: "",
     ext: {
         os : "ios",
         code: "original os error code",
         desc: "original os error message"
     }
 }
 **/
- (void)isAvailable:(CDVInvokedUrlCommand*)command{

    self.laContext = [[LAContext alloc] init];
    NSError *error;
    BOOL touchIDAvailable = [self.laContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    if(touchIDAvailable){
       CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
       [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    else{
        // by default is a generic error
        long errorCode = FPP_ERROR_CODE_GENERIC_ERROR;
        NSString *errorMsg = @"Touch ID Generic Error.";

       if(error)
       {
           //If an error is returned from LA Context (should always be true in this situation)
           NSDictionary *extErrorDictionary = @{@"OS":@"iOS",@"code":[NSString stringWithFormat:@"%li", (long)error.code],@"desc":error.localizedDescription};

           if (error.code == LAErrorTouchIDNotAvailable){
               errorCode = FPP_ERROR_CODE_TOUCHID_NOT_AVAILABLE_ON_THIS_DEVICE;
               errorMsg = FPP_ERROR_MSG_TOUCHID_NOT_AVAILABLE_ON_THIS_DEVICE;
           }
           if (error.code == LAErrorTouchIDNotEnrolled){
               errorCode = FPP_ERROR_CODE_NOT_ENROLLED;
               errorMsg = FPP_ERROR_MSG_NOT_ENROLLED;
           }

           if (error.code == LAErrorTouchIDLockout){
               errorCode = FPP_ERROR_CODE_TOUCHID_LOCKED_OUT;
               errorMsg = FPP_ERROR_MSG_TOUCHID_LOCKED_OUT; //probably for Application retry limit exceeded.
           }

           NSDictionary *errorDictionary = @{@"errCode":[NSString stringWithFormat:@"%li", (long)errorCode],@"errMsg":errorMsg, @"ext": extErrorDictionary};
           CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorDictionary];
           [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
       }
       else
       {
           //Should never come to this, but we treat it anyway
           NSDictionary *errorDictionary = @{@"errCode":[NSString stringWithFormat:@"%li", (long)errorCode],@"errMsg":errorMsg};
           CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary: errorDictionary];
           [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
       }
    }
}

- (void)setLocale:(CDVInvokedUrlCommand*)command{
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

/**

 has

 **/
- (void)has:(CDVInvokedUrlCommand*)command{

  	self.TAG = (NSString*)[command.arguments objectAtIndex:0];
    BOOL hasLoginKey = [[NSUserDefaults standardUserDefaults] boolForKey:self.TAG];

    NSDictionary *result = @{@"result": [NSNumber numberWithBool:hasLoginKey] };
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}

/**

 save

 (-5) ERROR - Value could not be saved

 Error Object
 {
    errCode: -5,
    errMsg: "Value could not be saved",
    ext: {
        os : "ios",
        code: "original os error code",
        desc: "original os error message"
    }
 }
 **/
- (void)save:(CDVInvokedUrlCommand*)command{

    self.TAG = (NSString*)[command.arguments objectAtIndex:0];
    NSString* password = (NSString*)[command.arguments objectAtIndex:1];
    @try {
        self.MyKeychainWrapper = [[KeychainWrapper alloc]init];
        [self.MyKeychainWrapper mySetObject:password forKey:(__bridge id)(kSecValueData)];
        [self.MyKeychainWrapper writeToKeychain];
        [[NSUserDefaults standardUserDefaults]setBool:true forKey:self.TAG];
        [[NSUserDefaults standardUserDefaults]synchronize];

        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    @catch(NSException *exception){
        NSDictionary *extErrorDictionary = @{@"OS":@"iOS",@"code":exception.name,@"desc":exception.reason};
        NSDictionary *errorDictionary = @{@"errCode":[NSString stringWithFormat:@"%d", FPP_ERROR_CODE_VALUE_COULD_NOT_BE_SAVED], @"errMsg":FPP_ERROR_MSG_VALUE_COULD_NOT_BE_SAVED, @"ext": extErrorDictionary};
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorDictionary];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }

}

/**

 delete

 (-6) ERROR - Value could not be deleted

 Error Object
 {
    errCode: -6,
    errMsg: "Value could not be deleted",
    ext: {
        os : "ios",
        code: "original os error code",
        desc: "original os error message"
    }
 }

 **/
-(void)delete:(CDVInvokedUrlCommand*)command{
	 	self.TAG = (NSString*)[command.arguments objectAtIndex:0];
    @try {

        if(self.TAG && [[NSUserDefaults standardUserDefaults] objectForKey:self.TAG])
        {
            self.MyKeychainWrapper = [[KeychainWrapper alloc]init];
            [self.MyKeychainWrapper resetKeychainItem];
        }


        [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.TAG];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    @catch(NSException *exception) {
        NSDictionary *extErrorDictionary = @{@"OS":@"iOS",@"code":exception.name,@"desc":exception.reason};
        NSDictionary *errorDictionary = @{@"errCode":[NSString stringWithFormat:@"%d", FPP_ERROR_CODE_VALUE_COULD_NOT_BE_DELETED], @"errMsg":FPP_ERROR_MSG_VALUE_COULD_NOT_BE_DELETED, @"ext": extErrorDictionary};
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorDictionary];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }


}

/**

 verify

 (-7)  ERROR - Key not found.
 (-3)  ERROR - Generic Error.
 (-8)  ERROR - Canceled by user.
 (-9)  ERROR - Authentication failed.
 (-10) ERROR - Touch ID is locked out
 (-20) ERROR - Canceled by user for fallback authentication.

 SUCCESS - Value returned

 Error Object
 {
    errCode: X,
    errMsg: "",
    ext: {
        os : "ios",
        code: "original os error code",
        desc: "original os error message"
    }
 }
 **/
-(void)verify:(CDVInvokedUrlCommand*)command{
	 	self.TAG = (NSString*)[command.arguments objectAtIndex:0];
	  NSString* message = (NSString*)[command.arguments objectAtIndex:1];
    self.laContext = [[LAContext alloc] init];
    self.MyKeychainWrapper = [[KeychainWrapper alloc]init];

    BOOL hasLoginKey = [[NSUserDefaults standardUserDefaults] boolForKey:self.TAG];
    if(hasLoginKey){
        NSError * error;
        BOOL touchIDAvailable = [self.laContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];

        if(touchIDAvailable){
            [self.laContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:message reply:^(BOOL success, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{

                if(success){
                    NSString *password = [self.MyKeychainWrapper myObjectForKey:@"v_Data"];
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: password];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
                    if(error != nil) {

                        long errorCode = FPP_ERROR_CODE_GENERIC_ERROR;
                        NSString *errorMsg = FPP_ERROR_MSG_GENERIC_ERROR;

                        if (error.code == LAErrorUserCancel){
                            errorCode = FPP_ERROR_CODE_USER_CANCELED;
                            errorMsg = FPP_ERROR_MSG_USER_CANCELED;
                        }

                        if (error.code == LAErrorUserFallback){
                            errorCode = FPP_ERROR_CODE_USER_FALLBACK;
                            errorMsg = FPP_ERROR_MSG_USER_FALLBACK;
                        }

                        if (error.code == LAErrorTouchIDLockout){
                            errorCode = FPP_ERROR_CODE_TOUCHID_LOCKED_OUT;
                            errorMsg = FPP_ERROR_MSG_TOUCHID_LOCKED_OUT; //probably for Application retry limit exceeded.
                        }

                        if (error.code == LAErrorAuthenticationFailed){
                            errorCode =FPP_ERROR_CODE_AUTHENTICATION_FAILED;
                            errorMsg = FPP_ERROR_MSG_AUTHENTICATION_FAILED;
                        }

                        if (error.code == LAErrorTouchIDNotAvailable){
                            errorCode = FPP_ERROR_CODE_TOUCHID_NOT_AVAILABLE_ON_THIS_DEVICE;
                            errorMsg = FPP_ERROR_MSG_TOUCHID_NOT_AVAILABLE_ON_THIS_DEVICE;
                        }
                        if (error.code == LAErrorTouchIDNotEnrolled){
                            errorCode = FPP_ERROR_CODE_NOT_ENROLLED;
                            errorMsg = FPP_ERROR_MSG_NOT_ENROLLED;
                        }

                        NSDictionary *extErrorDictionary = @{@"OS":@"iOS",@"code":[NSString stringWithFormat:@"%li", (long)error.code],@"desc":error.localizedDescription};
                        NSDictionary *errorDictionary = @{@"errCode":[NSString stringWithFormat:@"%li", (long)errorCode],@"errMsg":errorMsg, @"ext": extErrorDictionary};
                        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorDictionary];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    }
                });
            }];

        }
        else{

            // by default is a generic error
            long errorCode = FPP_ERROR_CODE_GENERIC_ERROR;
            NSString *errorMsg = FPP_ERROR_MSG_GENERIC_ERROR;

            if(error)
            {
                if (error.code == LAErrorTouchIDLockout){
                    errorCode = FPP_ERROR_CODE_TOUCHID_LOCKED_OUT;
                    errorMsg = FPP_ERROR_MSG_TOUCHID_LOCKED_OUT; //probably for Application retry limit exceeded.
                }

                if (error.code == LAErrorTouchIDNotAvailable){
                    errorCode = FPP_ERROR_CODE_TOUCHID_NOT_AVAILABLE_ON_THIS_DEVICE;
                    errorMsg = FPP_ERROR_MSG_TOUCHID_NOT_AVAILABLE_ON_THIS_DEVICE;
                }
                if (error.code == LAErrorTouchIDNotEnrolled){
                    errorCode = FPP_ERROR_CODE_NOT_ENROLLED;
                    errorMsg = FPP_ERROR_MSG_NOT_ENROLLED;
                }

                //If an error is returned from LA Context (should always be true in this situation)
                NSDictionary *extErrorDictionary = @{@"OS":@"iOS",@"code":[NSString stringWithFormat:@"%li", (long)error.code],@"desc":error.localizedDescription};
                NSDictionary *errorDictionary = @{@"errCode":[NSString stringWithFormat:@"%li", (long)errorCode],@"errMsg":errorMsg, @"ext": extErrorDictionary};
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorDictionary];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
            else
            {
                //Should never come to this, but we treat it anyway
                NSDictionary *errorDictionary = @{@"errCode":[NSString stringWithFormat:@"%li", (long)errorCode],@"errMsg":errorMsg};
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary: errorDictionary];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
        }
    }
    else{
        NSDictionary *errorDictionary = @{@"errCode":[NSString stringWithFormat:@"%d", FPP_ERROR_CODE_KEY_NOT_FOUND], @"errMsg":FPP_ERROR_MSG_KEY_NOT_FOUND };
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorDictionary];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void) didFingerprintDatabaseChange:(CDVInvokedUrlCommand*)command {
    // Get enrollment state
    [self.commandDelegate runInBackground:^{
        LAContext *laContext = [[LAContext alloc] init];
        NSError *error = nil;

        // we expect the dev to have checked 'isAvailable' already so this should not return an error,
        // we do however need to run canEvaluatePolicy here in order to get a non-nil evaluatedPolicyDomainState
        if (![laContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]] callbackId:command.callbackId];
            return;
        }

        // only supported on iOS9+, so check this.. if not supported just report back as false
        if (![laContext respondsToSelector:@selector(evaluatedPolicyDomainState)]) {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:NO] callbackId:command.callbackId];
            return;
        }

        NSData * state = [laContext evaluatedPolicyDomainState];
        if (state != nil) {

            NSString * stateStr = [state base64EncodedStringWithOptions:0];

            NSString * storedState = [[NSUserDefaults standardUserDefaults] stringForKey:FingerprintDatabaseStateKey];

            // whenever a finger is added/changed/removed the value of the storedState changes,
            // so compare agains a value we previously stored in the context of this app
            BOOL changed = storedState != nil && ![stateStr isEqualToString:storedState];

            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:changed] callbackId:command.callbackId];

            // Store enrollment
            [[NSUserDefaults standardUserDefaults] setObject:stateStr forKey:FingerprintDatabaseStateKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }];
}


- (void)biometricType:(CDVInvokedUrlCommand*)command{
    self.laContext = [[LAContext alloc] init];
    BOOL touchIDAvailable = [self.laContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    if(@available(iOS 11.0, *)){
        if(self.laContext.biometryType == LABiometryTypeFaceID){
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"FACE"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
        else if(self.laContext.biometryType == LABiometryTypeTouchID){
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"TOUCH"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
        else{
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"NONE"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }
    else{
        if(touchIDAvailable){
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"TOUCH"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
        else{
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Touch ID not available"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }
}

@end
