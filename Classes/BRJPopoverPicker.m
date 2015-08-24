//
//  BRJPopoverPicker.m
//
//
//  Created by Ben Johnson on 3/30/14.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "BRJPopoverPicker.h"

static NSString * const BRJPopoverPickerCellReuseIdentifier = @"BRJPopoverPickerCellReuseIdentifier";
static CGFloat const BRJPopoverPickerIntrinsicWidth = 260.0;
static CGFloat const BRJPopoverPickerIntrinsicHeight = 400.0;
static CGFloat const BRJPopoverPickerRowHeight = 44.0;


@interface BRJPopoverPicker () <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) UIPopoverController *popoverController;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) UITableViewController *tableViewController;
@property (assign, nonatomic) NSUInteger selectedIndex;
@end

@implementation BRJPopoverPicker
- (instancetype)initWithDelegate:(id<BRJPopoverPickerDelegate>)delegate andDataSource:(id<BRJPopoverPickerDataSource>)dataSource {
    self = [super init];
    if (self) {
        _delegate = delegate;
        _dataSource = dataSource;
        _selectedIndex = NSNotFound;
        _maintainSelection = YES;
        _showCheckmarkForSelectedRow = NO;
        
        _tableViewController = ({
            UITableViewController *tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
            tableViewController.tableView.dataSource = self;
            tableViewController.tableView.delegate = self;
            [tableViewController.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:BRJPopoverPickerCellReuseIdentifier];
            tableViewController.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

            tableViewController.clearsSelectionOnViewWillAppear = NO;
            tableViewController;
        });
        
        _popoverController = ({
            _navigationController = [[UINavigationController alloc] initWithRootViewController:_tableViewController];
            
            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:_navigationController];
            popoverController.backgroundColor = [UIColor whiteColor];
            
            popoverController;
        });
    }
    return self;
}

#pragma mark - Configuration
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSString *title = [self titleForRowAtIndex:indexPath.row];
    cell.textLabel.text = title;
    cell.accessoryType = UITableViewCellAccessoryNone;

    if (self.selectedBackgroundColor && !self.showCheckmarkForSelectedRow) {
        cell.selectedBackgroundView = ({
            UIView *background = [[UIView alloc] init];
            background.backgroundColor = self.selectedBackgroundColor;
            background;
        });
    }
    
    if ([self canSelectRowAtIndex:indexPath.row]) {
        cell.selectionStyle  = UITableViewCellSelectionStyleDefault;
        cell.textLabel.textColor = [UIColor blackColor];
    }
    else {
        cell.selectionStyle = UITableViewCellEditingStyleNone;
        cell.textLabel.textColor = [UIColor grayColor];
    }

    if (self.showCheckmarkForSelectedRow) {
        // nullify background view
        cell.selectedBackgroundView = nil;
        if (self.selectedIndex == indexPath.row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
}

#pragma mark - Process Selection
- (void)selectRowAtIndex:(NSUInteger)index {
    if ([self.tableViewController.tableView numberOfRowsInSection:0] > index) {
        self.selectedIndex = index;
        
        [self processRowSelection];
    }
}

- (NSInteger)indexOfSelectedRow {
    return self.selectedIndex;
}

- (void)deselectSelectedRow {
    self.selectedIndex = NSNotFound;
    [self processRowSelection];
}

- (void)processRowSelection {
    if (self.selectedIndex == NSNotFound) {
        NSIndexPath *selectedPath = [self.tableViewController.tableView indexPathForSelectedRow];
        if (selectedPath) {
            [self.tableViewController.tableView deselectRowAtIndexPath:selectedPath animated:YES];
        }
    }
    else if (self.maintainSelection && !self.showCheckmarkForSelectedRow) {
        [self.tableViewController.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    }
}

#pragma mark - Convenience
- (NSString *)titleForRowAtIndex:(NSUInteger)index {
    return [self.dataSource popoverPicker:self titleForRowAtIndex:index];
}

- (NSUInteger)numberOfRows {
    return [self.dataSource numberOfRowsInPopoverPicker:self];
}

- (BOOL)canSelectRowAtIndex:(NSUInteger)index {
    if ([self.delegate respondsToSelector:@selector(popoverPicker:canSelectRowWithTitle:atIndex:)]) {
        return [self.delegate popoverPicker:self canSelectRowWithTitle:[self titleForRowAtIndex:index] atIndex:index];
    }
    return YES;
}

#pragma mark - Setter Override
- (void)setTitle:(NSString *)title {
    _title = [title copy];
    self.tableViewController.title = _title;
}

#pragma mark - Presentation and Dismissal
- (void)presentPopoverPickerFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated {
    [self presentPopover];
    [self.popoverController presentPopoverFromRect:rect inView:view permittedArrowDirections:arrowDirections animated:animated];
}

- (void)presentPopoverPickerFromPoint:(CGPoint)point inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated {
    [self presentPopoverPickerFromRect:CGRectMake(point.x, point.y, 1, 1) inView:view permittedArrowDirections:arrowDirections animated:animated];
}

- (void)presentPopoverPickerFromBarButtonItem:(UIBarButtonItem *)item permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated {
    [self presentPopover];
    [self.popoverController presentPopoverFromBarButtonItem:item permittedArrowDirections:arrowDirections animated:animated];
}

- (void)presentPopover {
    if ([self.delegate respondsToSelector:@selector(contentSizeForPopoverPicker:)]) {
        self.popoverController.popoverContentSize = [self.delegate contentSizeForPopoverPicker:self];
    } else {
        self.popoverController.popoverContentSize = [self intrinsicPopoverSize];
    }
    [self.tableViewController.tableView reloadData];
    [self processRowSelection];
}

- (void)dismissPopoverPickerAnimated:(BOOL)animated {
    [self.popoverController dismissPopoverAnimated:animated];
}

#pragma mark - Protocol: UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self numberOfRows];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:BRJPopoverPickerCellReuseIdentifier forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

#pragma mark - Protocol: UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndex = indexPath.row;
    if ([self.delegate respondsToSelector:@selector(popoverPicker:didSelectRowWithTitle:atIndex:)]) {
        NSString *title = [self titleForRowAtIndex:indexPath.row];
        [self.delegate popoverPicker:self didSelectRowWithTitle:title atIndex:indexPath.row];
    }
    [self dismissPopoverPickerAnimated:YES];
    if (!self.maintainSelection) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self canSelectRowAtIndex:indexPath.row] ? indexPath : nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return BRJPopoverPickerRowHeight;
}

/**
 * Returns a reasonable size for the popover that is at or near (w,h).
 * This size is used if the delegate does not specify a content size for the
 * popover.
 * 
 * @return A CGSize that represents a reasonable size for the popover.
 */
- (CGSize)intrinsicPopoverSize {
    CGFloat width = BRJPopoverPickerIntrinsicWidth;
    CGFloat navHeight = self.navigationController.toolbar.frame.size.height;
    CGFloat tableHeight = [self numberOfRows] * BRJPopoverPickerRowHeight;
    CGFloat height = MIN(BRJPopoverPickerIntrinsicHeight, navHeight + tableHeight);
    return CGSizeMake(width, height);
}

@end
