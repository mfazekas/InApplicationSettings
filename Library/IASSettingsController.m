//
//  RootViewController.m
//  IASSettingsController
//
//  Created by Miklós Fazekas on 4/11/09.
//  Copyright Miklós Fazekas 2009. All rights reserved.
//  http://www.unittested.com/blog
//

#import "IASSettingsController.h"

#import "IASSettingsMultiValueSelector.h"


@interface IASSettingsController()

- (BOOL)goToNextKeyboardEditableCell:(UITableViewCell*)cell;
@end


#define VALUE_TAG 102

@interface IASImpl_Common : NSObject
{
    NSDictionary* spec;
    NSUserDefaults* defaults;
    IASSettingsController* controller;
}

- (id)initWithSpec:(NSDictionary*)spec defaults:(NSUserDefaults*)defaults controller:(IASSettingsController*)controller;
- (UITableViewCell*)cellForRowInTableView:(UITableView*)tableView;
- (BOOL)willSelectCell:(UITableViewCell*)cell;
- (BOOL)keyboardEditable;

@end

typedef struct IASVisualSettings {
    CGFloat rowSpaceBetweenItems;
    CGFloat rowLeftMargin;
    CGFloat rowRightMargin;
    CGFloat rowLeft;
    CGFloat rowRight;
    CGFloat rowHeight;
    UIColor* valueColor;
    
} IASVisualSettings;


@implementation IASImpl_Common

- (void)createSubviewsForCell:(UITableViewCell*)cell visualSettings:(IASVisualSettings*)vs
{
    [NSException exceptionWithName:@"unimplemented createSubviewsForCell" reason:@"should be implemented by subclasses" userInfo:0];
}

- (void)configureCellValueView:(UITableViewCell*)cell
{
    [NSException exceptionWithName:@"unimplemented configureCellValueView" reason:@"should be implemented by subclasses" userInfo:0];
}

- (BOOL)willSelectCell:(UITableViewCell*)cell
{
    return NO;
}

- (BOOL)keyboardEditable
{
    return NO;
}

- (id)initWithSpec:(NSDictionary*)inSpec defaults:(NSUserDefaults*)inDefaults controller:(IASSettingsController*)inController;
{
    self = [super init];
    if (self != nil) {
        defaults = [inDefaults retain];
        spec = [inSpec retain];
        controller = [inController retain];
    }
    return self;
}

#define TABLE_SIDE_OUTER_MARGIN 10
#define TABLE_SIDE_MARGIN 12
#define MARGIN_BETWEEN_ITEMS 12
#define TABLE_DISCLOSURE_SIZE 16

#define NORMAL_EDITOR_WIDTH 92

- (UIColor*)valueColor
{
    return [UIColor colorWithRed:80.0/255.0 green:94.0/255.0 blue:147.0/255.0 alpha:1.0];
}

- (void)configureCell:(UITableViewCell*)cell
{
    cell.textLabel.text = [spec objectForKey:@"Title"];
    [self configureCellValueView:cell];
}

- (UITableViewCell *)tableView:(UITableView*) tableView cellWithReuseIdentifier:(NSString *)identifier {
    UITableViewCell* cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:identifier] autorelease];    
    
    cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0];
    
    double rowWidth = tableView.frame.size.width;
    rowWidth -= 2*TABLE_SIDE_OUTER_MARGIN;
    double rowRight = TABLE_SIDE_OUTER_MARGIN+rowWidth;
    double rowHeight = 42;
//    double rowLeft = TABLE_SIDE_OUTER_MARGIN;
//    double itemsLeft = rowLeft+TABLE_SIDE_MARGIN;
//    double itemsRight = rowRight-TABLE_SIDE_MARGIN;
    
    IASVisualSettings vs = {0};
    vs.rowLeft = TABLE_SIDE_OUTER_MARGIN;
    vs.rowRight = rowRight;
    vs.rowHeight = rowHeight;
    vs.valueColor = [self valueColor];
    vs.rowLeftMargin = TABLE_SIDE_MARGIN;
    vs.rowRightMargin = TABLE_SIDE_MARGIN;
    vs.rowSpaceBetweenItems = MARGIN_BETWEEN_ITEMS;
    
    [self createSubviewsForCell:cell visualSettings:&vs];
    return cell;
}

- (UITableViewCell*)cellForRowInTableView:(UITableView*)tableView
{
    NSString *cellIdentifier = [spec objectForKey:@"Type"];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [self tableView:tableView cellWithReuseIdentifier:cellIdentifier];
    }
    
    [self configureCell:cell];
    return cell;
}

- (void) dealloc
{
    [spec release]; spec = 0;
    [defaults release]; defaults = 0;
    [controller release]; controller = 0;
    [super dealloc];
}


- (int)multiValueIndexForValue:(NSObject*)value 
{
    NSArray* values = [spec objectForKey:@"Values"];
    for (int idx = 0; idx < values.count; ++idx) {
        if ([[values objectAtIndex:idx] isEqual:value]) {
            return idx;
        }
    }   
    return -1;
}

- (NSString*)multiValueTitleForValue:(NSObject*)value 
{
    int idx = [self multiValueIndexForValue:value];
    if (idx < 0)
        return 0;
    
    return [[spec objectForKey:@"Titles"] objectAtIndex:idx];
}

@end

@interface IASImpl_PSChildPaneSpecifier : IASImpl_Common
{
}

@end

@implementation IASImpl_PSChildPaneSpecifier


- (BOOL)willSelectCell:(UITableViewCell*)cell
{
    NSString* file = [spec objectForKey:@"File"];
    NSString* path = [[[controller.plistPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:file]stringByAppendingPathExtension:@"plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        IASSettingsController* childController = [[[IASSettingsController alloc] init] autorelease];
        childController.plistPath = path;
        childController.title = [spec objectForKey:@"Title"];
        childController.defaults = defaults;
        [controller.navigationController pushViewController:childController animated:YES];
    }
    return YES;
}

- (void)createSubviewsForCell:(UITableViewCell*)cell visualSettings:(const IASVisualSettings*) visual
{
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)configureCellValueView:(UITableViewCell*)cell
{
}

@end



@interface IASImpl_PSMultiValueSpecifier : IASImpl_Common
{
}
@end

@implementation IASImpl_PSMultiValueSpecifier

- (void)mutliValueChanged:(MultiValueSelectorViewController*)mvController
{
    NSUInteger value = [[[spec objectForKey:@"Values"] objectAtIndex:mvController.selected] intValue];
    [defaults setInteger:value forKey:[spec objectForKey:@"Key"]];
    
    UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:mvController.indexPath];
    if (cell) {
        [self configureCellValueView:cell];
    }
}

- (BOOL)willSelectCell:(UITableViewCell*)cell
{
    NSString* key = [spec objectForKey:@"Key"];
    NSObject* value = [defaults objectForKey:key];
    if (!value) {
        value = [spec objectForKey:@"DefaultValue"];
    }
    int idx = [self multiValueIndexForValue:value];
    if (idx < 0)
        idx = 0;
    MultiValueSelectorViewController* mvSelectorController = [[[MultiValueSelectorViewController alloc] init] autorelease];
    mvSelectorController.spec = spec;
    mvSelectorController.selected = idx;
    mvSelectorController.indexPath = [controller.tableView indexPathForCell:cell];
    [controller.navigationController pushViewController:mvSelectorController animated:YES];
    [mvSelectorController addTarget:self action:@selector(mutliValueChanged:)];
    return YES;  
}

- (void)createSubviewsForCell:(UITableViewCell*)cell visualSettings:(const IASVisualSettings*) visual
{
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    double height = 20.0;
    UIFont* tileFont = cell.textLabel.font;
    CGSize titleSize = [[spec objectForKey:@"Title"] sizeWithFont:tileFont];
    double left= TABLE_SIDE_MARGIN+titleSize.width+MARGIN_BETWEEN_ITEMS;
    UILabel* valueLabel = [[[UILabel alloc] initWithFrame:CGRectMake(left,(44.0-height)/2.0,visual->rowRight-TABLE_SIDE_MARGIN-TABLE_DISCLOSURE_SIZE-left,height)] autorelease];
    valueLabel.tag = VALUE_TAG;
    valueLabel.textAlignment = UITextAlignmentRight;
    valueLabel.textColor = [self valueColor];
    [cell addSubview:valueLabel];
}

- (void)configureCellValueView:(UITableViewCell*)cell
{
    UILabel* valueLabel = (UILabel*)[cell viewWithTag:VALUE_TAG];
    NSString* key = [spec objectForKey:@"Key"];
    NSObject* value = [defaults objectForKey:key];
    if (!value) {
        value = [spec objectForKey:@"DefaultValue"];
    }
    valueLabel.text = [self multiValueTitleForValue:value];
}

@end

@interface IASImpl_PSSliderSpecifier : IASImpl_Common
{
}
@end

@implementation IASImpl_PSSliderSpecifier

- (void)sliderChanged:(UISlider*)slider
{
    [defaults setDouble:slider.value forKey:[spec objectForKey:@"Key"]];
}

- (void)createSubviewsForCell:(UITableViewCell*)cell visualSettings:(const IASVisualSettings*) visual
{
    double itemsLeft = visual->rowLeft+TABLE_SIDE_MARGIN;
    double itemsRight = visual->rowRight-TABLE_SIDE_MARGIN;
    
    UISlider* valueSlider = [[[UISlider alloc] initWithFrame:CGRectMake(itemsLeft,0,itemsRight-itemsLeft,visual->rowHeight)] autorelease];
    valueSlider.tag = VALUE_TAG;
    [cell addSubview:valueSlider];
}

- (void)configureCellValueView:(UITableViewCell*)cell
{
    UISlider* slider = (UISlider*)[cell viewWithTag:VALUE_TAG];
    if ([spec objectForKey:@"MinimumValue"]) {
        slider.minimumValue = [[spec objectForKey:@"MinimumValue"] doubleValue];
        slider.maximumValue = [[spec objectForKey:@"MaximumValue"] doubleValue];
    }
    NSString* key = [spec objectForKey:@"Key"];
    if ([defaults objectForKey:key]) {
        slider.value = [defaults doubleForKey:key];
    } else {
        slider.value = [[spec objectForKey:@"DefaultValue"] doubleValue];
    }
    [slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
}


@end


@interface IASImpl_PSToggleSwitchSpecifier :IASImpl_Common
{
}
@end

@implementation IASImpl_PSToggleSwitchSpecifier

- (void)switchChanged:(UISwitch*)toggleSwitch
{
    [defaults setBool:toggleSwitch.on forKey:[spec objectForKey:@"Key"]];
}

- (void)createSubviewsForCell:(UITableViewCell*)cell visualSettings:(const IASVisualSettings*) visual
{
    UISwitch* valueSwitch = [[[UISwitch alloc] initWithFrame:CGRectMake(0,0,100,visual->rowHeight)] autorelease];
    CGRect frame = valueSwitch.frame;
    frame.origin.x = visual->rowRight-frame.size.width-visual->rowRightMargin;
    frame.origin.y = (visual->rowHeight-frame.size.height)/2.0;
    valueSwitch.tag = VALUE_TAG;
    valueSwitch.frame = frame;
    [cell addSubview:valueSwitch];
}

- (void)configureCellValueView:(UITableViewCell*)cell
{
    UISwitch* toggleSwitch = (UISwitch*)[cell viewWithTag:VALUE_TAG];
    NSString* key = [spec objectForKey:@"Key"];
    if ([defaults objectForKey:key]) {
        toggleSwitch.on = [defaults boolForKey:key];
    } else {
        toggleSwitch.on = [[spec objectForKey:@"DefaultValue"] boolValue];
    }
    [toggleSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
}

@end



@interface IASImpl_PSTitleValueSpecifier : IASImpl_Common
{
}

- (void)configureCellValueView:(UITableViewCell*)cell;
- (void)createSubviewsForCell:(UITableViewCell*)cell visualSettings:(const IASVisualSettings*) dimensions;

@end

@implementation IASImpl_PSTitleValueSpecifier

- (void)createSubviewsForCell:(UITableViewCell*)cell visualSettings:(const IASVisualSettings*) visual
{
    UIFont* tileFont = cell.textLabel.font;
    double height = 20.0;
    CGSize titleSize = [[spec objectForKey:@"Title"] sizeWithFont:tileFont];
    double left= visual->rowLeftMargin+titleSize.width+visual->rowSpaceBetweenItems;
    UILabel* valueLabel = [[[UILabel alloc] initWithFrame:CGRectMake(left,(44.0-height)/2.0,visual->rowRight-visual->rowRightMargin-left,height)] autorelease];
    valueLabel.tag = VALUE_TAG;
    valueLabel.textAlignment = UITextAlignmentRight;
    valueLabel.textColor = visual->valueColor;
    [cell addSubview:valueLabel];
}

- (void)configureCellValueView:(UITableViewCell*)cell
{
    UILabel* valueLabel = (UILabel*)[cell viewWithTag:VALUE_TAG];
    NSString* key = [spec objectForKey:@"Key"];
    NSObject* value = [defaults objectForKey:key];
    if (!value) {
        value = [spec objectForKey:@"DefaultValue"];
    }
    valueLabel.text = [self multiValueTitleForValue:value];
}
@end

@interface IASImpl_PSTextFieldSpecifier : IASImpl_Common<UITextFieldDelegate>
{
}

- (void)configureCellValueView:(UITableViewCell*)cell;
- (void)createSubviewsForCell:(UITableViewCell*)cell visualSettings:(const IASVisualSettings*) dimensions;

@end

@implementation IASImpl_PSTextFieldSpecifier

- (UITextAutocorrectionType) autocorrectionType
{
    NSString* type = [spec objectForKey:@"AutocorrectionType"];
    if ([type isEqualToString:@"Yes"]) {
        return UITextAutocorrectionTypeYes;
    } else if ([type isEqualToString:@"No"]) {
        return UITextAutocorrectionTypeNo;
    } else {
        return UITextAutocorrectionTypeDefault;
    }
}

- (UITextAutocapitalizationType) autocapitalizationType
{
    NSString* type = [spec objectForKey:@"AutocapitalizationType"];
    if ([type isEqualToString:@"None"]) {
        return UITextAutocapitalizationTypeNone;
    } else if ([type isEqualToString:@"Sentences"]) {
        return UITextAutocapitalizationTypeSentences;
    } else if ([type isEqualToString:@"Words"]) {
        return UITextAutocapitalizationTypeWords;
    } else if ([type isEqualToString:@"AllCharacters"]) {
        return UITextAutocapitalizationTypeAllCharacters;
    } else {
        return UITextAutocapitalizationTypeNone;
    }
}

- (UIKeyboardType) keyboardType
{
    NSString* type = [spec objectForKey:@"KeyboardType"];
    if ([type isEqualToString:@"Alphabet"]) {
        return UIKeyboardTypeASCIICapable;
    } else if ([type isEqualToString:@"NumbersAndPunctuation"]) {
        return UIKeyboardTypeNumbersAndPunctuation;
    } else if ([type isEqualToString:@"NumberPad"]) {
        return UIKeyboardTypeNumberPad;
    } else if ([type isEqualToString:@"URL"]) {
        return UIKeyboardTypeURL;
    } else if ([type isEqualToString:@"EmailAddress"]) {
        return UIKeyboardTypeEmailAddress;
    } else {
        return UIKeyboardTypeASCIICapable;
    }
}

- (void)textFieldChanged:(UITextField*)textField
{
    [defaults setObject:textField.text forKey:[spec objectForKey:@"Key"]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    UITableViewCell* cell = (UITableViewCell*)[textField superview];
    return ![controller goToNextKeyboardEditableCell:cell];
}

- (BOOL)keyboardEditable
{
    return YES;
}

- (BOOL)willSelectCell:(UITableViewCell*)cell
{
    [[cell viewWithTag:VALUE_TAG] becomeFirstResponder];
    return NO;
}

- (void)createSubviewsForCell:(UITableViewCell*)cell visualSettings:(const IASVisualSettings*) visual
{
    double height = 20.0;
    UIFont* tileFont = cell.textLabel.font;
    CGSize titleSize = [[spec objectForKey:@"Title"] sizeWithFont:tileFont];
    double left= TABLE_SIDE_MARGIN+titleSize.width+MARGIN_BETWEEN_ITEMS;
    UITextField* textField = [[[UITextField alloc] initWithFrame:CGRectMake(left,(44.0-height)/2.0,visual->rowRight-TABLE_SIDE_MARGIN-left,height)] autorelease];
    textField.textColor = [self valueColor];
    textField.tag = VALUE_TAG;
    textField.font = [UIFont systemFontOfSize:17.0];
    textField.minimumFontSize = 12.0;
    textField.adjustsFontSizeToFitWidth = YES;
    textField.delegate = self;
    [cell addSubview:textField];
}

- (void)configureCellValueView:(UITableViewCell*)cell
{
    UITextField* textField = (UITextField*)[cell viewWithTag:VALUE_TAG];
    textField.text = [defaults stringForKey:[spec objectForKey:@"Key"]];
    if (!textField.text) {
        textField.text = [spec objectForKey:@"DefaultValue"];
    }
    textField.autocorrectionType = [self autocorrectionType];
    textField.secureTextEntry = [[spec objectForKey:@"IsSecure"] boolValue];
    textField.keyboardType = [self keyboardType];
    textField.autocapitalizationType = [self autocapitalizationType];
    [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingDidEnd | UIControlEventEditingDidEndOnExit];
}

@end

@interface IASSettingsController()

@property (nonatomic,retain) NSDictionary* settings;
@property (nonatomic,retain) NSArray* sections;

@end


@implementation IASSettingsController

@synthesize plistPath;
@synthesize settings;
@synthesize sections;
@synthesize defaults;

- (id)init
{
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    // This is needed for loading the class from a NIB
    if (self = [super initWithCoder:coder]) {
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
    }
    return self;    
}

- (id)implForSpec:(NSDictionary*)spec
{
    NSString* prefix = @"IASImpl_";
    
    Class implClass = NSClassFromString([prefix stringByAppendingString:[spec objectForKey:@"Type"]]);
    if (implClass) {
        return [[[implClass alloc] initWithSpec:spec defaults:defaults controller:self] autorelease];
    }
    return 0;
}

- (NSMutableArray*)calculateSections
{
    NSMutableArray* result = [NSMutableArray array];
    NSMutableArray* actGroupRows = [NSMutableArray array];
    NSString* actGroupTitle = 0;
    for (NSDictionary* spec in [settings objectForKey:@"PreferenceSpecifiers"]) {
        if ([[spec objectForKey:@"Type"] isEqualToString:@"PSGroupSpecifier"]) {
            if (actGroupTitle || (actGroupRows.count != 0)) {
                [result addObject:
                    [NSDictionary dictionaryWithObjectsAndKeys:
                        actGroupRows,@"Rows",
                        actGroupTitle,@"Title",
                        0,0
                    ]
                ];
            }
            actGroupRows = [NSMutableArray array];
            actGroupTitle = [spec objectForKey:@"Title"];
        } else {
            id impl = [self implForSpec:spec];
            if (impl) {
                [actGroupRows addObject:
                    [NSDictionary dictionaryWithObjectsAndKeys:
                        impl,@"impl",
                        spec,@"spec",
                        0,0
                    ]
                ];
            }
        }
    }
    if (actGroupTitle || (actGroupRows.count != 0)) {
        [result addObject:
            [NSDictionary dictionaryWithObjectsAndKeys:
                actGroupRows,@"Rows",
                actGroupTitle,@"Title",
                0,0
            ]
        ];
    }
    return result;
}

- (void)loadDefaultPlistPath
{
    NSString *pathStr = [[NSBundle mainBundle] bundlePath];
    NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent:@"Settings.bundle"];
    NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent:@"Root.plist"];
    self.plistPath = finalPath;
}

- (void)viewDidLoad {
    if (plistPath == 0) {
        [self loadDefaultPlistPath];
        
    }
    if (self.title == 0) {
        self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    }
    if (self.defaults == 0) {
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
    
    self.settings = [NSDictionary dictionaryWithContentsOfFile:self.plistPath];
    self.sections = [self calculateSections];
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section > sections.count)
        return 0;
    else {
        return [[sections objectAtIndex:section] objectForKey:@"Title"];
    }
}

- (NSArray*)rowsInSection:(NSInteger)section
{
    return [[sections objectAtIndex:section] objectForKey:@"Rows"];
}

- (NSDictionary*)specAtIndexPath:(NSIndexPath*)indexPath
{
    return [[[self rowsInSection:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"spec"];
}
- (id)implAtIndexPath:(NSIndexPath*)indexPath
{
    return [[[self rowsInSection:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"impl"];
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self rowsInSection:section].count;
}

- (id)impl:(NSDictionary*)spec
{
    if ([[spec objectForKey:@"Type"] isEqualToString:@"PSTitleValueSpecifier"]) {
        return [[[IASImpl_PSTitleValueSpecifier alloc] init] autorelease];
    }
    return 0;
}

- (UIColor*)valueColor
{
    return [UIColor colorWithRed:80.0/255.0 green:94.0/255.0 blue:147.0/255.0 alpha:1.0];
}

- (BOOL)startKeyboardEditingAtCell:(UITableViewCell*)cell spec:(NSDictionary*)spec {
    if (![[spec objectForKey:@"Type"] isEqualToString:@"PSTextFieldSpecifier"])
        return NO;
    [[cell viewWithTag:VALUE_TAG] becomeFirstResponder];
    return YES;
}


#pragma mark "End of type dependend code"

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id impl = [self implAtIndexPath:indexPath];
    return [impl cellForRowInTableView:tableView ];}



- (NSIndexPath*)nextIndexPath:(NSIndexPath*)indexPath
{
    NSUInteger row = indexPath.row;
    NSUInteger section = indexPath.section;
    row++;
    if (row >= [self tableView:[self tableView] numberOfRowsInSection:section]) {
        row = 0;
        section++;
    }
    if (section >= [self numberOfSectionsInTableView:[self tableView]]) {
        return 0;
    }
    return [NSIndexPath indexPathForRow:row inSection:section];   
}

- (BOOL)startKeyboardEditingCell:(NSIndexPath*)indexPath {
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    return [self startKeyboardEditingAtCell:cell spec:[self specAtIndexPath:indexPath]];
} 

- (BOOL)editNextEditableCell:(NSIndexPath*)indexPath
{
    NSIndexPath* act = indexPath;
    while (act = [self nextIndexPath:act]) {
        id impl = [self implAtIndexPath:act];
        if ([impl keyboardEditable]) {
            [impl willSelectCell:[self.tableView cellForRowAtIndexPath:act]];
            return YES;
        }
        #if 0
        if ([self startKeyboardEditingCell:act]) {
            return YES;
        }
        #endif
    }
    return NO;
}

- (BOOL)goToNextKeyboardEditableCell:(UITableViewCell*)cell
{
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];  
    return [self editNextEditableCell:indexPath];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    UITableViewCell* cell = (UITableViewCell*)[textField superview];
    return [self goToNextKeyboardEditableCell:cell];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    id impl = [self implAtIndexPath:indexPath];
    if ([impl willSelectCell:cell]) {
        return indexPath;
    } else {
        return NULL;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // No-op
}

- (void)dealloc {
    self.sections = 0;
    self.settings = 0;
    self.plistPath = 0;
    [super dealloc];
}


@end

