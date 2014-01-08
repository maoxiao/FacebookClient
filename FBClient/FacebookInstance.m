//
//  FacebookInstance.m
//  FBClient
//
//  Created by Xiao Mao on 12/30/13.
//  Copyright (c) 2013 Xiao Mao. All rights reserved.
//

#import "FacebookInstance.h"
#import "FBFeeds.h"
#import "LoginController1.h"

@interface FacebookInstance()

@property (nonatomic) FBSessionTokenCachingStrategy *tokenCachingStrategy;
//This variable used to wait for all asynchronous api call
@property (atomic) int requests;

@end

@implementation FacebookInstance

static FacebookInstance* sharedSingleton;

- (id) init
{
    if (self = [super init])
    {
        self.tokenCachingStrategy = [self createCachingStrategy];
        self.basicInfo = [[FBUserInfo alloc] init];
        self.requests = 0;
    }
    NSLog(@"Initialize FacebookInstance");
    return self;
}

+ (void)initialize
{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        sharedSingleton = [[FacebookInstance alloc] init];
    }
}

+ (id)getInstance
{
    return sharedSingleton;
}

- (FBSessionTokenCachingStrategy*)createCachingStrategy{
    // FBSample logic
    // Token caching strategies are an advanced feature of the SDK; by creating one and passing it to
    // FBSession at instantiation time, the SUUserManager class takes control of the token caching
    // behavior of session instances; this is useful to do in this application, because there may be up
    // to four users whose tokens are remembered by the application at one time; and so the names in
    // NSUserDefaults used to store these values need to reflect the user whose data is being cached
    // Note: an application with more advanced token caching needs (beyond NSUserDefaults) can derive
    // from FBSessionTokenCachingStrategy, and implement any store for the token cache that it needs,
    // including storing and retrieving tokens on an application-specific server, filesystem, etc.
    FBSessionTokenCachingStrategy *tokenCachingStrategy = [[FBSessionTokenCachingStrategy alloc]
                                                           initWithUserDefaultTokenInformationKeyName:[NSString stringWithFormat:@"FBSessionToken"]];
    return tokenCachingStrategy;
}


- (void) logout
{
    NSLog(@"Logged out of facebook");
    // Close the session and remove the access token from the cache
    [FBSession.activeSession closeAndClearTokenInformation];

    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies])
    {
        NSString* domainName = [cookie domain];
        NSRange domainRange = [domainName rangeOfString:@"facebook"];
        if(domainRange.length > 0)
        {
            [storage deleteCookie:cookie];
        }
    }

}

- (void) openSession;
{

    // If the session state is any of the two "open" states when the button is clicked
    if (FBSession.activeSession.state == FBSessionStateOpen
        || FBSession.activeSession.state == FBSessionStateOpenTokenExtended)
    {
        //Act like a logout button
        [self logout];
    }
    else
    {
        NSLog(@"open a new session");

        //Use webview login to make logout work
        FBSession.activeSession = [[FBSession alloc] initWithAppID:nil
                             permissions:self.fbPermissions
                         urlSchemeSuffix:nil
                      tokenCacheStrategy:self.tokenCachingStrategy];
        [FBSession.activeSession openWithBehavior:FBSessionLoginBehaviorForcingWebView
                                completionHandler:^(FBSession *session,
                                                    FBSessionState state,
                                                    NSError *error) {
                                    // this handler is called back whether the login succeeds or fails; in the
                                    // success case it will also be called back upon each state transition between
                                    // session-open and session-close
                                    if (error)
                                    {
                                        [self sessionStateChanged:session state:state error:error];
                                    }
                                    else
                                    {
                                        
                                        if (FBSession.activeSession.accessTokenData.accessToken) {
                                            NSLog(@"token after open session: %@", FBSession.activeSession.accessTokenData.accessToken);
                                            [self requestUserInfo];
                                        }
                                        
                                    }
                                }];
    }
}

- (void) openCachedSession;
{

    if([[NSUserDefaults standardUserDefaults] objectForKey:@"FBSessionToken"])
    {
        NSLog(@"Opoen cached session");
        FBSession.activeSession = [[FBSession alloc] initWithAppID:nil
                                                       permissions:self.fbPermissions
                                                   urlSchemeSuffix:nil
                                                tokenCacheStrategy:self.tokenCachingStrategy];
        
        [FBSession.activeSession openWithBehavior:FBSessionLoginBehaviorForcingWebView
                                completionHandler:^(FBSession *session,
                                                    FBSessionState state,
                                                    NSError *error) {
                                    // this handler is called back whether the login succeeds or fails; in the
                                    // success case it will also be called back upon each state transition between
                                    // session-open and session-close
                                    if (error)
                                    {
                                        [self sessionStateChanged:session state:state error:error];
                                    }
                                    else
                                    {
                                        [self requestUserInfo];

                                    }
                                }];
    }
}


- (void)requestUserInfo;

{
    NSLog(@"requestUserInfo");
    [FBRequestConnection startWithGraphPath:@"/me/permissions"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (!error)
                              {

                                  NSMutableArray *requestPermissions = [self checkNewPermissions:result];
                                  
                                  // If we have permissions to request
                                  if ([requestPermissions count] > 0){
                                      // Ask for the missing permissions
                                      [FBSession.activeSession
                                       requestNewReadPermissions:requestPermissions
                                       completionHandler:^(FBSession *session, NSError *error) {
                                           if (!error) {
                                               // Permission granted, we can request the user information
                                               [self makeRequestForUserInfo];
                                           } else {
                                               // An error occurred, we need to handle the error
                                               // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
                                               NSLog(@"requestNewPermssion error %@", error.description);
                                           }
                                       }];
                                  } else {
                                      // Permissions are present
                                      // We can request the user information
                                      [self makeRequestForUserInfo];
                                  }
                                  
                              } else {
                                  // An error occurred, we need to handle the error
                                  // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
                                  NSLog(@"request permssion connection error： %@", error.description);
                              }
                          }];
}

- (void) makeRequestForUserInfo;
{
    NSLog(@"makeRequestForUserInfo");
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // Success! Include your code to handle the results here
            [self.basicInfo parseUserData:result];
            NSLog(@"user first name: %@", self.basicInfo.firstname);
            [self.loginDelegate userDidLogin];
        } else {
            // An error occurred, we need to handle the error
            // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
            NSLog(@"make request data error %@", error.description);
        }
    }];
}


- (void) requestUserFeeds
{
    NSLog(@"requestUserFeeds");

    // Request the permissions the user currently has
    [FBRequestConnection startWithGraphPath:@"/me/permissions"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (!error)
                              {
                                  
                                  NSMutableArray *requestPermissions = [self checkNewPermissions:result];
                                  
                                  // If we have permissions to request
                                  if ([requestPermissions count] > 0){
                                      // Ask for the missing permissions
                                      [FBSession.activeSession
                                       requestNewReadPermissions:requestPermissions
                                       completionHandler:^(FBSession *session, NSError *error) {
                                           if (!error) {
                                               // Permission granted, we can request the user information
                                               [self makeRequestForFeedsData];
                                           } else {
                                               // An error occurred, we need to handle the error
                                               // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
                                               NSLog(@"requestNewPermssion error %@", error.description);
                                           }
                                       }];
                                  } else {
                                      // Permissions are present
                                      // We can request the user information
                                      [self makeRequestForFeedsData];
                                  }
                                  
                              } else {
                                  // An error occurred, we need to handle the error
                                  // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
                                  NSLog(@"request permssion connection error： %@", error.description);
                              }
                          }];
}

- (void) makeRequestForFeedsData
{
    //If lastFeedsRequest is not null, then refresh feeds since last feed reques, other retrive 10 items
    NSString *since = [NSString stringWithFormat:@"since=%@", self.lastFeedsRequest.description];
    NSString *req = (self.lastFeedsRequest) ? since : @"limit=10";
    NSString *url = [NSString stringWithFormat:@"me/home?date_format=U&%@", req];
    
    [FBRequestConnection startWithGraphPath:url
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error)
    {
        if (!error) {
            // Success! Include your code to handle the results here
            self.feedsRawData = [result objectForKey:@"data"] ;
            self.feedsCount = [self.feedsRawData count];
            NSLog(@"feeds count: %d", self.feedsCount);
            [self parseRawFeedsData];
        
        } else {
            // An error occurred, we need to handle the error
            // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
            NSLog(@"make request data error %@", error.description);
        }
    }];

}


- (NSMutableArray *)  checkNewPermissions:(id) result
{
    // These are the current permissions the user has
    NSDictionary *currentPermissions= [(NSArray *)[result data] objectAtIndex:0];
    
    // We will store here the missing permissions that we will have to request
    NSMutableArray *requestPermissions = [[NSMutableArray alloc] initWithArray:@[]];
    
    // Check if all the permissions we need are present in the user's current permissions
    // If they are not present add them to the permissions to be requested
    for (NSString *permission in self.fbPermissions){
        if (![currentPermissions objectForKey:permission]){
            [requestPermissions addObject:permission];
        }
    }
    return requestPermissions;
}

- (void) parseRawFeedsData
{
    if (self.feedsCount < 1) {
        [self.feedsDataDelegate beforeMakeLikeAndCommentRequest];
        return;
    }
    
    self.feeds = [NSMutableArray arrayWithCapacity:self.feedsCount];
    for(NSDictionary *dict in self.feedsRawData)
    {
        FBFeeds *feed = [[FBFeeds alloc] init];
        
        [self getCommentsCountNumberForFeed:feed withPost:[dict objectForKey:@"id"]];
        [self getLikesCountNumberForFeed:feed withPost:[dict objectForKey:@"id"]];
        feed.feedID   = [dict objectForKey:@"id"];
        feed.name     = [[dict objectForKey:@"from"] objectForKey:@"name"];
        feed.message  = [dict objectForKey:@"message"];
        feed.date     = [dict objectForKey:@"created_time"];
        feed.imageURL = [self retrieveStringFrom:[dict objectForKey:@"picture"]];
        [self.feeds addObject:feed];
        
    }
    FBFeeds *feed = [self.feeds objectAtIndex:0];
    if (nil != feed) {
        self.lastFeedsRequest = feed.date;
    }
    
    [self.feedsDataDelegate beforeMakeLikeAndCommentRequest];

}

- (void) getCommentsCountNumberForFeed:(FBFeeds *) feed withPost:(NSString *) postID
{
    ++self.requests;
    NSString *url = [NSString stringWithFormat:@"%@/comments?summary=true", postID];

    [FBRequestConnection startWithGraphPath:url
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error)
     {
         if (!error) {
             // Success! Include your code to handle the results here
             feed.commentCount = [[result objectForKey:@"summary"] objectForKey:@"total_count"];
         }
         else {
             // An error occurred, we need to handle the error
             // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
             NSLog(@"make request data error %@", error.description);
         }
         if(nil == feed.commentCount)
         {
             feed.commentCount = [NSNumber numberWithInteger:0];
         }
         --self.requests;
         if(self.requests < 1)
         {
             NSLog(@"[get comment and like count done!]");
             [self.feedsDataDelegate feedsDataDidLoad];
         }
     }];
    
}

- (void) getLikesCountNumberForFeed:(FBFeeds *) feed withPost:(NSString *) postID
{
    ++self.requests;
    NSString *url = [NSString stringWithFormat:@"%@/likes?summary=true", postID];

    [FBRequestConnection startWithGraphPath:url
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error)
     {
         if (!error) {
             // Success! Include your code to handle the results here
             feed.likeCount = [[result objectForKey:@"summary"] objectForKey:@"total_count"];
         }
         else {
             // An error occurred, we need to handle the error
             // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
             NSLog(@"make request data error %@", error.description);
         }
         if(nil == feed.likeCount)
         {
             feed.likeCount = [NSNumber numberWithInteger:0];
         }
         --self.requests;
         if(self.requests < 1)
         {
             NSLog(@"[get comment and like count done!]");
             [self.feedsDataDelegate feedsDataDidLoad];
         }
     }];
    
}

- (NSString *)stringByDecodingURLFormat:(NSString*) encodedURL
{
    NSString *result = [(NSString *)encodedURL stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

//Decode pirture url
- (NSString *)retrieveStringFrom:(NSString*) encoded
{
    NSArray *array = [encoded componentsSeparatedByString:@"url="];
    NSInteger count = [array count];
    NSString *result = [array objectAtIndex:(count - 1)];
    return [self stringByDecodingURLFormat:result];
}

// This method will handle ALL the session state changes in the app
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    // If the session was opened successfully
    if (!error && state == FBSessionStateOpen){
        NSLog(@"Session opened");

        return;
    }
    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed){
        // If the session is closed
        NSLog(@"Session closed");
    }
    
    // Handle errors
    if (error)
    {
        NSLog(@"Error: %@", error.description);
        NSString *alertText;
        NSString *alertTitle;
        // If the error requires people using an app to make an action outside of the app in order to recover
        if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
            alertTitle = @"Something went wrong";
            alertText = [FBErrorUtility userMessageForError:error];
//            [self showMessage:alertText withTitle:alertTitle];
        } else {
            
            // If the user cancelled login, do nothing
            if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
                NSLog(@"User cancelled login");
                
                // Handle session closures that happen outside of the app
            } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
                alertTitle = @"Session Error";
                alertText = @"Your current session is no longer valid. Please log in again.";
//                [self showMessage:alertText withTitle:alertTitle];
                
                // For simplicity, here we just show a generic message for all other errors
                // You can learn how to handle other errors using our guide: https://developers.facebook.com/docs/ios/errors
            } else {
                //Get more error information from the error
                NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
                
                // Show the user an error message
                alertTitle = @"Something went wrong";
                alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]];
//                [self showMessage:alertText withTitle:alertTitle];
            }
        }
        // Clear this token
        [FBSession.activeSession closeAndClearTokenInformation];

        NSHTTPCookie *cookie;
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (cookie in [storage cookies])
        {
            NSString* domainName = [cookie domain];
            NSRange domainRange = [domainName rangeOfString:@"facebook"];
            if(domainRange.length > 0)
            {
                [storage deleteCookie:cookie];
            }
        }
    }
}


@end
