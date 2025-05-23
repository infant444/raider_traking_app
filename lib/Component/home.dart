import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  final LatLng _startPoint = LatLng(12.4701689, 79.3199367);
  final LatLng _destinationPoint = LatLng(12.465119, 79.346652);

  List<LatLng> _routePoint = [];

  bool _routeLoad = false;

  LatLng _vehiclePosition = LatLng(12.4701689, 79.3199367);
  double _vehicleRotation = 0.0;
  Timer? _timer;
  int _currentRouterIndex = 0;
  double _progress = 0.0;
  bool _isFollowingVehicle = true;
  Timer? _followTimer;

  double _contactSpeed = 40.0;
  double _totalRouteDistance = 0.0;
  double _distanceTraveled = 0.0;

  String _vehicleType = 'Sedan';
  String _driverName = 'Raju';
  String _estimatedTime = 'Calculating...';
  String _distance = 'Calculating...';

  double _rating = 4.9;
  String _plateNumber = "TN25BC1414";
  String _carModel = 'Alto K10';

  late AnimationController _vehicleAnimationController;
  late AnimationController _bottomSheetController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _vehicleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bottomSheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _bottomSheetController.forward();

    setState(() {
      _vehiclePosition = _startPoint;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRealRoute();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _followTimer?.cancel();
    _vehicleAnimationController.dispose();
    _bottomSheetController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchRealRoute() async {
    try {
      final String url =
          "https://router.project-osrm.org/route/v1/driving/${_startPoint.longitude},${_startPoint.latitude};${_destinationPoint.longitude},${_destinationPoint.latitude}?overview=full&geometries=geojson";
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Flutter Map Example'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // print(data);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          // print(route);
          final coordinates = route['geometry']['coordinates'] as List;
          _routePoint =
              coordinates.map<LatLng>((coord) {
                return LatLng(coord[1].toDouble(), coord[0].toDouble());
              }).toList();

          final distance = route['distance'] / 1000.0;
          final duration = route['duration'] / 60.0;

          setState(() {
            _vehiclePosition = _routePoint.first;
            _routeLoad = true;
            _distance = '${distance.toStringAsFixed(1)} km';
            _estimatedTime = '${duration.round()} min';
            _totalRouteDistance = distance;
            _distanceTraveled = 0.0;
          });

          _startVehicleTracking();

          if (_routePoint.isNotEmpty) {
            Future.delayed(Duration(milliseconds: 500), () {
              if (mounted) {
                try {
                  double minLat = _routePoint
                      .map((p) => p.latitude)
                      .reduce(math.min);
                  double maxLat = _routePoint
                      .map((p) => p.latitude)
                      .reduce(math.max);

                  double minLng = _routePoint
                      .map((p) => p.longitude)
                      .reduce(math.min);
                  double maxLng = _routePoint
                      .map((p) => p.longitude)
                      .reduce(math.max);
                  LatLng center = LatLng(
                    (maxLat + minLat) / 2,
                    (maxLng + minLng) / 2,
                  );

                  _mapController.move(center, 13);
                } catch (e) {
                  print("Hi $e");
                }
              }
            });
          }
        } else {
          _fallBackSimulateRoute();
        }
      }
    } catch (e) {
      print("Error Fetching route : $e");
      _fallBackSimulateRoute();
    }
  }

  void _fallBackSimulateRoute() {
    _routePoint = [
      LatLng(12.470161, 79.319973),
      LatLng(12.469569, 79.319838),
      LatLng(12.469072, 79.319763),
      LatLng(12.468896, 79.320058),
      LatLng(12.468771, 79.320356),
      LatLng(12.468175, 79.323712),
      LatLng(12.467926, 79.325517),
      LatLng(12.467804, 79.326395),
      LatLng(12.467642, 79.328552),
      LatLng(12.467377, 79.331336),
      LatLng(12.467267, 79.333166),
      LatLng(12.466964, 79.338203),
      LatLng(12.466933, 79.338735),
      LatLng(12.466911, 79.339099),
      LatLng(12.466892, 79.33941),
      LatLng(12.466825, 79.339691),
      LatLng(12.466695, 79.340238),
      LatLng(12.466587, 79.340693),
      LatLng(12.466493, 79.341089),
      LatLng(12.466306, 79.341877),
      LatLng(12.466293, 79.341932),
      LatLng(12.466185, 79.345213),
      LatLng(12.466184, 79.345243),
      LatLng(12.466194, 79.346161),
      LatLng(12.466209, 79.346395),
      LatLng(12.466225, 79.346889),
      LatLng(12.466244, 79.347505),
      _destinationPoint,
    ];

    double _totalDistance = 0.0;
    for (int i = 0; i < _routePoint.length - 1; i++) {
      _totalDistance += _calculateDistanceBwt(
        _routePoint[i],
        _routePoint[i + 1],
      );
    }
    setState(() {
      _vehiclePosition = _routePoint.first;
      _routeLoad = true;
      _distance = '${_totalDistance.toStringAsFixed(1)} km';
      _estimatedTime = '${((_totalDistance / _contactSpeed) * 60).round()} min';
      _totalRouteDistance = _totalDistance;
      _distanceTraveled = 0.0;
    });

    _startVehicleTracking();
  }

  double _calculateDistanceBwt(LatLng start, LatLng end) {
    const double earthRadius = 6371.0; // in kilometers
    final double dLat = (end.latitude - start.latitude) * math.pi / 180.0;
    final double dLng = (end.longitude - start.longitude) * math.pi / 180.0;
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(start.latitude * math.pi / 180.0) *
            math.cos(end.latitude * math.pi / 180.0) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  void _startVehicleTracking() {
    if (_routeLoad || _routePoint.isEmpty) return;

    _timer?.cancel();

    setState(() {
      _currentRouterIndex = 0;
      _progress = 0.0;
      _vehiclePosition = _routePoint.first;
    });

    _timer = Timer.periodic(Duration(milliseconds: 33), (timer) {
      if (_currentRouterIndex < _routePoint.length - 1) {
        _updateVehiclePosition();
      } else {
        _timer?.cancel();
        _showRideComplete();
      }
    });
  }

  void _updateVehiclePosition() {
    if (_currentRouterIndex >= _routePoint.length - 1) return;

    double totalDistanceSoFor = 0.0;

    for (int i = 0; i < _currentRouterIndex; i++) {
      totalDistanceSoFor += _calculateDistanceBwt(
        _routePoint[i],
        _routePoint[i + 1],
      );
    }
    if (_currentRouterIndex < _routePoint.length - 1) {
      double currentSegmentDistance = _calculateDistanceBwt(
        _routePoint[_currentRouterIndex],
        _routePoint[_currentRouterIndex + 1],
      );
      totalDistanceSoFor += currentSegmentDistance * _progress;
    }
    double speedPerUpdate = (_contactSpeed / 3600.0) * 0.033;
    final newTotalDistance = totalDistanceSoFor + speedPerUpdate;

    double accumlatedDistance = 0.0;
    int newSegmentIndex = 0;
    double progressInNewSegment = 0.0;

    for (int i = 0; i < _routePoint.length - 1; i++) {
      double segmentDistance = _calculateDistanceBwt(
        _routePoint[i],
        _routePoint[i + 1],
      );
      if (accumlatedDistance + segmentDistance >= newTotalDistance) {
        newSegmentIndex = i;
        double distanceIntoSegment = newTotalDistance - accumlatedDistance;
        progressInNewSegment = distanceIntoSegment / segmentDistance;
        break;
      }
      accumlatedDistance += segmentDistance;
      newSegmentIndex = i + 1;
    }
    if (newSegmentIndex >= _routePoint.length - 1) {
      setState(() {
        _vehiclePosition = _routePoint.last;
        _vehicleRotation = _calculateBearing(
          _routePoint[_routePoint.length - 2],
          _routePoint.last,
        );
      });
      _timer?.cancel();
      _showRideCompleted();
      return;
    }
    LatLng startPoint = _routePoint[newSegmentIndex];
    LatLng endPoint = _routePoint[newSegmentIndex + 1];
    progressInNewSegment = progressInNewSegment.clamp(0.0, 1.0);
    double lat =
        startPoint.latitude +
        (progressInNewSegment * (endPoint.latitude - startPoint.latitude));
    double lng =
        startPoint.longitude +
        (progressInNewSegment * (endPoint.longitude - startPoint.longitude));

    LatLng newPosition = LatLng(lat, lng);
    double rotation = _calculateBearing(startPoint, endPoint);

    setState(() {
      _
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
