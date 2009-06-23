//
//  RootViewController.h
//  InApplicationSettings
//
//  Created by Miklós Fazekas on 4/11/09.
//  Copyright Miklós Fazekas 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IASSettingsController : UITableViewController<UITextFieldDelegate> {
    NSDictionary* settings;
    NSArray* sections;
    NSUserDefaults* defaults;
    NSString* plistPath;
}

- (id)init;

@property (nonatomic,retain) NSString* plistPath;
@property (nonatomic,retain) NSUserDefaults* defaults;
- (NSDictionary*)settings;

@end
