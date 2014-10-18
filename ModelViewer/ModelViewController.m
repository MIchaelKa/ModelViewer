//
//  ModelViewController.m
//  ModelViewer
//
//  Created by Michael Kalinin on 18/10/14.
//  Copyright (c) 2014 Michael. All rights reserved.
//

#import "ModelViewController.h"

#include "icosphere.h"

@interface ModelViewController()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *baseEffect;

@property (nonatomic) GLKMatrix4 savedModelViewMatrix;

@property (nonatomic) CGPoint startPanningPoint;

@property (nonatomic) float rotationValueAxisX;
@property (nonatomic) float rotationValueAxisY;
@property (nonatomic) float rotationValueAxisZ;

@property (nonatomic) CGFloat scale;

@end

@implementation ModelViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupGL];
    [self setupBaseEffect];
    
    self.rotationValueAxisX = 0.0;
    self.rotationValueAxisY = 0.0;
    self.rotationValueAxisZ = 0.0;
    
    self.scale = 1.0;
    
    self.savedModelViewMatrix = GLKMatrix4MakeScale(1.0, 1.0, 1.0);
}

- (void)setupGL
{
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context)
    {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    view.context = self.context;
    
    [EAGLContext setCurrentContext: self.context];
    
    glClearColor(210.0/255.0, 219.0/255.0, 242.0/255.0, 1.0);
    glEnable(GL_DEPTH_TEST);
}

- (void)setupBaseEffect
{
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.light0.enabled = GL_TRUE;
    self.baseEffect.light0.position = GLKVector4Make(0.0f, 0.0f, -1.0f, 0.0f);
    self.baseEffect.lightingType = GLKLightingTypePerPixel;
}

- (void)applyScaling
{
    GLKView *view = (GLKView *)self.view;
    GLfloat aspectRatio = (GLfloat)view.drawableWidth / (GLfloat)view.drawableHeight;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeScale(1.0f, aspectRatio, 1.0f);
    
    self.baseEffect.transform.modelviewMatrix =
        GLKMatrix4Multiply(modelViewMatrix, self.savedModelViewMatrix);
}

- (void)applyUserRotation
{
    GLKMatrix4 currentModelViewMatrix = self.baseEffect.transform.modelviewMatrix;
    GLKMatrix4 modelViewMatrix = [self makeRotationMatrix];
    
    self.baseEffect.transform.modelviewMatrix =
        GLKMatrix4Multiply(currentModelViewMatrix, modelViewMatrix);
}

- (void)applyUserScaling
{
    GLKMatrix4 currentModelViewMatrix = self.baseEffect.transform.modelviewMatrix;
    GLKMatrix4 modelViewMatrix = [self makeScaleMatrix];
    
    self.baseEffect.transform.modelviewMatrix =
        GLKMatrix4Multiply(currentModelViewMatrix, modelViewMatrix);
}

- (GLKMatrix4)makeRotationMatrix
{
    GLKMatrix4 rotationMatrix;
    
    rotationMatrix = GLKMatrix4MakeRotation(
        GLKMathDegreesToRadians(360.0 * self.rotationValueAxisX),
        1.0f, 0.0f, 0.0f); // x, y, z
    
    rotationMatrix = GLKMatrix4Rotate(
        rotationMatrix,
        GLKMathDegreesToRadians(360.0 * self.rotationValueAxisY),
        0.0f, 1.0f, 0.0f); // x, y, z
    
    rotationMatrix = GLKMatrix4Rotate(
        rotationMatrix,
        GLKMathDegreesToRadians(360.0 * self.rotationValueAxisZ),
        0.0f, 0.0f, 1.0f); // x, y, z
    
    return rotationMatrix;
}

- (GLKMatrix4)makeScaleMatrix
{
    return GLKMatrix4MakeScale(self.scale, self.scale, self.scale);
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.baseEffect prepareToDraw];
    
    [self applyScaling];
    [self applyUserRotation];
    [self applyUserScaling];
    
    // Positions
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, icospherePositions);
    
    // Normals
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, icosphereNormals);
    
    
    glDrawArrays(GL_TRIANGLES, 0, icosphereVertices);
}

- (IBAction)pan:(UIPanGestureRecognizer *)sender
{
    CGPoint gesturePoint = [sender locationInView: self.view];
    
    switch (sender.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            self.startPanningPoint = gesturePoint;
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            [self setUserRotation: gesturePoint];
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            [self setUserRotation: gesturePoint];
            self.savedModelViewMatrix = GLKMatrix4Multiply(self.savedModelViewMatrix,
                                                           [self makeRotationMatrix]);
            self.rotationValueAxisX = 0.0;
            self.rotationValueAxisY = 0.0;
            self.rotationValueAxisZ = 0.0;
            break;
        }
        default:
        {
            break;
        }
    }
}

- (void) setUserRotation: (CGPoint)endPanningPoint
{
    CGFloat width  = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    
    self.rotationValueAxisX = -(endPanningPoint.y - self.startPanningPoint.y) / height;
    self.rotationValueAxisY = -(endPanningPoint.x - self.startPanningPoint.x) / width;
}

- (IBAction)pinch:(UIPinchGestureRecognizer *)sender
{
    switch (sender.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            self.scale = sender.scale;
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            self.scale = sender.scale;
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            self.scale = sender.scale;
            self.savedModelViewMatrix = GLKMatrix4Multiply(self.savedModelViewMatrix,
                                                           [self makeScaleMatrix]);
            self.scale = 1.0;
            break;
        }
        default:
        {
            break;
        }
    }
}

@end
