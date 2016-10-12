
#import "TestCase.h"
#import "MobileProfile.h"
#import "CodesignIdentity.h"
#import "Entitlement.h"

@interface MobileProfile (TEST)

- (NSInteger)rank;

@end

@interface MobileProfileTest : TestCase

@end

@implementation MobileProfileTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testRankedIOSProfilesForResigning {
    if (device_available()) {
        NSString *UDID = defaultDeviceUDID;
        CodesignIdentity *identity = [[Resources shared] KarlKrukowIdentity];

        NSString *appBundle = runner(ARM);

        NSArray<MobileProfile *> *nonExpiredProfiles;
        nonExpiredProfiles = [MobileProfile nonExpiredIOSProfiles];

        NSArray<MobileProfile *> *profiles;
        profiles = [MobileProfile rankedProfiles:nonExpiredProfiles
                                    withIdentity:identity
                                      deviceUDID:UDID
                                   appBundlePath:appBundle];

        expect(profiles).notTo.equal(nil);
        expect(profiles.count).notTo.equal(0);
        expect(profiles.count >= 2).to.equal(YES);

        MobileProfile *first = profiles[0];
        MobileProfile *last = [profiles lastObject];
        expect(first.rank <= last.rank).to.equal(YES);

        NSUInteger index;
        index = [profiles indexOfObjectPassingTest:^BOOL(MobileProfile *obj,
                                                         NSUInteger idx,
                                                         BOOL *stop) {
            return obj.rank == ProfileDoesNotHaveRequiredKey;
        }];
        expect(index).to.equal(NSNotFound);

        DDLogVerbose(@"=== RANKED PROFILES ===");
        DDLogVerbose(@"%@", profiles);
    }
}

@end
