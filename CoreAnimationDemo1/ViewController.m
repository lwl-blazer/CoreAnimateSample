//
//  ViewController.m
//  CoreAnimationDemo1
//
//  Created by blazer on 16/8/26.
//  Copyright © 2016年 blazer. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property(nonatomic, strong) CAShapeLayer *shapeLayer;

@property(nonatomic, strong) CAShapeLayer *leftLayer;
@property(nonatomic, strong) CAShapeLayer *centerLayer;
@property(nonatomic, strong) CAShapeLayer *rightLayer;
@property(nonatomic, strong) CAShapeLayer *fluctLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
#if 0 //隐式动画绘制环
    self.shapeLayer = [CAShapeLayer layer];
    self.shapeLayer.strokeEnd = 0;    //填充的百分比
    self.shapeLayer.lineWidth = 6;
    self.shapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.shapeLayer.strokeColor = [UIColor redColor].CGColor;
    
    //阴影
    self.shapeLayer.shadowColor = [UIColor grayColor].CGColor;  //颜色
    self.shapeLayer.shadowOffset = CGSizeMake(2.0, 5.0);  //阴影偏移 x向右偏移 y向下偏移  这个跟shadowRadius配合使用
    self.shapeLayer.shadowOpacity = 1;   //阴影透明度 默认0
    self.shapeLayer.shadowRadius = 5;  //阴影半径 默认3
    
    [self.view.layer addSublayer:self.shapeLayer];
#endif
    
    self.fluctLayer = [CAShapeLayer layer];
    self.centerLayer = [CAShapeLayer layer];
    self.leftLayer = [CAShapeLayer layer];
    self.rightLayer = [CAShapeLayer layer];
    
    self.fluctLayer.fillColor = [UIColor greenColor].CGColor;
    self.leftLayer.frame = CGRectMake(0, 0, 1, 1);
    self.rightLayer.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 1, 0, 1, 1);
    self.centerLayer.frame = CGRectMake([UIScreen mainScreen].bounds.size.width / 2, 0, 5, 5);
    self.centerLayer.fillColor = [UIColor redColor].CGColor;
    
    [self.view.layer addSublayer:self.leftLayer];
    [self.view.layer addSublayer:self.centerLayer];
    [self.view.layer addSublayer:self.rightLayer];
    [self.view.layer addSublayer:self.fluctLayer];
    
    UIButton *animate = [UIButton buttonWithType:UIButtonTypeSystem];
    [animate setTitle:@"Animate" forState:UIControlStateNormal];
    animate.frame = CGRectMake(100, CGRectGetHeight(self.view.frame) - 40, 100, 20);
    [animate addTarget:self action:@selector(animateClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:animate];
}

- (void)animateClick{
#if  0     //隐式动画绘制环
    self.shapeLayer.path = [UIBezierPath bezierPathWithArcCenter:self.view.center radius:100 startAngle:0 endAngle:2 *M_PI clockwise:YES].CGPath;
    self.shapeLayer.strokeEnd = 1;
#endif
    
    /*
     * CADisplayLink 是一个能让我们以和屏幕刷新率相同的频率将内容画到屏幕上的定时器
     * 当绑定好了target后，这时target可以读到CADisplayLink的每次调用的时间戳，用来准备下一帧显示需要的数据
     * NSTimer和CADisplayLink有什么不同
     *   iOS设置屏幕刷新频率是固定的，CADisplayLink在正常情况下会在每次刷新结束都被调用，精确度相当高
     *   NSTimer的精确度就显得低了点，比如NSTimer的触发时间到的时候，runloop如果在阻塞状态，触发时间就会推迟到下一个runloop周期。并且NSTimer新增了tolerance属性，让用户可以设置可以容忍的触发的时间的延迟范围
     *   CADisplayLine使用场合相对专一，适合做UI不停重绘，比如自定义动画引擎或者视频播放的渲染。NSTimer的使用范围要广泛的多，各种需要单次或者循环定时处理的任务都可以使用。在UI相关的动画或者显示内容使用CADisplayLink比起用NSTimer的好处就是我们不需要在格外关心屏幕刷新频率上。因为它本身就是跟屏幕刷新同步的
     */
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(fluctLayerAnimate)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    CABasicAnimation *move = [CABasicAnimation animationWithKeyPath:@"position.y"];
    move.toValue = [NSNumber numberWithFloat:160.0];

    self.leftLayer.position = CGPointMake(self.leftLayer.position.x, 160.0);
    self.rightLayer.position = CGPointMake(self.rightLayer.position.x, 160.0);
    [self.leftLayer addAnimation:move forKey:nil];
    [self.rightLayer addAnimation:move forKey:nil];
    
    CASpringAnimation *springAnimate = [CASpringAnimation animationWithKeyPath:@"position.y"];
    springAnimate.damping = 15;
    springAnimate.initialVelocity = 40;
    springAnimate.toValue = [NSNumber numberWithFloat:160.0];
    self.centerLayer.position = CGPointMake(self.centerLayer.position.x, 160.0);
    [self.centerLayer addAnimation:springAnimate forKey:@"spring"];
}

- (void)fluctLayerAnimate{
    //用于每次绘制的位置
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointZero];
    
   CAAnimation *animate = [self.centerLayer animationForKey:@"spring"];
    if (animate == nil) {
        return;
    }
    
    //呈现树
    CALayer *leftPresentLayer = (CALayer *)[self.leftLayer presentationLayer];
    CALayer *centerPresentLayer = (CALayer *)[self.centerLayer presentationLayer];
    
    //偏移值
    CGFloat offset = leftPresentLayer.position.y - centerPresentLayer.position.y;
    //控制弧型的点
    CGFloat controlY = 160.0;
    if (offset < 0) {
        controlY = centerPresentLayer.position.y + 30;
    }else if (offset > 0){
        controlY = centerPresentLayer.position.y - 30;
    }
    
    [path addLineToPoint:self.leftLayer.position];

    /*画二次贝塞尔曲线
     * endPoint：终端点
     * controlPoint:控制点，对于二次贝塞尔曲线，只有一个控制点
     */
    [path addQuadCurveToPoint:self.rightLayer.position controlPoint:CGPointMake(self.centerLayer.position.x, controlY)];
    [path addLineToPoint:CGPointMake([UIScreen mainScreen].bounds.size.width, 0)];
    [path closePath];
    self.fluctLayer.path = path.CGPath;
}

@end
