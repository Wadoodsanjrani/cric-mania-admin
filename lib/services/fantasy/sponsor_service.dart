import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../image_helper.dart';

/// Sponsor Configuration Model (Base64 version)
class SponsorConfig {
  final String bannerBase64;
  final String slot1Base64;
  final String slot2Base64;
  final String slot3Base64;
  final String cornerLogoBase64;
  final String fpodSponsorLogoBase64;
  final String fpodSponsorName;
  final String fpodCardTitle;

  SponsorConfig({
    this.bannerBase64 = '',
    this.slot1Base64 = '',
    this.slot2Base64 = '',
    this.slot3Base64 = '',
    this.cornerLogoBase64 = '',
    this.fpodSponsorLogoBase64 = '',
    this.fpodSponsorName = '',
    this.fpodCardTitle = 'Player of the Day',
  });

  factory SponsorConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return SponsorConfig();
    return SponsorConfig(
      bannerBase64: map['bannerBase64'] ?? '',
      slot1Base64: map['slot1Base64'] ?? '',
      slot2Base64: map['slot2Base64'] ?? '',
      slot3Base64: map['slot3Base64'] ?? '',
      cornerLogoBase64: map['cornerLogoBase64'] ?? '',
      fpodSponsorLogoBase64: map['fpodSponsorLogoBase64'] ?? '',
      fpodSponsorName: map['fpodSponsorName'] ?? '',
      fpodCardTitle: map['fpodCardTitle'] ?? 'Player of the Day',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bannerBase64': bannerBase64,
      'slot1Base64': slot1Base64,
      'slot2Base64': slot2Base64,
      'slot3Base64': slot3Base64,
      'cornerLogoBase64': cornerLogoBase64,
      'fpodSponsorLogoBase64': fpodSponsorLogoBase64,
      'fpodSponsorName': fpodSponsorName,
      'fpodCardTitle': fpodCardTitle,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  bool get hasBanner => bannerBase64.isNotEmpty;
  bool get hasCornerLogo => cornerLogoBase64.isNotEmpty;
  bool get hasFpodSponsor =>
      fpodSponsorLogoBase64.isNotEmpty || fpodSponsorName.isNotEmpty;
}

/// Sponsor Service (Base64 version — no Firebase Storage needed)
/// Firestore path: tournaments/{tournamentId}/sponsors/config
class SponsorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  Future<String> uploadBanner(String tournamentId, File image) async {
    return _uploadImage(tournamentId, image, 'bannerBase64');
  }

  /// Upload slot image (1, 2, or 3)
  Future<String> uploadSlot(
    String tournamentId,
    File image,
    int slotNumber,
  ) async {
    return _uploadImage(tournamentId, image, 'slot${slotNumber}Base64');
  }

  /// Upload corner logo
  Future<String> uploadCornerLogo(String tournamentId, File image) async {
    return _uploadImage(tournamentId, image, 'cornerLogoBase64');
  }

  /// Upload FPOD sponsor logo
  Future<String> uploadFpodSponsorLogo(
    String tournamentId,
    File image,
  ) async {
    return _uploadImage(tournamentId, image, 'fpodSponsorLogoBase64');
  }

  /// Generic image upload + Firestore update (base64)
  Future<String> _uploadImage(
    String tournamentId,
    File image,
    String fieldName,
  ) async {
    // Convert to base64 (compressed)
    final base64String = await ImageHelper.fileToBase64(image);

    // Safety check
    if (!ImageHelper.isSafeForFirestore(base64String)) {
      throw Exception(
        'Image too large (${ImageHelper.base64SizeKB(base64String).toStringAsFixed(0)} KB). '
        'Please choose a smaller image.',
      );
    }

    // Update Firestore
    await _configDoc(tournamentId).set(
      {
        fieldName: base64String,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );

    return base64String;
  }

  /// ─────────────────── Remove Methods ───────────────────

  Future<void> removeBanner(String tournamentId) async {
    await _removeImage(tournamentId, 'bannerBase64');
  }

  Future<void> removeSlot(String tournamentId, int slotNumber) async {
    await _removeImage(tournamentId, 'slot${slotNumber}Base64');
  }

  Future<void> removeCornerLogo(String tournamentId) async {
    await _removeImage(tournamentId, 'cornerLogoBase64');
  }

  Future<void> removeFpodSponsorLogo(String tournamentId) async {
    await _removeImage(tournamentId, 'fpodSponsorLogoBase64');
  }

  Future<void> _removeImage(String tournamentId, String fieldName) async {
    await _configDoc(tournamentId).set(
      {
        fieldName: '',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );
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