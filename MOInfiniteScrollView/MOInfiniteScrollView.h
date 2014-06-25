//
//  MOInfiniteScrollView.h
//
//  Created by Mikko Välimäki on 13-07-25.
//

#import <UIKit/UIKit.h>

@protocol MOInfiniteScrollViewDataSource

@required
- (UIView *)viewForIndex:(NSInteger)index;
- (CGSize)sizeOfViewForIndex:(NSInteger)index;

@end

@interface MOInfiniteScrollView : UIScrollView

@property (weak, nonatomic) IBOutlet id<MOInfiniteScrollViewDataSource> dataSource;
@property (strong, nonatomic, readonly) NSArray *visibleViews;

- (void)reloadViews;

@end
