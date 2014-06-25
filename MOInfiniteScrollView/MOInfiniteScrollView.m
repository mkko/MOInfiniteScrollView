//
//  MOInfiniteScrollView.m
//
//  Created by Mikko Välimäki on 13-07-25.
//

#import "MOInfiniteScrollView.h"

@interface MOInfiniteScrollView () <UIScrollViewDelegate>
{
    UIScrollView *_scrollView;
    NSMutableArray *_visibleViews;
    UIView *_containerView;
    NSInteger _leftIndex;
    CGPoint _contentOffsetOffset;
    
    BOOL _updatingLayout;
}

@end

@implementation MOInfiniteScrollView

- (instancetype)init
{
    if (self = [super init])
    {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _updatingLayout = NO;
    
    _visibleViews = [[NSMutableArray alloc] init];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    _scrollView.contentSize = CGSizeMake(5000, self.frame.size.height);
    _scrollView.delegate = self;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:_scrollView];
    
    _containerView = [[UIView alloc] init];
    _containerView.frame = CGRectMake(0, 0, _scrollView.contentSize.width, _scrollView.contentSize.height);
    [_scrollView addSubview:_containerView];
    
    [_containerView setUserInteractionEnabled:NO];
    
    // Hide horizontal scroll indicator so our recentering trick is not revealed
    [self setShowsHorizontalScrollIndicator:YES];
}

- (NSArray *)visibleViews
{
    return [NSArray arrayWithArray:_visibleViews];
}

- (NSInteger)indexOfView:(UIView *)view
{
    NSUInteger i = [_visibleViews indexOfObject:view];
    if (i != NSNotFound)
    {
        return _leftIndex + ((NSInteger)i);
    }
    return NSNotFound;
}

- (void)reloadViews
{
    for (UIView *v in _visibleViews)
    {
        NSInteger i = [self indexOfView:v];
        UIView *view = [_dataSource viewForIndex:i];
        CGRect frame = view.frame;
        frame.origin = v.frame.origin;
        view.frame = frame;
        [_containerView addSubview:view];
        [v removeFromSuperview];
    }
}

#pragma UIScrollView overrides

- (CGPoint)contentOffset
{
    return (CGPoint) {
        .x = _scrollView.contentOffset.x - _contentOffsetOffset.x,
        .y = _scrollView.contentOffset.y - _contentOffsetOffset.y,
    };
}

- (void)setContentOffset:(CGPoint)contentOffset
{
    // Stop animating (if scrolling).
    [_scrollView setContentOffset:_scrollView.contentOffset animated:NO];
    
    CGPoint currentOffset = self.contentOffset;
    if (CGPointEqualToPoint(currentOffset, contentOffset)) return;
    
    CGPoint delta = (CGPoint) {
        .x = contentOffset.x - currentOffset.x,
        .y = contentOffset.y - currentOffset.y,
    };
    
    // Calculate some fixed point within the new offset.
    
    NSInteger direction = (delta.x < 0 ? -1 : 1);
    CGFloat jumpX = 0;
    NSInteger n = 0;
    
    CGRect leftmostFrame = [[_visibleViews firstObject] frame];
    CGRect rightmostFrame = [[_visibleViews lastObject] frame];
    CGFloat leftPoint = CGRectGetMinX([_containerView convertRect:leftmostFrame toView:_scrollView]);
    CGFloat rightPoint = CGRectGetMaxX([_containerView convertRect:rightmostFrame toView:_scrollView]);
    
    leftPoint -= (_scrollView.contentOffset.x + CGRectGetWidth(_scrollView.bounds));
    rightPoint -= _scrollView.contentOffset.x;
    // The covered area is the loaded views. We start adding the new views next to the
    // covered area until we reach the first view that will be visible.
    CGFloat covered = abs(direction < 0 ? leftPoint : rightPoint);
    
    CGSize s = [self.dataSource sizeOfViewForIndex:(_leftIndex + [_visibleViews count])];
    while (abs(delta.x) - covered > (jumpX + s.width))
    {
        jumpX += s.width;
        n += direction;
        s = [self.dataSource sizeOfViewForIndex:(_leftIndex + [_visibleViews count] + n)];
    }
    
    // Fake the left index so that the views are consecutive.
    _leftIndex += n;
    
    // Take a shortcut.
    delta.x -= jumpX * direction;
    _contentOffsetOffset.x -= jumpX * direction;
    
    CGPoint co = _scrollView.contentOffset;
    co.x += delta.x;
    _scrollView.contentOffset = co;
}

#pragma mark Layout

// Recenter content periodically to achieve impression of infinite scrolling
- (void)recenterIfNecessary
{
    CGPoint currentOffset = [_scrollView contentOffset];
    CGFloat contentWidth = [_scrollView contentSize].width;
    CGFloat centerOffsetX = (contentWidth - [_scrollView bounds].size.width) / 2.0;
    CGFloat distanceFromCenter = fabs(currentOffset.x - centerOffsetX);
    
    if (distanceFromCenter > (contentWidth / 4.0))
    {
        _scrollView.contentOffset = CGPointMake(centerOffsetX, currentOffset.y);
        
        CGFloat delta = (centerOffsetX - currentOffset.x);
        _contentOffsetOffset.x += delta;
        
        // Move content by the same amount so it appears to stay still
        for (UIView *view in _visibleViews)
        {
            CGPoint center = [_containerView convertPoint:view.center toView:_scrollView];
            center.x += delta;
            view.center = [_scrollView convertPoint:center toView:_containerView];
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _scrollView.frame = self.bounds;
    
    [self updateLayout];
}

- (void)updateLayout
{
    if (_updatingLayout) return;
    _updatingLayout = YES;
    
    [self recenterIfNecessary];
    
    // tile content in visible bounds
    CGRect visibleBounds = [_scrollView convertRect:[_scrollView bounds] toView:_containerView];
    CGFloat minimumVisibleX = CGRectGetMinX(visibleBounds);
    CGFloat maximumVisibleX = CGRectGetMaxX(visibleBounds);
    
    [self tileViewsFromMinX:minimumVisibleX toMaxX:maximumVisibleX];
    
    _updatingLayout = NO;
}

#pragma mark View tiling

- (CGRect)placeViewOnLeft
{
    return [self placeViewAt:_leftIndex - 1];
}

- (CGRect)placeViewOnRight
{
    return [self placeViewAt:_leftIndex + [_visibleViews count]];
}

- (CGRect)placeViewAt:(NSInteger)index
{
    UIView *view = [self.dataSource viewForIndex:index];
    CGRect frame = [view frame];
    if (index == _leftIndex - 1)
    {
        // Adding a new view to the left side.
        _leftIndex--;
        CGFloat leftEdge = CGRectGetMinX([[_visibleViews firstObject] frame]);
        frame.origin.x = leftEdge - frame.size.width;
        [_visibleViews insertObject:view atIndex:0];
    }
    else if ([_visibleViews count] > 0 && index == _leftIndex + [_visibleViews count])
    {
        // Adding a new view to the right side.
        CGFloat rightEdge = CGRectGetMaxX([[_visibleViews lastObject] frame]);
        frame.origin.x = rightEdge;
        [_visibleViews addObject:view];
    }
    else if ([_visibleViews count] == 0)
    {
        // Initial view.
        
        CGRect visibleBounds = [_scrollView convertRect:[_scrollView bounds] toView:_containerView];
        CGFloat minimumVisibleX = CGRectGetMinX(visibleBounds);
        CGFloat rightEdge = minimumVisibleX;
        frame.origin.x = rightEdge;
        [_visibleViews addObject:view];
    }
    else
    {
        NSLog(@"Well this was unexpected. Please fix the code.");
        abort();
    }
    
    view.frame = frame;
    [_containerView addSubview:view];
    return frame;
}

- (void)tileViewsFromMinX:(CGFloat)minimumVisibleX toMaxX:(CGFloat)maximumVisibleX
{
    // We need at least one view.
    if ([_visibleViews count] == 0)
    {
        [self placeViewAt:_leftIndex];
    }
    
    UIView *lastView = [_visibleViews lastObject];
    CGFloat rightEdge = CGRectGetMaxX([lastView frame]);
    while (rightEdge < maximumVisibleX)
    {
        rightEdge = CGRectGetMaxX([self placeViewOnRight]);
    }
    
    UIView *firstView = [_visibleViews firstObject];
    CGFloat leftEdge = CGRectGetMinX([firstView frame]);
    while (leftEdge > minimumVisibleX)
    {
        leftEdge = CGRectGetMinX([self placeViewOnLeft]);
    }
    
    while ([[_visibleViews lastObject] frame].origin.x > maximumVisibleX)
    {
        [self dropRightmostView];
    }
    
    while (CGRectGetMaxX([[_visibleViews firstObject] frame]) < minimumVisibleX)
    {
        [self dropLeftmostView];
    }
}

- (void)dropLeftmostView
{
    UIView *leftmostView = [_visibleViews firstObject];
    if (leftmostView)
    {
        [leftmostView removeFromSuperview];
        [_visibleViews removeObjectAtIndex:0];
        _leftIndex++;
    }
}

- (void)dropRightmostView
{
    UIView *rightmostView = [_visibleViews lastObject];
    [rightmostView removeFromSuperview];
    [_visibleViews removeLastObject];
}

#pragma UIScrollViewDelegate implementation

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateLayout];
    if ([self.delegate respondsToSelector:@selector(scrollViewDidScroll:)])
    {
        [self.delegate scrollViewDidScroll:self];
    }
}

//- (void)scrollViewDidZoom:(UIScrollView *)scrollView
//{
//
//}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)])
    {
        [self.delegate scrollViewWillBeginDragging:self];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if ([self.delegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)])
    {
        [self.delegate scrollViewWillEndDragging:self withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)])
    {
        [self.delegate scrollViewDidEndDragging:self willDecelerate:decelerate];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)])
    {
        [self.delegate scrollViewWillBeginDecelerating:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)])
    {
        [self.delegate scrollViewDidEndDecelerating:self];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)])
    {
        [self.delegate scrollViewDidEndScrollingAnimation:self];
    }
}

/*
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{

}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{

}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{

}
*/

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)])
    {
        return [self.delegate scrollViewShouldScrollToTop:self];
    }
    return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(scrollViewDidScrollToTop:)])
    {
        [self.delegate scrollViewDidScrollToTop:self];
    }
}

@end
