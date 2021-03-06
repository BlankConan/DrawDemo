
//
//  Gradient.m
//  DrawDemoTest
//
//  Created by liugangyi on 2017/5/4.
//  Copyright © 2017年 com.allinmd.cn. All rights reserved.
//

#import "Gradient.h"

@implementation Gradient

- (CGGradientRef)gradient {
    
    return _gradient;
}

+ (instancetype)gradientWithColors:(NSArray *)colorsArray locations:(NSArray *)locationArray {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL) {
        NSLog(@"Error：Unable to create RGB color space");
        return nil;
    }
    // Convert NSNumber *locations array to CGFloat *
    CGFloat locations[locationArray.count];
    for (int i = 0; i < locationArray.count; i++)
        locations[i] = fminf(fmaxf([locationArray[i] floatValue], 0), 1);
    
    // Convert colors array to (id) CGColorRef
    NSMutableArray *colorRefArray = [NSMutableArray array];
    for (UIColor *color in colorsArray)
        [colorRefArray addObject:(id)color.CGColor];
    
    // Build the internal gradient
    CGGradientRef gradientRef = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colorRefArray, locations);
    CGColorSpaceRelease(colorSpace);
    if (gradientRef == NULL) {
        NSLog(@"Error：Unable to create CGGradientRef");
        return nil;
    }
    
    // Build the wrapper, store the gradient , and return
    Gradient *gradient = [[self alloc] init];
    gradient.gradient = gradientRef;
    CGGradientRelease(gradientRef);
    
    return gradient;
}

+ (instancetype)gradientColorFrom:(UIColor *)color1 to:(UIColor *)color2 {
    
    return [self gradientWithColors:@[color1,color2] locations:@[@0 , @1]];
}

- (void)drawLinerFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint {
    [self drawLinerFromPoint:startPoint toPoint:endPoint style:0];
}

- (void)drawLinerFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint style:(int)mask {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (context == NULL) {
        NSLog(@"Error：NO context to draw");
        return;
    }
    
    CGContextDrawLinearGradient(context, [self gradient], startPoint, endPoint, mask);
}

- (void)drawRadialFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint raidus:(CGPoint)radiusPoint style:(int)mask {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (context == NULL) {
        NSLog(@"Error：NO context to draw");
        return;
    }
    
    CGContextDrawRadialGradient(context, [self gradient], startPoint, radiusPoint.x, endPoint, radiusPoint.y, mask);
}

+ (Gradient *)gradientUsingInterpolationBlock:(InterpolationBlock)block betweenColor:(UIColor *)color1 andColor:(UIColor *)color2 {
    
    if (!block) {
        NSLog(@"No interpolate block");
        return nil;
    }
    
    NSMutableArray *colorsArray = [NSMutableArray array];
    NSMutableArray *locationsArray = [NSMutableArray array];
    
    int numberOfSample = 24;
    for (int i = 0; i <= numberOfSample ; i++) {
        
        CGFloat amt = (CGFloat)i / (CGFloat)numberOfSample;
        CGFloat percent = fmin(fmax(0.0, block(amt)), 1);
        [colorsArray addObject:InterploateBetweenColors(color1, color2, percent)];
        [locationsArray addObject:@(amt)];
    }
    
    return [Gradient gradientWithColors:colorsArray locations:locationsArray];
}


- (void)drawBottomToTop:(CGRect)rect {
    
    CGPoint startPoint = (CGPoint){rect.origin.x + rect.size.width/2.0 , rect.origin.y + rect.size.height};
    CGPoint endPoint = {rect.origin.x + rect.size.width/2.0 , rect.origin.y};;
    
    [self drawLinerFromPoint:startPoint toPoint:endPoint];
}

- (void)drawTopToBottom:(CGRect)rect {
    
    CGPoint startPoint = {rect.origin.x + rect.size.width/2.0 , rect.origin.y};;
    CGPoint endPoint = (CGPoint){rect.origin.x + rect.size.width/2.0 , rect.origin.y + rect.size.height};
    
    [self drawLinerFromPoint:startPoint toPoint:endPoint];
    
}


@end


UIColor *InterploateBetweenColors(UIColor *color1 , UIColor *color2 ,CGFloat amt) {
    
    CGFloat r1 ,g1 ,b1 ,a1;
    CGFloat r2 ,g2 ,b2 ,a2;
    
    if (CGColorGetNumberOfComponents(color1.CGColor) == 4) {
        [color1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    } else {
        [color1 getWhite:&r1 alpha:&a1];
        g1 = r1;
        b1 = r1;
    }
    if (CGColorGetNumberOfComponents(color2.CGColor) == 4) {
        [color2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    } else {
        [color2 getWhite:&r2 alpha:&a2];
        g2 = r2;
        b2 = r2;
    }
    
    CGFloat r = (r2 * amt) + (r1 * (1.0 - amt));
    CGFloat g = (g2 * amt) + (g1 * (1.0 - amt));
    CGFloat b = (b2 * amt) + (b1 * (1.0 - amt));
    CGFloat a = (a2 * amt) + (a1 * (1.0 - amt));
    
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

#pragma mark - Easing Functions
// Ease only the begin (factor 指数 1/2/3)
CGFloat EaseIn(CGFloat currentTime , int factor) {
    return powf(currentTime, factor);
}

// Ease only the end
CGFloat EaseOut(CGFloat currentTime , int factor) {
    return 1 - powf((1 - currentTime), factor);
}

// Ease both beginning and end
CGFloat EaseInOut(CGFloat currentTime, int factor) {
    
    currentTime = currentTime * 2.0;
    if (currentTime < 1)
        return (0.5 * pow(currentTime, factor));
    
    currentTime -= 2.0;
    if (factor % 2)
        return 0.5 * (pow(currentTime, factor) + 2.0);
    return 0.5 * (2.0 - pow(currentTime, factor));

}

UIColor * ScaleColorBrightness(UIColor *color , CGFloat amount) {
    
    if (!color) {
        return [UIColor blackColor];
    }
    
    CGFloat h ,s ,v ,a;
    [color getHue:&h saturation:&s brightness:&v alpha:&a];
    CGFloat v1 = fmaxf(fminf(v * amount, 1), 0);
    
    return [UIColor colorWithHue:h saturation:s brightness:v1 alpha:a];
}

void DrawStrokedShadowedShape(UIBezierPath *path, UIColor *baseColor, CGRect dest) {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        NSLog(@"Error：No context to draw to");
        return;
    }
    
    PushDraw(^{
        CGContextSetShadow(context, CGSizeMake(4,4), 4);
        // Draw letter gradient (to half brighness)
        PushLayerDraw(^{
            Gradient *gradient = [Gradient gradientColorFrom:baseColor to:ScaleColorBrightness(baseColor, .5)];
            [path addClip];
            [gradient drawTopToBottom:path.bounds];
            
            
            // Add the inner shadow with dark color
            PushDraw(^{
                CGContextSetBlendMode(context, kCGBlendModeMultiply);
                DrawInnerShadow(path, ScaleColorBrightness(baseColor, 0.3), CGSizeMake(0, -2), 2);
            });
            
            // Stroke with reversed gray gadient
            PushDraw(^{
                [path clipToStroke:6];
                [path.inverse addClip];
                Gradient *grayGradient = [Gradient gradientColorFrom:White_Levels(0, 1) to:White_Levels(0.5, 1)];
                [grayGradient drawTopToBottom:dest];
            });
            
        });
       
    });

}

void DrawGradientOverTexture(UIBezierPath *path, UIImage *texture, Gradient *gradient, CGFloat alpha) {
    
    if (!path || !texture || !gradient ) {
        NSLog(@"Error： Param error");
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (context == NULL) { NSLog(@"Error: No Context to Draw");return;}
        
    CGRect rect = path.bounds; PushDraw(^{
        CGContextSetAlpha(context, alpha); [path addClip];
        PushLayerDraw(^{
            [texture drawInRect:rect]; CGContextSetBlendMode(
                                                             context, kCGBlendModeColor); [gradient drawTopToBottom:rect];
        }); });
    
}









