import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Sponsor Configuration Model
class SponsorConfig {
  final String bannerUrl;
  final String slot1Url;
  final String slot2Url;
  final String slot3Url;
  final String cornerLogoUrl;
  final String fpodSponsorLogoUrl;
  final String fpodSponsorName;
  final String fpodCardTitle;

  SponsorConfig({
    this.bannerUrl = '',
    this.slot1Url = '',
    this.slot2Url = '',
    this.slot3Url = '',
    this.cornerLogoUrl = '',
    this.fpodSponsorLogoUrl = '',
    this.fpodSponsorName = '',
    this.fpodCardTitle = 'Player of the Day',
  });

  factory SponsorConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return SponsorConfig();
    return SponsorConfig(
      bannerUrl: map['bannerUrl'] ?? '',
      slot1Url: map['slot1Url'] ?? '',
      slot2Url: map['slot2Url'] ?? '',
      slot3Url: map['slot3Url'] ?? '',
      cornerLogoUrl: map['cornerLogoUrl'] ?? '',
      fpodSponsorLogoUrl: map['fpodSponsorLogoUrl'] ?? '',
      fpodSponsorName: map['fpodSponsorName'] ?? '',
      fpodCardTitle: map['fpodCardTitle'] ?? 'Player of the Day',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bannerUrl': bannerUrl,
      'slot1Url': slot1Url,
      'slot2Url': slot2Url,
      'slot3Url': slot3Url,
      'cornerLogoUrl': cornerLogoUrl,
      'fpodSponsorLogoUrl': fpodSponsorLogoUrl,
      'fpodSponsorName': fpodSponsorName,
      'fpodCardTitle': fpodCardTitle,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  bool get hasBanner => bannerUrl.isNotEmpty;
  bool get hasCornerLogo => cornerLogoUrl.isNotEmpty;
  bool get hasFpodSponsor => fpodSponsorLogoUrl.isNotEmpty ||
      fpodSponsorName.isNotEmpty;
}

/// Sponsor Service
/// Firestore path: tournaments/{tournamentId}/sponsors/config
/// Storage path: sponsors/{tournamentId}/{fileName}
class SponsorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  DocumentReference<Map<String, dynamic>> _configDoc(String tournamentId) =>
      _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('sponsors')
          .doc('config');

  /// Stream sponsor configuration for a tournament
  Stream<SponsorConfig> streamConfig(String tournamentId) {
    return _configDoc(tournamentId).snapshots().map((doc) {
      return SponsorConfig.fromMap(doc.data());
    });
  }

  /// Get sponsor configuration once
  Future<SponsorConfig> getConfig(String tournamentId) async {
    final doc = await _configDoc(tournamentId).get();
    return SponsorConfig.fromMap(doc.data());
  }

  /// ─────────────────── Upload Methods ───────────────────

  /// Upload banner image
  Future<String> uploadBanner(
    String tournamentId,
    File image,
  ) async {
    return _uploadImage(tournamentId, image, 'banner');
  }

  /// Upload slot image (1, 2, or 3)
  Future<String> uploadSlot(
    String tournamentId,
    File image,
    int slotNumber,
  ) async {
    return _uploadImage(tournamentId, image, 'slot$slotNumber');
  }

  /// Upload corner logo
  Future<String> uploadCornerLogo(
    String tournamentId,
    File image,
  ) async {
    return _uploadImage(tournamentId, image, 'corner_logo');
  }

  /// Upload FPOD sponsor logo
  Future<String> uploadFpodSponsorLogo(
    String tournamentId,
    File image,
  ) async {
    return _uploadImage(tournamentId, image, 'fpod_sponsor');
  }

  /// Generic image upload + Firestore update
  Future<String> _uploadImage(
    String tournamentId,
    File image,
    String fieldName,
  ) async {
    final ext = image.path.split('.').last.toLowerCase();
    final path =
        'sponsors/$tournamentId/$fieldName.$ext';

    final ref = _storage.ref().child(path);
    await ref.putFile(image);
    final url = await ref.getDownloadURL();

    // Update Firestore
    await _configDoc(tournamentId).set(
      {
        '${fieldName}Url': url,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );

    return url;
  }

  /// ─────────────────── Remove Methods ───────────────────

  Future<void> removeBanner(String tournamentId) async {
    await _removeImage(tournamentId, 'banner');
  }

  Future<void> removeSlot(
    String tournamentId,
    int slotNumber,
  ) async {
    await _removeImage(tournamentId, 'slot$slotNumber');
  }

  Future<void> removeCornerLogo(String tournamentId) async {
    await _removeImage(tournamentId, 'corner_logo');
  }

  Future<void> removeFpodSponsorLogo(String tournamentId) async {
    await _removeImage(tournamentId, 'fpod_sponsor');
  }

  Future<void> _removeImage(String tournamentId, String fieldName) async {
    // Remove from Firestore
    await _configDoc(tournamentId).set(
      {
        '${fieldName}Url': '',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );

    // Try to delete from Storage (ignore if not exists)
    try {
      // Try both extensions
      for (final ext in ['jpg', 'jpeg', 'png', 'webp']) {
        try {
          await _storage
              .ref()
              .child('sponsors/$tournamentId/$fieldName.$ext')
              .delete();
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// ─────────────────── Text Methods ───────────────────

  /// Save FPOD sponsor name and card title
  Future<void> saveFpodTexts({
    required String tournamentId,
    required String sponsorName,
    required String cardTitle,
  }) async {
    await _configDoc(tournamentId).set(
      {
        'fpodSponsorName': sponsorName,
        'fpodCardTitle': cardTitle,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );
  }
}