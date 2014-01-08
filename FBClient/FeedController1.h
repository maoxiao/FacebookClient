//
//  FeedController1.h
//  ADVFlatUI
//
//  Created by Tope on 03/06/2013.
//  Copyright (c) 2013 App Design Vault. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "FacebookInstance.h"

@interface FeedController1 : UIViewController <UITableViewDataSource, FacebookFeedsDataDelegatge>

@property (nonatomic, weak) IBOutlet UITableView* feedTableView;

- (void) refreshResult;
@end
