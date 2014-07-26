//
//  WDCPartyTableViewController.m
//  WWDC
//
//  Created by Genady Okrain on 5/17/14.
//  Copyright (c) 2014 Sugar So Studio. All rights reserved.
//

#import <EventKitUI/EventKitUI.h>
#import <MapKit/MapKit.h>
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"
#import "JVObserver.h"
#import "WDCPartyTableViewController.h"
#import "WDCParties.h"
#import "WDCPartiesTVC.h"
#import "WDCMapDayViewController.h"

@interface WDCPartyTableViewController () <EKEventEditViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *detailsTextView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *address1Label;
@property (weak, nonatomic) IBOutlet UILabel *address2Label;
@property (weak, nonatomic) IBOutlet UILabel *address3Label;
@property (weak, nonatomic) IBOutlet UIButton *goingButton;
@property (weak, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (strong, nonatomic) JVObserver *observer;

@end

@implementation WDCPartyTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Google
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"WDCPartyTableViewController"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];

    self.observer = [JVObserver observerForObject:self.party keyPath:@"logo" target:self block:^(__weak typeof(self) self) {
        if (self.party.logo) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.logoImageView.image = self.party.logo;
            });
        }
    }];

    self.titleLabel.text = self.party.title;

    NSMutableAttributedString *attributedDetails = [[NSMutableAttributedString alloc]initWithString:self.party.details];
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f];
    [attributedDetails addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, self.party.details.length)];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineHeightMultiple = 20.0f;
    paragraphStyle.maximumLineHeight = 20.0f;
    paragraphStyle.minimumLineHeight = 20.0f;
    [attributedDetails addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, self.party.details.length)];
    UIColor *color = [UIColor colorWithRed:146.0f/255.0f green:146.0f/255.0f blue:146.0f/255.0f alpha:1.0f];
    [attributedDetails addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, self.party.details.length)];
    self.detailsTextView.attributedText = attributedDetails;
    self.dateLabel.text = [self.party date];
    self.hoursLabel.text = [self.party hours];
    MKCoordinateRegion region;
    region.center.latitude = [self.party.latitude floatValue];
    region.center.longitude = [self.party.longitude floatValue];
    region.span.latitudeDelta = 0.0075f;
    region.span.longitudeDelta = 0.0075f;
    [self.mapView setRegion:region animated:NO];
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = CLLocationCoordinate2DMake([self.party.latitude floatValue], [self.party.longitude floatValue]);
    [self.mapView addAnnotation:annotation];
    self.address1Label.text = self.party.address1;
    self.address2Label.text = self.party.address2;
    self.address3Label.text = self.party.address3;
    [self refreshGoing];

    // I hope to find better way to do it
    CGRect frame = self.view.frame;
    if (self.splitViewController) {
        if (self.splitViewController.viewControllers.count == 2) {
            frame = [self.splitViewController.viewControllers[1] view].frame;
        }
    }
    CGRect detailsTextViewFrame = self.detailsTextView.frame;
    CGFloat width = frame.size.width-30.0f;
    detailsTextViewFrame.size.width = width;
    detailsTextViewFrame.size.height = [self.detailsTextView sizeThatFits:CGSizeMake(detailsTextViewFrame.size.width, FLT_MAX)].height;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.detailsTextView.frame = detailsTextViewFrame;
        [self.tableView reloadData];
    });
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    // I hope to find better way to do it
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        CGRect detailsTextViewFrame = self.detailsTextView.frame;
        detailsTextViewFrame.size.height = [self.detailsTextView sizeThatFits:CGSizeMake(detailsTextViewFrame.size.width, FLT_MAX)].height;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.detailsTextView.frame = detailsTextViewFrame;
            [self.tableView reloadData];
        });
    }];
}

- (void)refreshGoing
{
    if ([[WDCParties sharedInstance].going indexOfObject:self.party.objectId] == NSNotFound) {
        [self.goingButton setTitle:NSLocalizedString(@"Not Going", nil) forState:UIControlStateNormal];
        [self.goingButton setTitleColor:[UIColor colorWithRed:106.0/255.0f green:118.0/255.f blue:220.f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [self.goingButton setTitleColor:[UIColor colorWithRed:106.0/255.0f green:118.0/255.f blue:220.f/255.0f alpha:0.3f] forState:UIControlStateHighlighted];
        [self.goingButton setImage:nil forState:UIControlStateNormal];
    } else {
        [self.goingButton setTitle:NSLocalizedString(@"Going", nil) forState:UIControlStateNormal];
        [self.goingButton setTitleColor:[UIColor colorWithRed:46.0f/255.0f green:204.0/255.f blue:113.f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [self.goingButton setTitleColor:[UIColor colorWithRed:46.0f/255.0f green:204.0/255.f blue:113.f/255.0f alpha:0.3f] forState:UIControlStateHighlighted];
        [self.goingButton setImage:[UIImage imageNamed:@"going"] forState:UIControlStateNormal];
    }
}

- (IBAction)updateGoing:(id)sender
{
    if ([[WDCParties sharedInstance].going indexOfObject:self.party.objectId] == NSNotFound) {
        [[WDCParties sharedInstance].going addObject:self.party.objectId];
    } else {
        [[WDCParties sharedInstance].going removeObject:self.party.objectId];
    }
    [self refreshGoing];
    [[WDCParties sharedInstance] saveGoing];

    if ([self.splitViewController.viewControllers[0] isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = self.splitViewController.viewControllers[0];
        if ([navigationController.topViewController isKindOfClass:[WDCPartiesTVC class]]) {
            WDCPartiesTVC *partiesTVC = (WDCPartiesTVC *)navigationController.topViewController;
            [partiesTVC updateFilteredParties];
        }
    }
}

- (IBAction)openMaps:(id)sender
{
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [self.party.latitude floatValue];
    coordinate.longitude = [self.party.longitude floatValue];
    NSMutableDictionary *addressDictionary = [[NSMutableDictionary alloc] init];
    [addressDictionary setObject:@"United States" forKey:(NSString *)kABPersonAddressCountryKey];
    if (self.party.address2) {
        [addressDictionary setObject:self.party.address2 forKey:(NSString *)kABPersonAddressStreetKey];
    }
    NSArray *address3Split = [self.party.address3 componentsSeparatedByString: @", "];
    if ([address3Split count] == 2) {
        [addressDictionary setObject:address3Split[0] forKey:(NSString *)kABPersonAddressCityKey];
        NSArray *address3SplitSplit = [address3Split[1] componentsSeparatedByString: @" "];
        if ([address3SplitSplit count] == 2) {
            [addressDictionary setObject:address3SplitSplit[0] forKey:(NSString *)kABPersonAddressStateKey];
            [addressDictionary setObject:address3SplitSplit[1] forKey:(NSString *)kABPersonAddressZIPKey];
        }
    }
    MKMapItem *item = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:[addressDictionary copy]]];
    item.name = self.party.title;
    [item openInMapsWithLaunchOptions:@{MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking,
                                        MKLaunchOptionsMapTypeKey: [NSNumber numberWithInteger:MKMapTypeStandard]}];
}

- (IBAction)openCal:(id)sender
{
    EKEventStore *es = [[EKEventStore alloc] init];
    EKAuthorizationStatus authorizationStatus = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
    BOOL needsToRequestAccessToEventStore = (authorizationStatus == EKAuthorizationStatusNotDetermined);

    if (needsToRequestAccessToEventStore) {
        [es requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            if (granted) {
                [self addEvent];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please allow access to the Calendars", nil)
                                                                    message:nil
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil];
                [alertView show];
            }
        }];
    } else {
        BOOL granted = (authorizationStatus == EKAuthorizationStatusAuthorized);
        if (granted) {
            [self addEvent];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please allow access to the Calendars", nil)
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }
}

- (void)addEvent
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    EKEvent *event  = [EKEvent eventWithEventStore:eventStore];

    // Event
    event.title     = self.party.title;
    event.startDate = self.party.startDate;
    event.endDate   = self.party.endDate;
    event.location  = [NSString stringWithFormat:@"%@, %@, %@", self.party.address1, self.party.address2, self.party.address3];
    event.URL       = [NSURL URLWithString:self.party.url];
    event.notes     = self.party.details;

    // addController
    EKEventEditViewController *addController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
    addController.eventStore = eventStore;
    addController.event = event;
    addController.editViewDelegate = self;
    [self presentViewController:addController animated:YES completion:nil];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.row == 6) { // Xcode Bug #2
        cell.backgroundColor = [UIColor colorWithRed:106.0f/255.0f green:111.8f/255.0f blue:220.0f/255.0f alpha:1.0f];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 6) {
        NSURL *url = [NSURL URLWithString:self.party.url];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = [super tableView:tableView heightForRowAtIndexPath:indexPath];

    if (indexPath.row == 2) {
        height = CGRectGetHeight(self.detailsTextView.bounds)-5.0f;
    } else if (indexPath.row == 1) {
        height = CGRectGetHeight(self.titleLabel.bounds);
    }

    return height;
}

#pragma mark - EKEventEditViewDelegate

- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
    NSError *error = nil;
    switch (action) {
        case EKEventEditViewActionSaved:
            [controller.eventStore saveEvent:controller.event span:EKSpanThisEvent error:&error];
            break;
        default:
            break;
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end