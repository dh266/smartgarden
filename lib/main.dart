import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class Sensor {
  final String name;
  final double highThreshold;
  final double lowThreshold;
  final String unit;
  bool isRelayOn; // Thêm trạng thái relay

  Sensor({
    required this.name,
    required this.highThreshold,
    required this.lowThreshold,
    required this.unit,
    this.isRelayOn = false, // Khởi tạo trạng thái relay mặc định
  });

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
      name: json['name'] ?? '',
      highThreshold: (json['highThreshold'] as num).toDouble(),
      lowThreshold: (json['lowThreshold'] as num).toDouble(),
      unit: json['unit'] ?? '',
      isRelayOn: json['isRelayOn'] ?? false, // Lấy trạng thái relay từ JSON
    );
  }

  String get thresholdText => '$name: $lowThreshold - $highThreshold $unit';
}

class APIService {
  static Future<Sensor> fetchSensorData(int sensorId) async {
    final response = await http.get(Uri.parse('http://iot209.ddns.net/api/app/sensor/$sensorId'));

    if (response.statusCode == 200) {
      return Sensor.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load sensor data');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DefaultTabController(
        length: 2,
        child: MyTabs(),
      ),
    );
  }
}

class MyTabs extends StatelessWidget {
  const MyTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor App'),
      ),
      body: Column(
        children: [
          _buildHeaderImage(context), // Thêm phần ảnh chủ đề
          const Expanded(
            child: TabBarView(
              children: [
                SensorWidget(),
                ControlWidget(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const TabBar(
        tabs: [
          Tab(text: 'In House'),
          Tab(text: 'Control'),
        ],
      ),
    );
  }

  Widget _buildHeaderImage(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 3,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/house.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter, // Căn hình ảnh ở phía trên giữa
        ),
      ),
    );
  }
}

class SensorWidget extends StatelessWidget {
  const SensorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Sensor>>(
        future: Future.wait([
          APIService.fetchSensorData(1),
          APIService.fetchSensorData(2),
          APIService.fetchSensorData(3),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final List<Sensor> sensorDataList = snapshot.data!;
            return GridView.count(
              crossAxisCount: 2,
              children: [
                _buildSensorTile(sensorDataList, 'Soil Moisture', context),
                _buildSensorTile(sensorDataList, 'pH', context),
                _buildSensorTile(sensorDataList, 'EC', context),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSensorTile(List<Sensor> sensorDataList, String name, BuildContext context) {
    Sensor? sensorData = sensorDataList.firstWhere((sensor) => sensor.name == name, orElse: () => Sensor(name: '', highThreshold: 0, lowThreshold: 0, unit: ''));
    String iconPath = 'assets/images/icons/${name.replaceAll(' ', '').toLowerCase()}.png';
    return GestureDetector(
      onTap: () {
        _showTooltip(context, name); // Hiển thị tooltip khi bấm vào icon
      },
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Image.asset(iconPath, width: 50, height: 50), // Hiển thị hình ảnh
            const SizedBox(height: 8), // Khoảng cách giữa hình ảnh và văn bản
            Text(sensorData!.thresholdText),
          ],
        ),
      ),
    );
  }

  void _showTooltip(BuildContext context, String name) {
    final tooltip = Tooltip(
      message: name,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          name,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) => tooltip,
    );
  }
}

class ControlWidget extends StatelessWidget {
  const ControlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ControlButton(name: 'Relay 1'),
          ControlButton(name: 'Relay 2'),
          ControlButton(name: 'Relay 3'),
        ],
      ),
    );
  }
}

class ControlButton extends StatefulWidget {
  final String name;

  const ControlButton({super.key, required this.name});

  @override
  _ControlButtonState createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {
  bool _isRelayOn = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _isRelayOn = !_isRelayOn;
        });
        // Gửi trạng thái relay tới server
        _sendRelayStateToServer(_isRelayOn);
      },
      child: Text(widget.name + ' ' + (_isRelayOn ? 'On' : 'Off')), // Hiển thị trạng thái relay
    );
  }

  // Hàm gửi trạng thái relay tới server
  void _sendRelayStateToServer(bool isRelayOn) {
    // Code để gửi trạng thái relay tới server ở đây
  }
}
