/*
 Copyright (c) 2010 Robert Chin
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "RCSwitch.h"
#import <QuartzCore/QuartzCore.h>

@interface RCSwitch ()
- (void)regenerateImages;
- (void)performSwitchToPercent:(float)toPercent;
- (CGFloat)nonTextWidth;
@end

@implementation RCSwitch
@synthesize textPadding, onText, offText;

- (void)initCommon
{
	/* It seems that the animation length was changed in iOS 4.0 to animate the switch slower. */
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_4_0)
		animationDuration = 0.25;
	else
		animationDuration = 0.175;
	
	self.contentMode = UIViewContentModeRedraw;
	self.textPadding = 6.0;
	self.backgroundColor = [UIColor clearColor];
	[self setKnobWidth:44];
	[self regenerateImages];
	sliderOff = [[[UIImage imageNamed:@"btn_slider_off.png"] stretchableImageWithLeftCapWidth:12.0
																				 topCapHeight:0.0] retain];
	
	if([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
		scale = (double)[[UIScreen mainScreen] scale];
	else
		scale = 1.0;
	
	self.opaque = NO;
	
	//add the label work
	onTextLabel = [UILabel new];
	onTextLabel.text = NSLocalizedString(@"ON", @"Switch localized string");
	onTextLabel.textColor = [UIColor whiteColor];
	onTextLabel.font = [UIFont boldSystemFontOfSize:17];
	onTextLabel.shadowColor = [UIColor colorWithWhite:0.175 alpha:1.0];
	onTextLabel.textAlignment = UITextAlignmentCenter;
	onTextLabel.adjustsFontSizeToFitWidth = YES;
	onTextLabel.minimumFontSize = 10.0;
	
	offTextLabel = [UILabel new];
	offTextLabel.text = NSLocalizedString(@"OFF", @"Switch localized string");
	offTextLabel.textColor = [UIColor grayColor];
	offTextLabel.font = [UIFont boldSystemFontOfSize:17];
	offTextLabel.textAlignment = UITextAlignmentCenter;
	offTextLabel.adjustsFontSizeToFitWidth = YES;
	offTextLabel.minimumFontSize = 10.0;
}

- (id)initWithFrame:(CGRect)aRect
{
	if((self = [super initWithFrame:aRect]))
	{
		[self initCommon];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if((self = [super initWithCoder:aDecoder])){
		[self initCommon];
		percent = 1.0;
	}
	return self;
}

- (void)dealloc
{
	[knobImage release];
	[knobImagePressed release];
	[sliderOn release];
	[sliderOff release];
	[onText release];
	[offText release];
	[buttonEndTrack release];
	[buttonEndTrackPressed release];
	[super dealloc];
}

- (void)setKnobWidth:(float)aFloat
{
	knobWidth = roundf(aFloat); // whole pixels only
	endcapWidth = roundf(knobWidth / 2.0);
	
	{
		UIImage *knobTmpImage = [UIImage imageNamed:@"btn_slider_thumb.png"];
		UIImage *knobImageStretch = [knobTmpImage stretchableImageWithLeftCapWidth:12.0
																	  topCapHeight:0.0];
		CGRect knobRect = CGRectMake(0, 0, knobWidth, [knobImageStretch size].height);
		
		if(UIGraphicsBeginImageContextWithOptions != NULL)
			UIGraphicsBeginImageContextWithOptions(knobRect.size, NO, scale);
		else
			UIGraphicsBeginImageContext(knobRect.size);

		[knobImageStretch drawInRect:knobRect];
		[knobImage release];
		knobImage = [UIGraphicsGetImageFromCurrentImageContext() retain];
		UIGraphicsEndImageContext();	
	}
	
	{
		UIImage *knobTmpImage = [UIImage imageNamed:@"btn_slider_thumb_pressed.png"];
		UIImage *knobImageStretch = [knobTmpImage stretchableImageWithLeftCapWidth:12.0
																	  topCapHeight:0.0];
		CGRect knobRect = CGRectMake(0, 0, knobWidth, [knobImageStretch size].height);
		
		if(UIGraphicsBeginImageContextWithOptions != NULL)
			UIGraphicsBeginImageContextWithOptions(knobRect.size, NO, scale);
		else
			UIGraphicsBeginImageContext(knobRect.size);
		[knobImageStretch drawInRect:knobRect];
		[knobImagePressed release];
		knobImagePressed = [UIGraphicsGetImageFromCurrentImageContext() retain];
		UIGraphicsEndImageContext();	
	}
}

- (float)knobWidth
{
	return knobWidth;
}

- (void)regenerateImages
{
	CGRect boundsRect = self.bounds;
	UIImage *sliderOnBase = [[UIImage imageNamed:@"btn_slider_on.png"] stretchableImageWithLeftCapWidth:12.0
																						   topCapHeight:0.0];
	CGRect sliderOnRect = boundsRect;
	sliderOnRect.size.height = [sliderOnBase size].height;
	
	if(UIGraphicsBeginImageContextWithOptions != NULL)
		UIGraphicsBeginImageContextWithOptions(sliderOnRect.size, NO, scale);
	else
		UIGraphicsBeginImageContext(sliderOnRect.size);
	
	[sliderOnBase drawInRect:sliderOnRect];
	[sliderOn release];
	sliderOn = nil;
	sliderOn = [UIGraphicsGetImageFromCurrentImageContext() retain];
	UIGraphicsEndImageContext();
	
#if 0
	UIGraphicsBeginImageContext(sliderOnRect.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, sliderOnRect);
	[sliderOnBase drawInRect:sliderOnRect];
	CGContextSetBlendMode(context, kCGBlendModeOverlay);
	CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:1.0 green:127.0/255.0 blue:13.0/255.0 alpha:1.0] CGColor]);
	CGContextFillRect(context, sliderOnRect);
	CGContextSetBlendMode(context, kCGBlendModeDestinationAtop);
	CGContextDrawImage(context, sliderOnRect, [sliderOnBase CGImage]);
	[sliderOn release];
	sliderOn = nil;
	sliderOn = [UIGraphicsGetImageFromCurrentImageContext() retain];
	UIGraphicsEndImageContext();	
#endif
	
	{
		UIImage *buttonTmpImage = [UIImage imageNamed:@"btn_slider_track.png"];
		UIImage *buttonEndTrackBase = [buttonTmpImage stretchableImageWithLeftCapWidth:12.0
																		  topCapHeight:0.0];
		CGRect sliderOnRect = boundsRect;
		/* works around < 4.0 bug with not scaling height (see http://stackoverflow.com/questions/785986/resizing-an-image-with-stretchableimagewithleftcapwidth) */
		
		if(UIGraphicsBeginImageContextWithOptions != NULL)
			UIGraphicsBeginImageContextWithOptions(sliderOnRect.size, NO, scale);
		else
		{
			//CGSize testSize = sliderOnRect.size;
			UIGraphicsBeginImageContext(sliderOnRect.size);
		}
		[buttonEndTrackBase drawInRect:sliderOnRect];
		[buttonEndTrack release];
		buttonEndTrack = nil;
		buttonEndTrack = [UIGraphicsGetImageFromCurrentImageContext() retain];
		UIGraphicsEndImageContext();		
	}
	
	{
		UIImage *buttonTmpImage = [UIImage imageNamed:@"btn_slider_track_pressed.png"];
		UIImage *buttonEndTrackBase = [buttonTmpImage stretchableImageWithLeftCapWidth:12.0
																		  topCapHeight:0.0];
		CGRect sliderOnRect = boundsRect;
		if(UIGraphicsBeginImageContextWithOptions != NULL)
			UIGraphicsBeginImageContextWithOptions(sliderOnRect.size, NO, scale);
		else
			UIGraphicsBeginImageContext(sliderOnRect.size);		
		[buttonEndTrackBase drawInRect:sliderOnRect];
		[buttonEndTrackPressed release];
		buttonEndTrackPressed = nil;
		buttonEndTrackPressed = [UIGraphicsGetImageFromCurrentImageContext() retain];
		UIGraphicsEndImageContext();		
	}
}

- (void)drawUnderlayersInRect:(CGRect)aRect withOffset:(float)offset inTrackWidth:(float)trackWidth
{
	{
		CGRect textRect = aRect;
		textRect.origin.x += 6.0 + (offset - trackWidth);
		textRect.size.width = trackWidth - 6.0;
		[onTextLabel drawTextInRect:textRect];	
	}
	
	{
		CGRect textRect = aRect;
		textRect.origin.x += knobWidth + offset + 3.0;
		textRect.size.width = trackWidth - 9.0;
		[offTextLabel drawTextInRect:textRect];
	}
}

- (void)drawRect:(CGRect)rect
{
	CGRect boundsRect = self.bounds;
	if(!CGSizeEqualToSize(boundsRect.size, lastBoundsSize)){
		[self regenerateImages];
		lastBoundsSize = boundsRect.size;
	}
	
	float width = boundsRect.size.width;
	float drawPercent = percent;
	if(((width - knobWidth) * drawPercent) < 3)
		drawPercent = 0.0;
	if(((width - knobWidth) * drawPercent) > (width - knobWidth - 3))
		drawPercent = 1.0;
	
	if(endDate){
		NSTimeInterval interval = [endDate timeIntervalSinceNow];
		if(interval < 0.0){
			[endDate release];
			endDate = nil;
		} else {
			if(percent == 1.0)
				drawPercent = cosf((interval / animationDuration) * (M_PI / 2.0));
			else
				drawPercent = 1.0 - cosf((interval / animationDuration) * (M_PI / 2.0));
			[self performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:0.0];
		}
	}
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	{
		CGContextSaveGState(context);
		UIGraphicsPushContext(context);
		
		if(drawPercent == 0.0){
			CGRect insetClipRect = boundsRect;
			insetClipRect.origin.x += endcapWidth;
			insetClipRect.size.width -= endcapWidth;
			UIRectClip(insetClipRect);
		}
		
		if(drawPercent == 1.0){
			CGRect insetClipRect = boundsRect;
			insetClipRect.size.width -= endcapWidth;
			UIRectClip(insetClipRect);
		}
		
		{
			CGRect sliderOffRect = boundsRect;
			sliderOffRect.size.height = [sliderOff size].height;
			[sliderOff drawInRect:sliderOffRect];
		}
		
		if(drawPercent > 0.0){		
			float onWidth = 3 + (width - knobWidth + 3) * drawPercent;
			CGRect sourceRect = CGRectMake(0, 0, onWidth * scale, [sliderOn size].height * scale);
			CGRect drawOnRect = CGRectMake(0, 0, onWidth, [sliderOn size].height);
			CGImageRef sliderOnSubImage = CGImageCreateWithImageInRect([sliderOn CGImage], sourceRect);
			CGContextSaveGState(context);
			CGContextScaleCTM(context, 1.0, -1.0);
			CGContextTranslateCTM(context, 0.0, -boundsRect.size.height);	
			CGContextDrawImage(context, drawOnRect, sliderOnSubImage);
			CGContextRestoreGState(context);
			CGImageRelease(sliderOnSubImage);
		}
		
		{
			CGContextSaveGState(context);
			UIGraphicsPushContext(context);
			CGRect insetClipRect = CGRectInset(boundsRect, 4, 4);
			UIRectClip(insetClipRect);
			[self drawUnderlayersInRect:rect
							 withOffset:drawPercent * (boundsRect.size.width - knobWidth)
						   inTrackWidth:(boundsRect.size.width - knobWidth)];
			UIGraphicsPopContext();
			CGContextRestoreGState(context);
		}
		
		{
			CGContextScaleCTM(context, 1.0, -1.0);
			CGContextTranslateCTM(context, 0.0, -boundsRect.size.height);	
			CGPoint location = boundsRect.origin;
			UIImage *imageToDraw = knobImage;
			if(self.highlighted)
				imageToDraw = knobImagePressed;
			
			CGRect drawOnRect = CGRectMake(location.x - 1 + roundf(drawPercent * (boundsRect.size.width - knobWidth + 2)),
										   location.y, knobWidth, [knobImage size].height);
			CGContextDrawImage(context, drawOnRect, [imageToDraw CGImage]);
		}
		UIGraphicsPopContext();
		CGContextRestoreGState(context);
	}
	
	if(drawPercent == 0.0 || drawPercent == 1.0){
		CGContextSaveGState(context);
		CGContextScaleCTM(context, 1.0, -1.0);
		CGContextTranslateCTM(context, 0.0, -boundsRect.size.height - 1.0);	
		
		UIImage *buttonTrackDrawImage = buttonEndTrack;
		if(self.highlighted)
			buttonTrackDrawImage = buttonEndTrackPressed;
		
		if(drawPercent == 0.0){
			CGRect sourceRect = CGRectMake(0, 0.0, floorf(endcapWidth * scale), [buttonTrackDrawImage size].height * scale);
			CGRect drawOnRect = CGRectMake(0, 1.0, floorf(endcapWidth), [buttonTrackDrawImage size].height);
			CGImageRef buttonTrackSubImage = CGImageCreateWithImageInRect([buttonTrackDrawImage CGImage], sourceRect);
			CGContextDrawImage(context, drawOnRect, buttonTrackSubImage);
			CGImageRelease(buttonTrackSubImage);		
		}
		
		if(drawPercent == 1.0){
			CGRect sourceRect = CGRectMake(([buttonTrackDrawImage size].width - endcapWidth) * scale, 0.0, endcapWidth * scale, [buttonTrackDrawImage size].height * scale);
			CGRect drawOnRect = CGRectMake(boundsRect.size.width - ceilf(endcapWidth), 1.0, ceilf(endcapWidth), [buttonTrackDrawImage size].height);
			CGImageRef buttonTrackSubImage = CGImageCreateWithImageInRect([buttonTrackDrawImage CGImage], sourceRect);
			CGContextDrawImage(context, drawOnRect, buttonTrackSubImage);
			CGImageRelease(buttonTrackSubImage);
		}
		
		CGContextRestoreGState(context);
	}	
}

- (CGFloat)nonTextWidth;
{
	return knobWidth + endcapWidth/2;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	self.highlighted = YES;
	oldPercent = percent;
	[endDate release];
	endDate = nil;
	mustFlip = YES;
	[self setNeedsDisplay];
	[self sendActionsForControlEvents:UIControlEventTouchDown];
	return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint point = [touch locationInView:self];
	percent = (point.x - knobWidth / 2.0) / (self.bounds.size.width - knobWidth);
	float width = self.bounds.size.width;
	if(((width - knobWidth) * percent) > 3 || ((width - knobWidth) * percent) > (width - knobWidth - 3))
		mustFlip = NO;
	if(percent < 0.0)
		percent = 0.0;
	if(percent > 1.0)
		percent = 1.0;
	[self setNeedsDisplay];
	[self sendActionsForControlEvents:UIControlEventTouchDragInside];
	return YES;
}

- (void)finishEvent
{
	self.highlighted = NO;
	[endDate release];
	endDate = nil;
	float width = self.bounds.size.width;
	float toPercent = roundf(1.0 - oldPercent);
	if(!mustFlip){
		if(((width - knobWidth) * percent) < 3)
			toPercent = 0.0;
		if(((width - knobWidth) * percent) > (width - knobWidth - 3))
			toPercent = 1.0;
	}
	[self performSwitchToPercent:toPercent];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
	[self finishEvent];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self finishEvent];
}

- (BOOL)isOn
{
	return percent > 0.5;
}

- (void)setOn:(BOOL)aBool animated:(BOOL)animated
{
	if(animated){
		float toPercent = aBool ? 1.0 : 0.0;
		if(percent < 0.5 && aBool || percent > 0.5 && !aBool)
			[self performSwitchToPercent:toPercent];
	} else {
		percent = aBool ? 1.0 : 0.0;
		[self setNeedsDisplay];
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	}
}

- (void)setOn:(BOOL)aBool
{
	[self setOn:aBool animated:NO];
}

- (void)performSwitchToPercent:(float)toPercent
{
	[endDate release];
	endDate = nil;
	endDate = [[NSDate dateWithTimeIntervalSinceNow:fabsf(percent - toPercent) * animationDuration] retain];
	percent = toPercent;
	[self setNeedsDisplay];
	[self sendActionsForControlEvents:UIControlEventValueChanged];
	[self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (NSString *)onText
{
	return onTextLabel.text;
}

- (NSString *)offText
{
	return offTextLabel.text;
}

- (void)setOnText:(NSString *)text
{
	onTextLabel.text = text;
	[self regenerateImages];
}

- (void)setOffText:(NSString *)text
{
	offTextLabel.text = text;
	[self regenerateImages];
}

#pragma mark -
#pragma mark Autoresize
- (void)sizeToFit;
{
	NSString *onString = onTextLabel.text;
	NSString *offString = offTextLabel.text;
	
	CGFloat width = [onString sizeWithFont:onTextLabel.font].width;
	CGFloat offWidth = [offString sizeWithFont:offTextLabel.font].width;
	
	if(offWidth > width)
		width = offWidth;
	
	width += [self nonTextWidth];
	
	CGRect existingFrame = self.frame;
	CGFloat currentWidth = existingFrame.size.width;
	existingFrame.size.width = width;
	existingFrame.origin.x += currentWidth - width;
	[self setFrame:existingFrame];
	[self regenerateImages];
}

@end
