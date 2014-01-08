//
//  FeedController1.m
//  ADVFlatUI
//
//  Created by Tope on 03/06/2013.
//  Copyright (c) 2013 App Design Vault. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SVPullToRefresh.h"
#import "MBProgressHUD.h"

#import "FeedController1.h"
#import "FeedCell1.h"
#import "LoginController1.h"
#import "FBFeeds.h"

@interface FeedController1 ()

@property (atomic) float numberOfTasksBeingProcessed;;
@property (nonatomic, strong) NSMutableArray *dataSource;

//process number format date
- (NSString *) getDateLabelFromNumber:(NSNumber *)rawDate;
//process string format date
- (NSString *) getDateLabelFromString:(NSString *)rawDate;
- (void) openURLImageForImageView:(FBFeeds *)feed;
- (void) logoutAction;

@end

@implementation FeedController1

NSMutableDictionary *imageDict;
FacebookInstance *fbInstance;
bool feedsDataLoaded;
float totalTasks;
MBProgressHUD *hud;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.feedTableView addPullToRefreshWithActionHandler:^{
        // prepend data to dataSource, insert cells at top of table view
        // call [tableView.pullToRefreshView stopAnimating] when done
        [self refreshResult];
    }];}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:NO];
    fbInstance = [FacebookInstance getInstance];
    fbInstance.feedsDataDelegate = self;
    imageDict = [NSMutableDictionary dictionary];

    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeAnnularDeterminate;
    hud.animationType = MBProgressHUDAnimationFade;
    hud.labelText = @"Loading";
    
    NSString* boldFontName = @"GillSans-Bold";

    [self styleNavigationBarWithFontName:boldFontName];
    self.title = fbInstance.basicInfo.firstname;
    self.feedTableView.dataSource = self;
    
    self.feedTableView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    self.feedTableView.separatorColor = [UIColor clearColor];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    FeedCell1* cell = [tableView dequeueReusableCellWithIdentifier:@"FeedCell1"];
    FBFeeds *feed = [self.dataSource objectAtIndex:indexPath.row];
    
    cell.nameLabel.text = feed.name;
    cell.updateLabel.text = feed.message;
    cell.dateLabel.text = [self getDateLabelFromNumber:feed.date];
    cell.likeCountLabel.text = feed.likeCount.description;
    cell.commentCountLabel.text = feed.commentCount.description;
    //Sometimes, cannot get orginal picture, so the image might not be very clear.
    cell.picImageView.image = [imageDict objectForKey:feed.feedID];
    
    return cell;
}

-(void)styleNavigationBarWithFontName:(NSString*)navigationTitleFont{
    
    CGSize size = CGSizeMake(320, 44);
    UIColor* color = [UIColor colorWithRed:65.0/255 green:75.0/255 blue:89.0/255 alpha:1.0];
    
    UIGraphicsBeginImageContext(size);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGRect fillRect = CGRectMake(0,0,size.width,size.height);
    CGContextSetFillColorWithColor(currentContext, color.CGColor);
    CGContextFillRect(currentContext, fillRect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UINavigationBar* navAppearance = [UINavigationBar appearance];
    
    [navAppearance setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    
    [navAppearance setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [UIColor whiteColor], UITextAttributeTextColor,
                                           [UIFont fontWithName:navigationTitleFont size:18.0f], UITextAttributeFont,
                                           nil]];

    UIBarButtonItem* logoutItem = [[UIBarButtonItem alloc]  initWithTitle:@"Logout" style:UIBarButtonItemStyleBordered target:self action:@selector(logoutAction)];
    
    [logoutItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [UIColor redColor], UITextAttributeTextColor,
                                        [UIFont fontWithName:navigationTitleFont size:18.0f], @"Avenir-Book",
                                        nil] forState:UIControlStateNormal];

    self.navigationItem.rightBarButtonItem = logoutItem;
    
    UIImageView* menuView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu.png"]];
    menuView.frame = CGRectMake(0, 0, 28, 20);
    
    UIBarButtonItem* menuItem = [[UIBarButtonItem alloc] initWithCustomView:menuView];
    
    self.navigationItem.leftBarButtonItem = menuItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) logoutAction
{
    NSLog(@"Logout button pressed!");
    [fbInstance logout];
    [self.navigationController popViewControllerAnimated:YES];

}

- (void)refreshResult
{
    [fbInstance requestUserFeeds];
}

//Convert Facebook time format to customized string
- (NSString *) getDateLabelFromString:(NSString *)rawDate
{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZ";
    NSDate *date = [dateFormatter dateFromString:rawDate];
    NSTimeInterval hours = fbInstance.basicInfo.timezone * 60 * 60;
    NSDate *result = [date dateByAddingTimeInterval:hours];
    return [result.description substringToIndex:[result.description length] - 9];
}

//Convert Unix format timestamp to customized string
- (NSString *) getDateLabelFromNumber:(NSNumber *)rawDate
{
    NSTimeInterval epoch = [rawDate doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:epoch];
    NSTimeInterval hours = fbInstance.basicInfo.timezone * 60 * 60;
    NSDate *result = [date dateByAddingTimeInterval:hours];
    return [result.description substringToIndex:[result.description length] - 9];
}

// Open internet image in the post
- (void) openURLImageForImageView:(FBFeeds *)feed
{
    NSURL *imageURL = [NSURL URLWithString:feed.imageURL];
  
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
        
        dispatch_async(dispatch_get_main_queue(), ^{

            UIImage *image  = [UIImage imageWithData:imageData];
            //Sometimes, feed is a comment post (e.g. XXX commented on this.) and its message, picture, ect are null . This is not gracefully handled.
            if(image)
            {
                [imageDict setObject:[UIImage imageWithData:imageData] forKey:feed.feedID];
            }
            --self.numberOfTasksBeingProcessed;
            hud.progress = (totalTasks - self.numberOfTasksBeingProcessed) / totalTasks;
            if (self.numberOfTasksBeingProcessed < 1) {
                NSLog(@"[Open images process completed!]");
                // Update the UI
                [self.feedTableView reloadData];
                [hud hide:YES];
                [self.feedTableView.pullToRefreshView stopAnimating];
                NSLog(@"[Done!]");
                
            }
        });
    });

}

- (void) beforeMakeLikeAndCommentRequest
{
    if(fbInstance.feedsCount < 1)
    {
        [self.feedTableView.pullToRefreshView stopAnimating];
        NSLog(@"[Done!]");
        return;
    }
    
    feedsDataLoaded = NO;
    totalTasks = fbInstance.feedsCount + 1.0;
    self.numberOfTasksBeingProcessed = totalTasks;
    if([self.dataSource count] < 1)
    {
        self.dataSource =  [[NSMutableArray alloc] initWithArray:fbInstance.feeds];
    }
    else
    {
        for (int i = 0; i < fbInstance.feedsCount; i++) {
            [self.dataSource insertObject:[fbInstance.feeds lastObject] atIndex:0];
        }
        NSLog(@"after refresh feeds: %d, dataSource: %d", fbInstance.feedsCount, [self.dataSource count]);

    }
    
    for(FBFeeds *feed in fbInstance.feeds)
    {
        [self openURLImageForImageView:feed];
    }
}

- (void) feedsDataDidLoad
{
    feedsDataLoaded = YES;
    --self.numberOfTasksBeingProcessed;
    NSLog(@"Feeds data loaded!");
    hud.progress = (totalTasks - self.numberOfTasksBeingProcessed) / totalTasks;
    if(self.numberOfTasksBeingProcessed < 1)
    {
        [self.feedTableView reloadData];
        [hud hide:YES];
        [self.feedTableView.pullToRefreshView stopAnimating];
        NSLog(@"[Done!]");
    }
}

@end
