//
//  ViewController.m
//  MOInfiniteScrollView
//
//  Created by Mikko Välimäki on 14-06-25.
//  Copyright (c) 2014 Bitwise. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet MOInfiniteScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIView *)viewForIndex:(NSInteger)index
{
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 180, 240)];
    lbl.font = [UIFont boldSystemFontOfSize:120];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.adjustsFontSizeToFitWidth = YES;
    lbl.text = [@(index) stringValue];
    lbl.backgroundColor = [UIColor colorWithHue:(abs((int)index)%32)/31.0
                                     saturation:1 brightness:1 alpha:1];
    return lbl;
}

- (CGSize)sizeOfViewForIndex:(NSInteger)index
{
    return CGSizeMake(180, 240);
}

- (void)scrollViewDidScroll:(MOInfiniteScrollView *)scrollView
{
    _label.text = [NSString stringWithFormat:@"%f", scrollView.contentOffset.x];
}

- (IBAction)updated:(UISlider *)sender
{
    _scrollView.contentOffset = (CGPoint) { .x = sender.value, .y = _scrollView.contentOffset.y };
}

- (IBAction)jumpToZero:(id)sender
{
    [UIView animateWithDuration:0.2 animations:^{
        _scrollView.contentOffset = (CGPoint) { .x = 0, .y = _scrollView.contentOffset.y };
    }];
}

- (IBAction)reload:(id)sender
{
    [_scrollView reloadViews];
}

@end
