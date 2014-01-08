//
//  FBUserInfo.m
//  FBClient
//
//  Created by Xiao Mao on 1/6/14.
//  Copyright (c) 2014 Xiao Mao. All rights reserved.
//

#import "FBUserInfo.h"

@implementation FBUserInfo

- (void) parseUserData:(NSDictionary *)userDict
{
    self.firstname = [userDict objectForKey:@"first_name"];
    self.lastname  = [userDict objectForKey:@"last_name"];
    self.email     = [userDict objectForKey:@"email"];
    self.gender    = [userDict objectForKey:@"gender"];
    self.timezone  = [[userDict objectForKey:@"timezone"] integerValue];
}

@end
