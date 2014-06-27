MOInfiniteScrollView
====================

An implementation of UIScrollView with an infinite content. Continues from where the Apple sample project [StreetScroller](https://developer.apple.com/library/ios/samplecode/StreetScroller/Introduction/Intro.html) left off.

Features
========
* Delegate pattern for content.
* Set the `contentOffset` for the scroll view.
* Reload the displayed views.
* Only horizontal scrolling supported.

Installation
============

For now, copy MOInfiniteScrollView.{h, m} into your project.

Usage
=====

Set up the data source either via Interface Builder or programmatically. Implement `viewForIndex:` to provide the view for given index and `sizeOfViewForIndex:` to provide the boundaries for the view. The latter is used for optimization when the `contentOffset` is set programmatically and not every view has to be created in between.