class PerformanceData {
  final int enquiries;
  final int testDrives;
  final int orders;
  final int cancellation;
  final int netOrders;
  final int retail;

  PerformanceData({
    required this.enquiries,
    required this.testDrives,
    required this.orders,
    required this.cancellation,
    required this.netOrders,
    required this.retail,
  });

  factory PerformanceData.fromJson(Map<String, dynamic> json) {
    return PerformanceData(
      enquiries: int.tryParse(json['enquiries']?.toString() ?? '0') ?? 0,
      testDrives: int.tryParse(json['testDrives']?.toString() ?? '0') ?? 0,
      orders: int.tryParse(json['orders']?.toString() ?? '0') ?? 0,
      cancellation: int.tryParse(json['cancellation']?.toString() ?? '0') ?? 0,
      netOrders: int.tryParse(json['net_orders']?.toString() ?? '0') ?? 0,
      retail: int.tryParse(json['retail']?.toString() ?? '0') ?? 0,
    );
  }

  List<MetricItem> toMetricItems() {
    return [
      MetricItem(label: 'Enquiries', value: enquiries, key: 'enquiries'),
      MetricItem(label: 'Test Drive', value: testDrives, key: 'testDrives'),
      MetricItem(label: 'Orders', value: orders, key: 'orders'),
      MetricItem(
        label: 'Cancellations',
        value: cancellation,
        key: 'cancellation',
      ),
      MetricItem(label: 'Net Orders', value: netOrders, key: 'netOrders'),
      MetricItem(label: 'Retails', value: retail, key: 'retail'),
    ];
  }
}

class MetricItem {
  final String label;
  final int value;
  final String key;

  MetricItem({required this.label, required this.value, required this.key});
}
