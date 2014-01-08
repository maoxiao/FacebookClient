//
//  FacebookInstance.h
//  FBClient
//
//  Created by Xiao Mao on 12/30/13.
//  Copyright (c) 2013 Xiao Mao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>
#import "FBUserInfo.h"

@protocol FacebookInstanceLoginDelegatge <NSObject>
@required
- (void) userDidLogin;
@end

@protocol FacebookFeedsDataDelegatge <NSObject>
@required
- (void) beforeMakeLikeAndCommentRequest;
- (void) feedsDataDidLoad;
@end


@interface FacebookInstance : NSObject

@property (nonatomic, strong) NSArray *fbPermissions;
@property (nonatomic, strong) FBUserInfo *basicInfo;
@property (nonatomic, strong) NSMutableArray *feeds;
@property (nonatomic)         NSInteger feedsCount;
@property (nonatomic, strong) NSArray *feedsRawData;
//timestamp for last feeds request
@property (nonatomic, strong) NSNumber *lastFeedsRequest;

@property (nonatomic, weak) id <FacebookInstanceLoginDelegatge> loginDelegate;
@property (nonatomic, weak) id <FacebookFeedsDataDelegatge> feedsDataDelegate;

- (void) openSession;
- (void) openCachedSession;
- (void) requestUserInfo;
- (void) makeRequestForUserInfo;
- (void) requestUserFeeds;
- (void) makeRequestForFeedsData;
- (void) logout;

- (FBSessionTokenCachingStrategy*)createCachingStrategy;
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error;
- (NSMutableArray *)  checkNewPermissions:(id)result;
- (NSString *)stringByDecodingURLFormat:(NSString*)encodedURL;
- (NSString *)retrieveStringFrom:(NSString*)encoded;
- (void) parseRawFeedsData;

+(id) getInstance;
@end
