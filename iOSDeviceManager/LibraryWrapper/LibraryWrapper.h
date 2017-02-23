#import <Foundation/Foundation.h>
#import "CLI.h"

/**
 Launch simulator by ID
 @param simulatorID A simulator GUID
 @return iOSReturnStatusCode from command.
 
 If the sim is already running, does nothing.
 */
int launch_simulator(const char *simulatorID);

/**
 Kill simulator by ID
 @param simulatorID A simulator GUID
 @return iOSReturnStatusCode from command.
 
 If sim isn't running, does nothing.
 */
int kill_simulator(const char *simulatorID);

/**
 Installs an app bundle. Acts as "upgrade install" (i.e. maintains app data of any previous installation).
 @param pathToApp Path to an app bundle or ipa (for physical device).
 @param deviceID 40 char device ID or simulator GUID
 @param pathToProfile Path to mobile profile used to sign the bundle before installation. Ignored for sims apps.
 @return 0 if successful, 1 otherwise.
 */
int install_app(const char *pathToApp, const char *deviceID, const char *pathToProfile);

/**
 Uninstalls an app.
 @param bundleID bundle identifier of the app you want to remove
 @param deviceID 40 char device ID or simulator GUID.
 @return iOSReturnStatusCode for the command.
 */
int uninstall_app(const char *bundleID, const char *deviceID);

/**
 Checks if an app is installed
 @param bundleID bundle identifier of the app you want to remove
 @param deviceID 40 char device ID or simulator GUID.
 @return iOSReturnStatusCode of the command.
 */
int is_installed(const char *bundleID, const char *deviceID);
