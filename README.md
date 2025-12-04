# 🏥 Health Monitor App

Ứng dụng Flutter để theo dõi sức khỏe từ thiết bị **ESP32-C3** qua kết nối WiFi.

## 📋 Mục Lục
- [Tổng Quan](#tổng-quan)
- [Yêu Cầu Hệ Thống](#yêu-cầu-hệ-thống)
- [Cài Đặt](#cài-đặt)
- [Cách Sử Dụng](#cách-sử-dụng)
- [Kiến Trúc Ứng Dụng](#kiến-trúc-ứng-dụng)
- [Giao Diện](#giao-diện)
- [Tính Năng](#tính-năng)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Tổng Quan

**Health Monitor App** là một ứng dụng di động hiện đại được xây dựng bằng **Flutter** để kết nối và theo dõi các chỉ số sức khỏe từ thiết bị **ESP32-C3** (smartwatch/wristband).

### Tính Năng Chính:
- ✅ Giao diện cấu hình IP với animations mượt mà
- ✅ Kết nối WiFi an toàn đến ESP32-C3
- ✅ Theo dõi dữ liệu sức khỏe real-time
- ✅ Theme sáng/tối tự động theo hệ thống
- ✅ Responsive design cho mọi kích thước màn hình
- ✅ Xác thực Input hợp lệ

---

## 💻 Yêu Cầu Hệ Thống

### Phía Client (Điện Thoại)
- **Flutter SDK:** `^3.0.0`
- **Dart SDK:** `^3.0.0`
- **Android:** API 21+ (Android 5.0+)
- **iOS:** iOS 11+
- **macOS:** 10.14+
- **Web:** Chrome, Firefox, Safari

### Phía Server (ESP32-C3)
- **Board:** ESP32-C3 (hoặc tương thích)
- **Firmware:** ESP-IDF v5.0+
- **WiFi:** 2.4GHz hoặc 5GHz

---

## 🚀 Cài Đặt

### 1. Clone Repository
```bash
git clone <repo-url>
cd health_monitor_app
```

### 2. Cài Đặt Flutter Dependencies
```bash
flutter clean
flutter pub get
```

### 3. Chuẩn Bị Assets
```bash
# Kiểm tra thư mục assets
ls -la assets/images/
# Phải có: right_decor.jpeg
```

### 4. Build Ứng Dụng

#### Android
```bash
flutter build apk --release
# hoặc
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

---

## 📱 Cách Sử Dụng

### Bước 1: Khởi Động ESP32-C3
1. Upload code từ `health_monitoring_wristband`
2. Kết nối ESP32-C3 vào WiFi
3. Ghi nhớ **IP Address** của thiết bị
   - Kiểm tra từ router hoặc serial monitor

### Bước 2: Chạy Ứng Dụng Flutter

```bash
# Chạy trên thiết bị/emulator
flutter run

# Chạy với device cụ thể
flutter run -d <device_id>

# Xem danh sách device
flutter devices
```

### Bước 3: Kết Nối Thiết Bị

| Bước | Mô Tả |
|------|-------|
| 1️⃣ | Mở ứng dụng Health Monitor |
| 2️⃣ | Nhập IP của ESP32-C3 (ví dụ: `192.168.1.100`) |
| 3️⃣ | Kiểm tra cả 2 thiết bị cùng WiFi network |
| 4️⃣ | Nhấn nút **CONNECT TO DEVICE** |
| 5️⃣ | Chờ transition sang Health Monitor Screen |

---

## 🏗️ Kiến Trúc Ứng Dụng

### Cấu Trúc Thư Mục
```
health_monitor_app/
├── lib/
│   ├── main.dart                          # Entry point + IPConfigScreen
│   ├── screens/
│   │   ├── health_monitor_screen.dart    # Màn hình chính
│   │   └── ...
│   ├── models/                           # Data models
│   │   ├── health_data.dart
│   │   └── ...
│   ├── services/                         # API & connectivity
│   │   ├── api_service.dart
│   │   └── ...
│   └── widgets/                          # Reusable widgets
│       ├── heart_rate_card.dart
│       ├── stats_chart.dart
│       └── ...
├── assets/
│   └── images/
│       └── right_decor.jpeg
├── pubspec.yaml                          # Dependencies
├── android/                              # Android config
├── ios/                                  # iOS config
└── web/                                  # Web config
```

### Flow Ứng Dụng
```
┌─────────────────────────────────────┐
│   MyApp (MaterialApp Entry)         │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│   IPConfigScreen                    │
│   • Nhập IP ESP32                   │
│   • Validation IP format            │
│   • Animations (pulse, fade)        │
└────────────┬────────────────────────┘
             │ [CONNECT_PRESSED]
             ▼
    ┌────────────────────┐
    │ Validate IP        │
    │ Regex check        │
    └────────┬───────────┘
             │
        ✅ VALID / ❌ INVALID
        │                 │
        ▼                 ▼
   [Navigate]        [Show Error]
   Fade Transition   SnackBar
        │
        ▼
┌─────────────────────────────────────┐
│   HealthMonitorScreen               │
│   • Hiển thị dữ liệu real-time      │
│   • Charts & Statistics             │
│   • Device controls                 │
└─────────────────────────────────────┘
```

---

## ⚙️ Tính Năng Chi Tiết

### 1. IP Configuration Screen

#### Input Validation
```dart
RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(ip)
```

**Kiểm tra:**
- ✅ Không để trống
- ✅ Format IP hợp lệ (XXX.XXX.XXX.XXX)
- ✅ Trim whitespace

#### Error Handling
```dart
// Nếu IP không hợp lệ
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Vui lòng nhập IP hợp lệ!'),
    backgroundColor: Colors.red,
  ),
);
```

#### Navigation
```dart
Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (_, animation, __) => HealthMonitorScreen(esp32Ip: ip),
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 700),
  ),
);
```

## 📡 API Integration

### Expected ESP32 Endpoints

**Health Monitor Screen** sẽ gọi:

```
GET http://{ESP32_IP}/sensor
Response: {
  "heart_rate": 72,
  "blood_oxygen": 98,
  "temperature": 36.5,
  "steps": 1234,
  "timestamp": "2024-12-04T10:30:00Z"
}

GET http://{ESP32_IP}/alerts
Response: {
  "accel_x": 0.1,
  "accel_y": 0.2,
  "accel_z": 9.8,
  "gyro_x": 0.01,
  "gyro_y": 0.02,
  "gyro_z": 0.03
}
```

---

## 🐛 Troubleshooting

### ❌ Lỗi: "Vui lòng nhập IP hợp lệ!"

**Nguyên nhân:**
- IP format sai
- IP để trống
- Có khoảng trắng

**Giải pháp:**
```
✅ Correct: 192.168.1.100
❌ Wrong:   192.168.1.100 (có space)
❌ Wrong:   192.168.1
❌ Wrong:   (để trống)
```

### ❌ Lỗi: "Không kết nối được ESP32"

**Nguyên nhân:**
- ESP32 chưa start
- IP không đúng
- Không cùng WiFi network
- Firewall chặn

**Giải pháp:**
1. Kiểm tra ESP32 start (LED sáng)
2. Verify IP từ serial monitor
3. Ping từ phone: `adb shell ping {IP}`
4. Disable firewall tạm thời
5. Kiểm tra WiFi SSID


## 📦 Dependencies

### pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  material3: ^0.0.1
  # Thêm theo nhu cầu:
  # dio: ^5.0.0          # HTTP client
  # provider: ^6.0.0     # State management
  # charts_flutter: ...  # Data visualization
  # shared_preferences   # Local storage
```

---

## 📚 Tài Liệu Tham Khảo

- [Flutter Docs](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Material Design 3](https://m3.material.io/)
- [ESP-IDF Documentation](https://docs.espressif.com/projects/esp-idf/)
- [ESP32-C3 Datasheet](https://www.espressif.com/sites/default/files/documentation/esp32-c3_datasheet_en.pdf)

---


## 📞 Support

### Issues & Bugs
- GitHub Issues: [Link]
- Email: [contact@example.com]

### Quick Support
| Vấn Đề | Contact |
|--------|---------|
| Flutter | @flutter-support |
| ESP32 | @espressif-support |
| App | [email] |

---

**Version:** 1.0.0  
**Last Updated:** December 4, 2025 
**Author:** [Your Name]

---

🎉 **Enjoy monitoring your health with Health Monitor App!**