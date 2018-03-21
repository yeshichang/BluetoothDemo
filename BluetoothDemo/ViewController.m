//
//  ViewController.m
//  BluetoothDemo
//
//  Created by mac on 2018/2/3.
//  Copyright © 2018年 luomi. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

typedef NS_ENUM(NSInteger, BluetoothState){
    BluetoothStateDisconnect = 0,
    BluetoothStateScanSuccess,
    BluetoothStateScaning,
    BluetoothStateConnected,
    BluetoothStateConnecting
};

typedef NS_ENUM(NSInteger, BluetoothFailState){
    BluetoothFailStateUnExit = 0,
    BluetoothFailStateUnKnow,
    BluetoothFailStateByHW,
    BluetoothFailStateByOff,
    BluetoothFailStateUnauthorized,
    BluetoothFailStateByTimeout
};

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong , nonatomic) UITableView *tableView;
@property (strong , nonatomic) CBCentralManager *manager;               // 中央设备
@property (assign , nonatomic) BluetoothFailState bluetoothFailState;
@property (assign , nonatomic) BluetoothState bluetoothState;
@property (strong , nonatomic) CBPeripheral * discoveredPeripheral;     // 周边设备
@property (strong , nonatomic) CBCharacteristic *characteristic1;       // 周边设备服务特性
@property (strong , nonatomic) NSMutableArray *BleViewPerArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    self.BleViewPerArr = [[NSMutableArray alloc] initWithCapacity:1];
}

// 开始扫描
- (IBAction)scan:(id)sender {
    // 判断状态开始扫描周围设备，第一个参数为空则会扫描所有课链接设备
    // 指定一个CBUUID对象，从而只扫描注册用指定服务的设备
    // scanForPeripheralsWithServices方法调用完后会调用代理CBCentralManagerDelegate的
    // - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI方法
    
    [self.manager scanForPeripheralsWithServices:nil options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO }];
    // 记录目前是扫描状态
    _bluetoothState = BluetoothStateScaning;
    // 清空所有外设数组
    [self.BleViewPerArr removeAllObjects];
    // 如果蓝牙状态未开启，提示开启蓝牙
    if (_bluetoothState == BluetoothFailStateByOff) {
        NSLog(@"%@",@"检查您的蓝牙是否开启后重试");
    }
}

// 接下来会加测蓝牙状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBManagerStatePoweredOn) {
        NSLog(@"fail, state is off.");
        switch (central.state) {
            case CBManagerStatePoweredOff:
                NSLog(@"连接失败了\n请您再检查一下您的手机蓝牙是否开启，\n然后再试一次吧");
                _bluetoothFailState = BluetoothFailStateByOff;
                break;
            case CBManagerStateResetting:
                _bluetoothFailState = BluetoothFailStateByTimeout;
                break;
            case CBManagerStateUnsupported:
                NSLog(@"检测到您的手机不支持蓝牙4.0\n所以建立不了连接.建议更换您\n的手机再试试。");
                _bluetoothFailState = BluetoothFailStateByHW;
                break;
            case CBManagerStateUnauthorized:
                NSLog(@"连接失败了\n请您再检查一下您的手机蓝牙是否开启，\n然后再试一次吧");
                _bluetoothFailState = BluetoothFailStateUnauthorized;
                break;
            case CBManagerStateUnknown:
                _bluetoothFailState = BluetoothFailStateUnKnow;
                break;
            default:
                break;
        }
        return;
    }
    _bluetoothFailState = BluetoothFailStateUnExit;
    // ... so start scanning
}

// 广播数据和信号质量
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    if (peripheral == nil || peripheral.identifier == nil/*||peripheral.name == nil*/)
    {
        return;
    }
    NSString *pername = [NSString stringWithFormat:@"%@",peripheral.name];
    // 判断是否存在 你的设备名
    NSRange range = [pername rangeOfString:@"叶葉叶葉"];
    // 如果从搜索到的设备中找到指定设备名，和BleViewPerArr数组没有它的地址
    // 加入BleViewPerArr数组
    if (range.location != NSNotFound && [_BleViewPerArr containsObject:peripheral] == 0) {
        [_BleViewPerArr addObject:peripheral];
    }
    _bluetoothFailState = BluetoothFailStateUnExit;
    _bluetoothState = BluetoothStateScanSuccess;
    [_tableView reloadData];
}

- (void)setTableView {
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_tableView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IsConnect"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"IsConnect"];
    }
    
    // 将蓝牙外设对象接出，取出name，显示
    // 蓝牙对象在下面环节会查找出来，被放进bleViewperArr数组里面，是CBPeripheral对象
    CBPeripheral *per = (CBPeripheral *)_BleViewPerArr[indexPath.row];
//    NSString *bleName = [per.name substringWithRange:NSMakeRange(0, 9)];
    cell.textLabel.text = per.name;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _BleViewPerArr.count;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
