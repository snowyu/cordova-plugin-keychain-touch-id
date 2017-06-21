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

@implementation TouchID

/**

 isAvailable

 (-1) ERROR - Biometry not availble on this device
 (-2) ERROR - Biometry availble on this device but not enrolled
 (-3) ERROR - Generic Error

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
        long errorCode = -3;
        NSString *errorMsg = @"Touch ID Generic Error.";

       if(error)
       {
           //If an error is returned from LA Context (should always be true in this situation)
           NSDictionary *extErrorDictionary = @{@"OS":@"iOS",@"code":[NSString stringWithFormat:@"%li", (long)error.code],@"desc":error.localizedDescription};

           if (error.code == LAErrorTouchIDNotAvailable){
               errorCode = -1;
               errorMsg = @"Touch ID is not available on the device.";
           }
           if (error.code == LAErrorTouchIDNotEnrolled){
               errorCode = -2;
               errorMsg = @"Touch ID has no enrolled fingers.";
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
        NSDictionary *errorDictionary = @{@"errCode":@"-5", @"errMsg":@"Value could not be saved.", @"ext": extErrorDictionary};
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorDictionary];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }

}

/**

 delete

 (-6) ERROR - Value could not be saved

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
        NSDictionary *errorDictionary = @{@"errCode":@"-6", @"errMsg":@"Value could not be deleted.", @"ext": extErrorDictionary};
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorDictionary];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }


}

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
                        NSDictionary *errorDictionary = @{@"OS":@"iOS",@"ErrorCode":[NSString stringWithFormat:@"%li", (long)error.code],@"ErrorMessage":error.localizedDescription};
                        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorDictionary];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    }
                });
            }];

        }
        else{
            if(error)
            {
                //If an error is returned from LA Context (should always be true in this situation)
                NSDictionary *errorDictionary = @{@"OS":@"iOS",@"ErrorCode":[NSString stringWithFormat:@"%li", (long)error.code],@"ErrorMessage":error.localizedDescription};
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorDictionary];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
            else
            {
                //Should never come to this, but we treat it anyway
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Touch ID not available"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
        }
    }
    else{
           CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"-1"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}
@end
