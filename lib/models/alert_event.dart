class AlertEvent {
  final int t; // timestamp in milliseconds (relative)
  final String msg;

  AlertEvent({
    required this.t,
    required this.msg,
  });

  factory AlertEvent.fromJson(Map<String, dynamic> json) {
    return AlertEvent(
      t: (json['t'] ?? 0) as int,
      msg: (json['msg'] ?? '') as String,
    );
  }
}


