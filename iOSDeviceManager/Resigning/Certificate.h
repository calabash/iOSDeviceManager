
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <Foundation/Foundation.h>

// TODO: check to see if the certificate has expired or has been revoked
//
// SO post has and an example of finding the expiration date.
//
// http://stackoverflow.com/questions/8850524/seccertificateref-how-to-get-the-certificate-information
@interface Certificate : NSObject

@property(copy, readonly) NSString *commonName;
@property(copy, readonly) NSString *shasum;

+ (Certificate *)certificateWithData:(NSData *)data;

- (instancetype)initWithCommonName:(NSString *)commonName
                            shasum:(NSString *)shasum;

@end
