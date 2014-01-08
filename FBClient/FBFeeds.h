//
//  FBFeeds.h
//  FBClient
//
//  Created by Xiao Mao on 1/5/14.
//  Copyright (c) 2014 Xiao Mao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBFeeds : NSObject

@property (nonatomic, strong) NSString *feedID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSNumber *date;
@property (nonatomic, strong) NSNumber *likeCount;
@property (nonatomic, strong) NSNumber *commentCount;
@property (nonatomic, strong) NSString *imageURL;

@end
