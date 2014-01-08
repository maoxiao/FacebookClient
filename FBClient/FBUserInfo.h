//
//  FBUserInfo.h
//  FBClient
//
//  Created by Xiao Mao on 1/6/14.
//  Copyright (c) 2014 Xiao Mao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBUserInfo : NSObject

@property (nonatomic, strong) NSString *firstname;
@property (nonatomic, strong) NSString *lastname;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *gender;
@property (nonatomic)         NSInteger timezone;

- (void) parseUserData:(NSDictionary *) userDict;

@end
