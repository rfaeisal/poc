import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/location_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  final String channelId;
  const MapScreen({super.key, required this.channelId});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final center = location.myLocation ?? const LatLng(-6.2088, 106.8456);

    final markers = <Marker>[];

    // My location
    if (location.myLocation != null) {
      markers.add(Marker(
        point: location.myLocation!,
        width: 40,
        height: 40,
        child: const _MyLocationMarker(),
      ));
    }

    // Other members
    for (final member in location.memberLocations.values) {
      markers.add(Marker(
        point: member.position,
        width: 80,
        height: 60,
        child: _MemberMarker(callsign: member.callsign),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          if (location.myLocation != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () {
                _mapController.move(location.myLocation!, 15);
              },
            ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.fakhriez.poc_pecek',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          if (location.isSharing) {
            ref.read(locationProvider.notifier).stopSharing();
          }
        },
        child: Icon(
          location.isSharing ? Icons.location_on : Icons.location_off,
        ),
      ),
    );
  }
}

class _MyLocationMarker extends StatelessWidget {
  const _MyLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: const Center(
        child: Icon(Icons.person, size: 20, color: Colors.blue),
      ),
    );
  }
}

class _MemberMarker extends StatelessWidget {
  final String callsign;
  const _MemberMarker({required this.callsign});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            callsign,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(Icons.location_pin, size: 28, color: Colors.green),
      ],
    );
  }
}
