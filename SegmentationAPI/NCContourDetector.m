//
//  NCContourDetector.m
//  NoCrop
//
//  Created by Dey Device 6 on 19/3/24.
//

#import "NCContourDetector.h"

@implementation NCContourDetector

+ (instancetype)shared {
    static NCContourDetector *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NCContourDetector alloc] init];
    });
    return sharedInstance;
}

- (VNContoursObservation *)detectVisionContours:(UIImage *)image {
    CIImage *inputImage = [[CIImage alloc] initWithCGImage:image.CGImage];
    
    return [self detectVisionContours:image usingDarkOnLight:true];
}

- (VNContoursObservation *)detectVisionContours:(UIImage *)image usingDarkOnLight:(BOOL)darkOnLight
{
    CIImage *inputImage = [[CIImage alloc] initWithCGImage:image.CGImage];
    
    VNDetectContoursRequest *contourRequest = [[VNDetectContoursRequest alloc] init];
    contourRequest.revision = VNDetectContourRequestRevision1;
    contourRequest.contrastAdjustment = 1.0;
    contourRequest.detectsDarkOnLight = darkOnLight;
    contourRequest.maximumImageDimension = 512;
//    contourRequest.maximumImageDimension = 1024;
//    contourRequest.maximumImageDimension = 2048;
    
    VNImageRequestHandler *requestHandler = [[VNImageRequestHandler alloc] initWithCIImage:inputImage options:@{}];
    
    NSError *error;
    [requestHandler performRequests:@[contourRequest] error:&error];
    if (error) {
        NSLog(@"Error performing contour detection: %@", error);
        return nil;
    }
    
    VNContoursObservation *contoursObservation = [contourRequest.results firstObject];
    
    return contoursObservation;
}

@end
