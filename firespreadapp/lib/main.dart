// === 필수 패키지 import ===
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

// 앱 실행 진입점
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '산불 예측 앱',
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const MyHomePage(title: '산불 예측 홈')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset('assets/logo.png', width: 300),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double lat = 37.5665;
  double lon = 126.9780;
  bool isLoading = false;
  bool showResult = false;
  Map<String, dynamic>? predictionResult;
  GoogleMapController? mapController;
  Set<Polygon> firePolygons = {};

  Future<void> sendLocationToFirebase(double lat, double lon) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final docId = DateTime.now().toUtc().toIso8601String();

      await firestore.collection('fire_locations').doc(docId).set({
        'lat': lat,
        'lon': lon,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("✅ Firestore 저장 성공, 문서ID: $docId");
    } catch (e) {
      print("❌ Firestore 저장 실패: $e");
    }
  }

  Future<Map<String, dynamic>?> fetchLatestPredictionResult({int maxRetries = 1000}) async {
    final firestore = FirebaseFirestore.instance;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      print("🔁 [${attempt + 1}/$maxRetries] 최신 예측 결과 기다리는 중...");

      final snapshot = await firestore
          .collection('fire_results')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();

        if (data.containsKey('timestamp') && data.containsKey('grids')) {
          print("✅ 최신 예측 결과 찾음: ${doc.id}");
          return data;
        }
      }

      await Future.delayed(const Duration(seconds: 1));
    }

    print("❌ 예측 결과를 찾지 못했습니다.");
    return null;
  }

  void onPredictPressed() async {
    setState(() {
      isLoading = true;
      showResult = false;
      predictionResult = null;
    });

    await sendLocationToFirebase(lat, lon);

    try {
      final response = await http.get(Uri.parse(
          'https://firespread-api.onrender.com/input'));

      print('HTTP 응답 코드: ${response.statusCode}');
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예측 서버 요청에 실패했습니다.')),
      );
      return;
    }

    final result = await fetchLatestPredictionResult();

    if (result != null) {
      setState(() {
        predictionResult = result;
        showResult = true;
        isLoading = false;

        lat = result['lat'] ?? lat;
        lon = result['lon'] ?? lon;

        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lon), 12),
        );

        if (result.containsKey('grids')) {
          loadGridPolygonsFromDocument(result);
        } else {
          firePolygons = {};
        }
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예측 결과를 받아오지 못했습니다.')),
      );
    }
  }

  Color getGradientColor(double pSpread) {
    if (pSpread < 0.1) return Colors.green;
    else if (pSpread < 0.2) return Color.lerp(Colors.green, Colors.lightGreen, (pSpread - 0.1) / 0.1)!;
    else if (pSpread < 0.3) return Color.lerp(Colors.lightGreen, Colors.yellow, (pSpread - 0.2) / 0.1)!;
    else if (pSpread < 0.4) return Color.lerp(Colors.yellow, Colors.orange, (pSpread - 0.3) / 0.1)!;
    else if (pSpread < 0.5) return Color.lerp(Colors.orange, const Color(0xFFFF9999), (pSpread - 0.4) / 0.1)!;
    else if (pSpread < 0.6) return Color.lerp(const Color(0xFFFF9999), const Color(0xFFCC0000), (pSpread - 0.5) / 0.1)!;
    else if (pSpread < 0.75) return Color.lerp(const Color(0xFFCC0000), const Color(0xFF800000), (pSpread - 0.6) / 0.15)!;

    // 0.9 이상 구간: 0.01 간격 주황~진한 빨강 그라데이션
    else if (pSpread < 0.91) return const Color(0xFFFF6600); // 선명한 주황
    else if (pSpread < 0.92) return const Color(0xFFFF3300);
    else if (pSpread < 0.93) return const Color(0xFFFF0000); // 강한 빨강
    else if (pSpread < 0.94) return const Color(0xFFCC0000); // 진한 빨강
    else if (pSpread < 0.95) return const Color(0xFFB20000);
    else if (pSpread < 0.96) return const Color(0xFF990000);
    else if (pSpread < 0.97) return const Color(0xFF800000); // 어두운 빨강
    else if (pSpread < 0.98) return const Color(0xFF660000);
    else if (pSpread < 0.99) return const Color(0xFF4D0000);
    else return const Color(0xFF330000); // 매우 어두운 빨강
  }



  Polygon createGridPolygon(String grid_id, Map<String, dynamic> gridData) {
    final double latMin = (gridData['lat_min'] ?? 0).toDouble();
    final double latMax = (gridData['lat_max'] ?? 0).toDouble();
    final double lonMin = (gridData['lon_min'] ?? 0).toDouble();
    final double lonMax = (gridData['lon_max'] ?? 0).toDouble();
    final double pSpread = double.tryParse(gridData['pSpread'].toString()) ?? 0.0;

    final color = getGradientColor(pSpread);
    print("🟥 [$grid_id] pSpread: $pSpread, color: $color");
    print("🧭 [$grid_id] LatLngs: ($latMin, $lonMin), ($latMax, $lonMax)");

    Color blendWithTransparent(Color color, double opacity) {
      return Color.lerp(Colors.transparent, color, opacity) ?? color;
    }

    return Polygon(
      polygonId: PolygonId(grid_id),
      points: [
        LatLng(latMin, lonMin),
        LatLng(latMin, lonMax),
        LatLng(latMax, lonMax),
        LatLng(latMax, lonMin),
      ],
      fillColor: blendWithTransparent(getGradientColor(pSpread), 0.5),

      strokeColor: Colors.grey,
      strokeWidth: 1,
    );

  }

  void loadGridPolygonsFromDocument(Map<String, dynamic> docData) {
    final gridMap = docData['grids'] ?? {};
    print("🔥 [loadGridPolygonsFromDocument] grids 전체 데이터: $gridMap");
    print("🔥 그리드 수: ${gridMap.length}");
    Set<Polygon> polygons = {};
    gridMap.forEach((grid_id, data) {
      print("🟨 격자ID: $grid_id, 데이터: $data");
      polygons.add(createGridPolygon(grid_id, data));
    });
    setState(() {
      firePolygons = polygons;
      print("✅ 최종 생성된 폴리곤 수: ${firePolygons.length}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: const CameraPosition(
              target: LatLng(36.5, 127.5),
              zoom: 6.5,
            ),
            polygons: firePolygons,
            mapType: MapType.satellite,
            markers: showResult && predictionResult != null
                ? {
              Marker(
                markerId: const MarkerId('fire_prediction'),
                position: LatLng(lat, lon),
              ),
            }
                : {},
          ),
          if (!showResult)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: const Color.fromRGBO(255, 255, 255, 0.85),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: '위도 입력'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => lat = double.tryParse(val) ?? lat,
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: '경도 입력'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => lon = double.tryParse(val) ?? lon,
                    ),
                    const SizedBox(height: 10),
                    const Text('산불 예측을 진행하시겠습니까?'),
                    ElevatedButton(
                      onPressed: isLoading ? null : onPredictPressed,
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text('예측 시작하기'),
                    ),
                  ],
                ),
              ),
            ),
          if (showResult && predictionResult != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.33,
                padding: const EdgeInsets.all(12),
                color: const Color.fromRGBO(255, 255, 255, 0.85),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('위치: ${predictionResult?['lat'] ?? lat}, ${predictionResult?['lon'] ?? lon}'),
                    const Text('Top 3 영향 요인:'),
                    ...List.generate(
                      3,
                          (i) => Text(
                        '- ${predictionResult?["global_feature_importance_top3"]?[i] ?? '-'}',
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            showResult = false;
                            predictionResult = null;
                            firePolygons = {};
                          });
                        },
                        child: const Text('닫기'),
                      ),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
