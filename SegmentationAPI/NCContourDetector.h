//
//  NCContourDetector.h
//  NoCrop
//
//  Created by Dey Device 6 on 19/3/24.
//

#import <Foundation/Foundation.h>
#import <Vision/Vision.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface NCContourDetector : NSObject

+ (instancetype)shared;
- (VNContoursObservation *)detectVisionContours:(UIImage *)image;
- (VNContoursObservation *)detectVisionContours:(UIImage *)image usingDarkOnLight:(BOOL)darkOnLight;
@end

NS_ASSUME_NONNULL_END
