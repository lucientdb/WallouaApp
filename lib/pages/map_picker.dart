import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:geocoding/geocoding.dart';

class MapPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const MapPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  StreamSubscription<Position>? _positionStream;
  String _address = '';
  bool _isLoading = true;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _initializePosition();
  }

  Future<void> _getAddressFromCoordinates(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String addressParts = '';

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts += '${place.street}, ';
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts += '${place.locality}, ';
        }
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          addressParts += '${place.subAdministrativeArea}, ';
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts += place.country!;
        }

        setState(() {
          _address = addressParts.isNotEmpty
              ? addressParts
              : 'Adresse non disponible';
        });
      }
    } catch (e) {
      setState(() {
        _address =
            'Lat: ${position.latitude.toStringAsFixed(6)}, Long: ${position.longitude.toStringAsFixed(6)}';
      });
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _initializePosition() async {
    try {
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        setState(() {
          _selectedPosition = LatLng(
            widget.initialLatitude!,
            widget.initialLongitude!,
          );
          _isLoading = false;
        });
      } else {
        // localisation en temps réel
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Les services de localisation sont désactivés'),
              ),
            );
          }
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            setState(() => _isLoading = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Permission de localisation refusée'),
                ),
              );
            }
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Permission de localisation refusée définitivement',
                ),
              ),
            );
          }
          return;
        }

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _selectedPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        await _getAddressFromCoordinates(_selectedPosition!);

        _positionStream =
            Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 5,
              ),
            ).listen((Position pos) {
              final latLng = LatLng(pos.latitude, pos.longitude);
              setState(() {
                _selectedPosition = latLng;
              });
              if (_mapController != null) {
                _mapController!.animateCamera(CameraUpdate.newLatLng(latLng));
              }
            });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
    _getAddressFromCoordinates(position);
  }

  void _confirmLocation() {
    if (_selectedPosition != null && _address.isNotEmpty) {
      Navigator.pop(context, {
        'position': _selectedPosition,
        'address': _address,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner votre position'),
        backgroundColor: const Color.fromARGB(255, 16, 7, 189),
        foregroundColor: Colors.white,
        actions: [
          if (_selectedPosition != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmLocation,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 16, 7, 189),
              ),
            )
          : _selectedPosition == null
          ? const Center(
              child: Text(
                'Impossible de récupérer votre position',
                style: TextStyle(fontSize: 16),
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedPosition!,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: _onMapTapped,
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: _selectedPosition!,
                      draggable: true,
                      onDragEnd: (newPosition) {
                        setState(() {
                          _selectedPosition = newPosition;
                        });
                      },
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueViolet,
                      ),
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Adresse sélectionnée',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_isLoadingAddress)
                            const CircularProgressIndicator(
                              color: Color.fromARGB(255, 16, 7, 189),
                            )
                          else
                            Text(
                              _address.isNotEmpty
                                  ? _address
                                  : 'Chargement de l\'adresse...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _address.isNotEmpty && !_isLoadingAddress
                                ? _confirmLocation
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                16,
                                7,
                                189,
                              ),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Confirmer',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Déplacez le marqueur pour ajuster la position',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
