//
//  ViewController.m
//  Map
//
//  Created by rt on 17/9/28.
//  Copyright © 2017年 runtop. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController ()<MKMapViewDelegate,CLLocationManagerDelegate,UIActionSheetDelegate>{

    
    //地图View
    MKMapView *_mapView;
    CLGeocoder *_geocoder;
    //定位管理器
    CLLocationManager *_locationManager;
    CLLocationDegrees la;
    CLLocationDegrees lo;
    //2点之间的线路
    CLLocationCoordinate2D fromCoordinate;
    CLLocationCoordinate2D toCoordinate;
    //计算2点之间的距离
    CLLocation *newLocation;
    CLLocation *oldLocation;
}
@property(nonatomic,strong)MKPolyline *routeLine;
@property(nonatomic,strong)MKPolylineView *routeLineView;
@property(nonatomic,strong)UIButton *btn;

@end

@implementation ViewController

- (UIButton *)btn{
    
    if(!_btn){
        
        _btn=[UIButton buttonWithType:UIButtonTypeCustom];
        _btn.frame=CGRectMake(30, 30, 100, 30);
        [_btn setTitle: @"平面地图"forState: UIControlStateNormal];
         [_btn setTitle: @"3D地图"forState: UIControlStateSelected];
        [_btn setTintColor:[UIColor redColor]];
        [_btn addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btn;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //创建地图View
    _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-20)];
    [self.view addSubview:_mapView];
    
    [self.view addSubview:self.btn];

    //缩放系数,参数越小,放得越大
    MKCoordinateSpan span = MKCoordinateSpanMake(0.06, 0.06);
    
    //区域
    MKCoordinateRegion region = MKCoordinateRegionMake(fromCoordinate, span);
    
    //设置地图的显示区域
    [_mapView setRegion:region animated:YES];
    
    //设置中心坐标(缩放系数不变)
    _mapView.centerCoordinate = fromCoordinate;
    
    
    //设置代理
    _mapView.delegate = self;
    _mapView.mapType = MKMapTypeStandard;
    
    //是否能缩放
    _mapView.zoomEnabled = YES;
    
    //是否能移动
    _mapView.scrollEnabled = YES;
    
    //是否能旋转
    _mapView.rotateEnabled = NO;
    
    //是否显示自己的位置
    _mapView.showsUserLocation = YES;
    
    
    //定位
    _locationManager = [[CLLocationManager alloc] init];
    
    //设置代理,通过代理方法接收自己的位置
    _locationManager.delegate = self;
    
    _mapView.centerCoordinate = _locationManager.location.coordinate;
    //iOS8.0的定位
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0 ) {
        [_locationManager requestAlwaysAuthorization];
        [_locationManager requestWhenInUseAuthorization];
    }
    //设置定位精度
    _locationManager.desiredAccuracy=kCLLocationAccuracyBest;
    //定位频率,每隔多少米定位一次
    CLLocationDistance distance=10.0;//十米定位一次
    _locationManager.distanceFilter=distance;
    //启动定位
    [_locationManager startUpdatingLocation];
    
    
    //标注
    MKPointAnnotation *ann = [[MKPointAnnotation alloc] init];
    ann.coordinate = fromCoordinate; //中心坐标
    ann.title = @"666"; //标题
    ann.subtitle = @"555"; //副标题
    
    //将标注显示在地图上
    [_mapView addAnnotation:ann];
    
    //添加长按手势
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [_mapView addGestureRecognizer:longPress];


}

- (void)click:(UIButton *)sender{
    
    sender.selected=!sender.selected;
    if(sender.selected){
        
        _mapView.mapType = MKMapTypeSatelliteFlyover;
    }else{
        
         _mapView.mapType = MKMapTypeStandard;
    }
}

#pragma mark--长按显示目标位置距离
- (void)longPress:(UILongPressGestureRecognizer *)gesture{
    
    //避免多次调用 只允许开始长按状态才添加大头针
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    //获取长按地图上的某个点
    CGPoint point = [gesture locationInView:_mapView];
    
    //把point转换成在地图上的坐标经纬度
    CLLocationCoordinate2D coordinate = [_mapView convertPoint:point toCoordinateFromView:_mapView];
    toCoordinate = coordinate;;
    
    //添加长按的大头针
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = coordinate;
    annotation.title = [NSString stringWithFormat:@"经度=%f",coordinate.longitude];
    annotation.subtitle =[NSString stringWithFormat:@"纬度=%f",coordinate.latitude];
    oldLocation=newLocation;
    newLocation=[[CLLocation alloc]initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    CGFloat distance = [newLocation distanceFromLocation:oldLocation];
   
    NSLog(@"长按与当前位置距离 = %fm", distance);
    [_mapView addAnnotation:annotation];
    
    //[self drawing];
    NSArray *array = [NSArray arrayWithObjects:oldLocation, newLocation, nil];
    [self drawLineWithLocationArray:array];
    
    //[self longPres];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"选择" delegate:self cancelButtonTitle: @"取消" destructiveButtonTitle:nil otherButtonTitles:@"高德地图", @"百度地图",@"谷歌地图", nil];
    
    [actionSheet showInView:self.view];
    
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    NSLog(@"buttonIndex = %zd",buttonIndex);
    
    if (buttonIndex == 0) {
        
        [self longPres];
    }
    else if(buttonIndex==1){
        
        NSString *urlString = [[NSString stringWithFormat:@"baidumap://map/direction?origin={{我的位置}}&destination=latlng:%f,%f|name=666&mode=driving&coord_type=gcj02",toCoordinate.latitude, toCoordinate.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        
        
    }
    else if (buttonIndex==2){
        
       // NSString *urlString = [[NSString stringWithFormat:@"comgooglemaps://?x-source=%@&x-success=%@&saddr=&daddr=%f,%f&directionsmode=driving",appName,urlScheme,coordinate.latitude, coordinate.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        
        
    }
}

#pragma mark--直接调用苹果自带的高德地图
-(void)longPres{
    
    MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:toCoordinate addressDictionary:nil];
    MKMapItem *toLocation = [[MKMapItem alloc] initWithPlacemark:placemark];
    toLocation.name = @"666";//终点
    
    [MKMapItem openMapsWithItems:@[currentLocation, toLocation]
                   launchOptions:@{MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,MKLaunchOptionsShowsTrafficKey: [NSNumber numberWithBool:YES]}];
    
    
}


- (void)drawLineWithLocationArray:(NSArray *)locationArray
{
    NSInteger pointCount = [locationArray count];
    CLLocationCoordinate2D *coordinateArray = (CLLocationCoordinate2D *)malloc(pointCount * sizeof(CLLocationCoordinate2D));
    
    for (int i = 0; i < pointCount; ++i) {
        CLLocation *location = [locationArray objectAtIndex:i];
        coordinateArray[i] = [location coordinate];
    }
    
    MKPolyline * routeLine = [MKPolyline polylineWithCoordinates:coordinateArray count:pointCount];
    //[_mapView setVisibleMapRect:[routeLine boundingMapRect]];
    [_mapView addOverlay:routeLine];
    
    free(coordinateArray);
    coordinateArray = NULL;
}

- (void)drawing{

    MKPlacemark *fromPlacemark = [[MKPlacemark alloc] initWithCoordinate:fromCoordinate addressDictionary:nil];
    MKPlacemark *toPlacemark = [[MKPlacemark alloc] initWithCoordinate:toCoordinate addressDictionary:nil];
    MKMapItem *fromItem = [[MKMapItem alloc] initWithPlacemark:fromPlacemark];
    MKMapItem *toItem = [[MKMapItem alloc] initWithPlacemark:toPlacemark];
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    request.source = fromItem;
    request.destination = toItem;
    request.requestsAlternateRoutes = YES;
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:
     ^(MKDirectionsResponse *response, NSError *error) {
         if (error) {
             NSLog(@"error:%@", error);
         }
         else {
             MKRoute *route = response.routes[0];
             [_mapView addOverlay:route.polyline];
         }
     }];
}

//线路的绘制
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer *renderer;
    renderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
    renderer.lineWidth = 5.0;
    renderer.strokeColor = [UIColor purpleColor];
    
    return renderer;
}




#pragma mark - MKMapViewDelegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay
{
    if(overlay == self.routeLine) {
        if(nil == self.routeLineView) {
            self.routeLineView = [[MKPolylineView alloc] initWithPolyline:self.routeLine] ;
            self.routeLineView.fillColor = [UIColor redColor];
            self.routeLineView.strokeColor = [UIColor redColor];
            self.routeLineView.lineWidth = 5;
        }
        return self.routeLineView;
    }
    return nil;
}

#pragma mark--追踪获取自己地理位置

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    CLLocation *location=[locations firstObject];//取出第一个位置
    CLLocationCoordinate2D coordinate=location.coordinate;//位置坐标
    fromCoordinate=coordinate;
    NSLog(@"经度：%f,纬度：%f,海拔：%f,航向：%f,行走速度：%f",coordinate.longitude,coordinate.latitude,location.altitude,location.course,location.speed);
    //反地理编码(逆地理编码): 将位置信息转换成地址信息
    //地理编码: 把地址信息转换成位置信息
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (error) {
            NSLog(@"反地理编码失败!");
            return ;
        }
        
        //地址信息
        
        CLPlacemark *placemark = [placemarks firstObject];
        oldLocation = placemark.location;
        newLocation=placemark.location;
        NSString *country = placemark.country;
        NSString *administrativeArea = placemark.administrativeArea;
        NSString *subLocality = placemark.subLocality;
        NSString *name = placemark.name;
        
        NSLog(@"当前位置====%@ %@ %@ %@", country, administrativeArea, subLocality, name);
        
        
    }];
    
    //如果不需要实时定位，使用完即使关闭定位服务
    [_locationManager stopUpdatingLocation];
}

//定位失败
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"定位失败:%@", error);
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    NSLog(@"经度=%f,纬度=%f",userLocation.location.coordinate.longitude,userLocation.location.coordinate.latitude);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
