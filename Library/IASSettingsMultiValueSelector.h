//
//  MultiValueSelectorViewController.h
//  InApplicationSettings
//
//  Created by Miklós Fazekas on 4/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MultiValueSelectorViewController : UITableViewController {
    NSDictionary* spec;
    NSIndexPath* _indexPath;
    NSUInteger selected;
    NSMutableArray* targetActions;
}

- (id)init;
- (void)addTarget:(id)target action:(SEL)action;

@property (nonatomic,retain) NSDictionary* spec;
@property (nonatomic,retain) NSIndexPath* indexPath;
@property (nonatomic)        NSUInteger selected;


@end
