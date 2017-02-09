
#import "MobileProfile.h"
#import "Application.h"

@interface Codesigner : NSObject

typedef void(^appResigningCompleteBlock)(Application *app);

/**
 "resign"

 Resigns a the contents of an Application app dir.

 @param app Application to resign
 @param profile Profile to use to resign
 @return YES if successful, NO otherwise.
 @warn Resigns in-place (i.e. destructively)
 
 */
+ (void)resignApplication:(Application *)app
  withProvisioningProfile:(MobileProfile *)profile;

/**
 "resign"
 
 Resigns a the contents of an Application app dir.
 
 @param app Application to resign
 @param profile Profile to use to resign
 @param codesignIdentity CodesignIdentity to use to resign
 @return YES if successful, NO otherwise.
 @warn Resigns in-place (i.e. destructively)
 
 */
+ (void)resignApplication:(Application *)app
  withProvisioningProfile:(MobileProfile *)profile
     withCodesignIdentity:(CodesignIdentity *)codesignIdentity;

/**
 "resign"
 
 Resigns a the contents of an Application app dir.
 
 @param app Application to resign
 @param profile Profile to use to resign
 @param resourcePaths Paths to objects to inject. Intended use case is .dylibs
 @return YES if successful, NO otherwise.
 @warn Resigns in-place (i.e. destructively)
 
 Note that the objects pointed to by `resourcePaths` are simply inserted into the bundle
 prior to resigning. They are *NOT* dynamically linked with any binary executable within
 the bundle.
 */
+ (void)resignApplication:(Application *)app
  withProvisioningProfile:(MobileProfile *)profile
        resourcesToInject:(NSArray<NSString *> *)resourcePaths;

/**
 
 "resign-all"
 
 Resigns a the contents of an Application app dir once for each profile in `profiles`
 
 @param app Application to resign
 @param profiles Profiles to use to resign
 @param resourcePaths Paths to objects to inject. Intended use case is .dylibs
 @param handler Handler block to deal with each app as they become resigned. Since resigning occurs in-place,
                the caller should copy each application bundle over to a new location every time `handler` is
                invoked.
 @return YES if successful, NO otherwise.
 @warn Resigns in-place (i.e. destructively)
 
 Note that the objects pointed to by `resourcePaths` are simply inserted into the bundle
 prior to resigning. They are *NOT* dynamically linked with any binary executable within
 the bundle.
 */
+ (void)resignApplication:(Application *)app
              forProfiles:(NSArray <MobileProfile *> *)profiles
        resourcesToInject:(NSArray<NSString *> *)resourcePaths
         resigningHandler:(appResigningCompleteBlock)handler;

/**
 
 "resign-object"
 
 Resigns a .framework or .dylib
 
 @param pathToObject .framework or .dylib to resign
 @param codesignIdentity CodesignIdentity to use for resigning
*/
+ (void)resignObject:(NSString *)pathToObject
    codesignIdentity:(CodesignIdentity *)codesignID;

@end
