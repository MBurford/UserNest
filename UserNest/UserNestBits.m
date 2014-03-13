//
//  UserNestBits.m
//  UserNestTestApp
//
//  Created by Michael Burford on 3/5/14.
//

#import "UserNestBits.h"
#import <Accelerate/Accelerate.h>
#import <float.h>


@implementation UserNestKeychain

+ (NSMutableDictionary *)newSearchDictionary:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
	
    [searchDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
	
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];
    [searchDictionary setObject:@"UserNest" forKey:(__bridge id)kSecAttrService];
	
    return searchDictionary;
}

+ (id)searchKeychainCopyMatching:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
	
    // Add search attributes
    [searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
	
    // Add search return types
    [searchDictionary setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
	
    CFTypeRef 		result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &result);
	if (status!=errSecSuccess) {
		NSLog(@"SecItemCopyMatching:%d", (int)status);
	}
	
    [searchDictionary release];
    return (__bridge id)(result);
}


+ (NSString*)stringForKey:(NSString*)key {
	NSData		*valueData = [self searchKeychainCopyMatching:key];
	NSString	*value = nil;
    if (valueData) {
        value = [[NSString alloc] initWithData:valueData encoding:NSUTF8StringEncoding];
        [valueData release];
    }
	return value;
}


+ (Boolean)setString:(NSString*)object forKey:(NSString*)key {
	//Setting to nil crashes, so change to blank string, so clears existing values
    if (object==nil) {
        object = @"";
    }
	OSStatus	status;
	id			existing = [UserNestKeychain searchKeychainCopyMatching:key];
	if (existing==nil) {
		NSMutableDictionary *dictionary = [self newSearchDictionary:key];
		
		NSData *objectData = [object dataUsingEncoding:NSUTF8StringEncoding];
		[dictionary setObject:objectData forKey:(__bridge id)kSecValueData];
		
#ifdef KEYCHAIN_EXTRASECURE
		[dictionary setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
#endif
		
		status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
		[dictionary release];
		
		if (status==errSecSuccess) {
			return YES;
		}
	} else {
		NSMutableDictionary *searchDictionary = [self newSearchDictionary:key];
		NSMutableDictionary *updateDictionary = [[NSMutableDictionary alloc] init];
		NSData *objectData = [object dataUsingEncoding:NSUTF8StringEncoding];
		[updateDictionary setObject:objectData forKey:(__bridge id)kSecValueData];
		
#ifdef KEYCHAIN_EXTRASECURE
		[searchDictionary setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
		[updateDictionary setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
#endif
		
		status = SecItemUpdate((__bridge CFDictionaryRef)searchDictionary, (__bridge CFDictionaryRef)updateDictionary);
		
		[searchDictionary release];
		[updateDictionary release];
		
		if (status==errSecSuccess) {
			return YES;
		}
	}
	NSLog(@"Error:SecItemAdd/Update:%d", (int)status);
	//return NO;
	return YES;
}

@end

/////////////////////////////////////////////////////////////////////////////////
//CODE FROM APPLE, for blurring...
//Plus a few other UIImage things too
@implementation UIImage (UserNest)

+ (UIImage*)userNestLeftButtonImage:(Boolean)selected {
    CGSize  size = CGSizeMake(50, 50);
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size.width, size.height), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (selected) {
        CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:0.0 alpha:0.5] CGColor]);
        CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    }
	
    CGContextSetLineWidth(context, 1);
    CGContextSetStrokeColorWithColor(context, [[UIColor grayColor] CGColor]);
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, size.width, 0);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
    //image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	return image;
}

+ (UIImage*)userNestRightButtonImage:(Boolean)selected {
    CGSize  size = CGSizeMake(50, 50);
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size.width, size.height), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (selected) {
        CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:0.0 alpha:0.5] CGColor]);
        CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    }
    
    CGContextSetLineWidth(context, 1);
    CGContextSetStrokeColorWithColor(context, [[UIColor grayColor] CGColor]);
    CGContextMoveToPoint(context, 0, size.height);
    CGContextAddLineToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, size.width, 0);
    CGContextStrokePath(context);
	
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
    //image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	return image;
}


- (UIImage *)userNestApplyGrayEffect {
    UIColor *tintColor = [UIColor colorWithWhite:0.15 alpha:0.75];
    return [self userNestApplyBlurWithRadius:6 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];
}

- (UIImage *)userNestApplyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage
{
    // Check pre-conditions.
    if (self.size.width < 1 || self.size.height < 1) {
        NSLog (@"*** error: invalid size: (%.2f x %.2f). Both dimensions must be >= 1: %@", self.size.width, self.size.height, self);
        return nil;
    }
    if (!self.CGImage) {
        NSLog (@"*** error: image must be backed by a CGImage: %@", self);
        return nil;
    }
    if (maskImage && !maskImage.CGImage) {
        NSLog (@"*** error: maskImage must be backed by a CGImage: %@", maskImage);
        return nil;
    }
	
    CGRect imageRect = { CGPointZero, self.size };
    UIImage *effectImage = self;
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -self.size.height);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage);
		
        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
		
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
		
        if (hasBlur) {
            // A description of how to compute the box kernel width from the Gaussian
            // radius (aka standard deviation) appears in the SVG spec:
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            //
            // For larger values of 's' (s >= 2.0), an approximation can be used: Three
            // successive box-blurs build a piece-wise quadratic convolution kernel, which
            // approximates the Gaussian kernel to within roughly 3%.
            //
            // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
            //
            // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
            //
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            NSUInteger radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1; // force radius to be odd so that the three box-blur methodology works.
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
				0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped)
		effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
		
        if (effectImageBuffersAreSwapped)
		effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
	
    // Set up output context.
    UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.size.height);
	
    // Draw base image.
    CGContextDrawImage(outputContext, imageRect, self.CGImage);
	
    // Draw effect image.
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
	
    // Add in color tint.
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
	
    // Output image is ready.
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
    return outputImage;
}

@end
