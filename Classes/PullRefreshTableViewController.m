//
//  PullRefreshTableViewController.m
//  Plancast
//
//  Created by Leah Culver on 7/2/10.
//  Copyright (c) 2010 Leah Culver
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import <QuartzCore/QuartzCore.h>
#import "PullRefreshTableViewController.h"

#define REFRESH_HEADER_HEIGHT 52.0f


@implementation PullRefreshTableViewController

@synthesize textPull = textPull_;
@synthesize textRelease = textRelease_;
@synthesize textLoading = textLoading_;
@synthesize refreshHeaderView = refreshHeaderView_;
@synthesize refreshLabel = refreshLabel_;
@synthesize refreshArrow = refreshArrow_;
@synthesize refreshSpinner = refreshSpinner_;
@synthesize tableView = _tableView;
@synthesize delegate = _delegate;

- (void)dealloc 
{
    self.refreshHeaderView = nil;
    self.refreshLabel = nil;
    self.refreshArrow = nil;
    self.refreshSpinner = nil;
    self.textPull = nil;
    self.textRelease = nil;
    self.textLoading = nil;
    
    [super dealloc];
}

- (void) awakeFromNib
{
    self.textPull = @"Pull down to refresh...";
    self.textRelease = @"Release to refresh...";
    self.textLoading = @"Loading...";
    
    [self addPullToRefreshHeader];
}

- (void)addPullToRefreshHeader 
{
    self.refreshHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0 - REFRESH_HEADER_HEIGHT, 320, REFRESH_HEADER_HEIGHT)] autorelease];
    self.refreshHeaderView.backgroundColor = [UIColor clearColor];

    self.refreshLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, REFRESH_HEADER_HEIGHT)] autorelease];
    self.refreshLabel.backgroundColor = [UIColor clearColor];
    self.refreshLabel.font = [UIFont boldSystemFontOfSize:12.0];
    self.refreshLabel.textAlignment = UITextAlignmentCenter;
    self.refreshLabel.textColor = [UIColor colorWithWhite:.1 alpha:1];

    self.refreshArrow = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow.png"]] autorelease];
    self.refreshArrow.frame = CGRectMake((REFRESH_HEADER_HEIGHT - 27) / 2,
                                    (REFRESH_HEADER_HEIGHT - 44) / 2,
                                    27, 44);

    self.refreshSpinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    self.refreshSpinner.frame = CGRectMake((REFRESH_HEADER_HEIGHT - 20) / 2, (REFRESH_HEADER_HEIGHT - 20) / 2, 20, 20);
    self.refreshSpinner.hidesWhenStopped = YES;

    [self.refreshHeaderView addSubview:self.refreshLabel];
    [self.refreshHeaderView addSubview:self.refreshArrow];
    [self.refreshHeaderView addSubview:self.refreshSpinner];
    [self.tableView addSubview:self.refreshHeaderView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView 
{
    if (isLoading) return;
    isDragging = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (isLoading) 
    {
        // Update the content inset, good for section headers
        if (scrollView.contentOffset.y > 0)
        {   
            self.tableView.contentInset = UIEdgeInsetsZero;
        }
        else if (scrollView.contentOffset.y >= -REFRESH_HEADER_HEIGHT)
        {   
            self.tableView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
        }
    } 
    else if (isDragging && scrollView.contentOffset.y < 0) 
    {
        // Update the arrow direction and label
        [UIView beginAnimations:nil context:NULL];
        if (scrollView.contentOffset.y < -REFRESH_HEADER_HEIGHT) 
        {
            // User is scrolling above the header
            self.refreshLabel.text = self.textRelease;
            [self.refreshArrow layer].transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
        } 
        else
        { // User is scrolling somewhere within the header
            self.refreshLabel.text = self.textPull;
            [self.refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
        }
        [UIView commitAnimations];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (isLoading) return;
    isDragging = NO;
    if (scrollView.contentOffset.y <= -REFRESH_HEADER_HEIGHT) 
    {
        // Released above the header
        [self startLoading];
    }
}

- (void)startLoading {
    isLoading = YES;

    // Show the header
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    
    self.tableView.contentInset = UIEdgeInsetsMake(REFRESH_HEADER_HEIGHT, 0, 0, 0);
    self.refreshLabel.text = self.textLoading;
    self.refreshArrow.hidden = YES;
    [self.refreshSpinner startAnimating];
    
    [UIView commitAnimations];

    // Refresh action!
    [self refresh];
}

- (void)stopLoading {
    isLoading = NO;

    // Hide the header
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDidStopSelector:@selector(stopLoadingComplete:finished:context:)];
    
    self.tableView.contentInset = UIEdgeInsetsZero;
    [self.refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
    
    [UIView commitAnimations];
}

- (void)stopLoadingComplete:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    // Reset the header
    self.refreshLabel.text = self.textPull;
    self.refreshArrow.hidden = NO;
    [self.refreshSpinner stopAnimating];
}

- (void)refresh 
{
    if ([self.delegate respondsToSelector:@selector(refresh)]) 
    {
        [self.delegate performSelector:@selector(refresh)];
    }
}

@end
