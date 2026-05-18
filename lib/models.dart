// Data models — GblackAI Mobile
// Mirrors the schema returned by API v12.

enum AnalysisType {
  plantPest('PLANT_PEST', '🌿 Plant / Pest'),
  satellite('SATELLITE_REMOTE_SENSING', '🛰️ Satellite'),
  drone('DRONE_ANALYSIS', '🚁 Drone');

  final String value;
  final String label;
  const AnalysisType(this.value, this.label);
}

// ─── Main response ────────────────────────────────────────────────────────────

class AnalysisResponse {
  final AnalysisSubject subject;
  final List<Detection> detections;

  const AnalysisResponse({required this.subject, required this.detections});

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisResponse(
      subject: AnalysisSubject.fromJson(json['subject'] as Map<String, dynamic>),
      detections: (json['detections'] as List<dynamic>)
          .map((d) => Detection.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'subject': subject.toJson(),
        'detections': detections.map((d) => d.toJson()).toList(),
      };
}

// ─── Identified subject ───────────────────────────────────────────────────────

class AnalysisSubject {
  final String subjectType;
  final String description;
  final double confidence;

  const AnalysisSubject({
    required this.subjectType,
    required this.description,
    required this.confidence,
  });

  factory AnalysisSubject.fromJson(Map<String, dynamic> json) {
    return AnalysisSubject(
      subjectType: json['subjectType'] as String,
      description: json['description'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'subjectType': subjectType,
        'description': description,
        'confidence': confidence,
      };
}

// ─── Detection ────────────────────────────────────────────────────────────────

class Detection {
  final String className;
  final double confidenceScore;
  final String severity;
  final String? croppedImageUrl;
  final DetectionDetails details;

  const Detection({
    required this.className,
    required this.confidenceScore,
    required this.severity,
    this.croppedImageUrl,
    required this.details,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      className: json['className'] as String,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      severity: json['severity'] as String,
      croppedImageUrl: json['croppedImageUrl'] as String?,
      details: DetectionDetails.fromJson(json['details'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'className': className,
        'confidenceScore': confidenceScore,
        'severity': severity,
        'croppedImageUrl': croppedImageUrl,
        'details': details.toJson(),
      };
}

// ─── Detection details ────────────────────────────────────────────────────────

class DetectionDetails {
  final String description;
  final String impact;
  final Recommendations recommendations;
  final List<String> knowledgeBaseTags;

  const DetectionDetails({
    required this.description,
    required this.impact,
    required this.recommendations,
    required this.knowledgeBaseTags,
  });

  factory DetectionDetails.fromJson(Map<String, dynamic> json) {
    return DetectionDetails(
      description: json['description'] as String,
      impact: json['impact'] as String,
      recommendations: Recommendations.fromJson(
        json['recommendations'] as Map<String, dynamic>,
      ),
      knowledgeBaseTags: (json['knowledgeBaseTags'] as List<dynamic>)
          .map((t) => t as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'impact': impact,
        'recommendations': recommendations.toJson(),
        'knowledgeBaseTags': knowledgeBaseTags,
      };
}

// ─── Recommendations ──────────────────────────────────────────────────────────

class Recommendations {
  final List<RecommendationItem> biological;
  final List<RecommendationItem> chemical;
  final List<RecommendationItem> cultural;

  const Recommendations({
    required this.biological,
    required this.chemical,
    required this.cultural,
  });

  factory Recommendations.fromJson(Map<String, dynamic> json) {
    List<RecommendationItem> parse(String key) =>
        (json[key] as List<dynamic>? ?? [])
            .map((r) => RecommendationItem.fromJson(r as Map<String, dynamic>))
            .toList();

    return Recommendations(
      biological: parse('biological'),
      chemical: parse('chemical'),
      cultural: parse('cultural'),
    );
  }

  Map<String, dynamic> toJson() => {
        'biological': biological.map((r) => r.toJson()).toList(),
        'chemical': chemical.map((r) => r.toJson()).toList(),
        'cultural': cultural.map((r) => r.toJson()).toList(),
      };

  bool get isEmpty =>
      biological.isEmpty && chemical.isEmpty && cultural.isEmpty;
}

class RecommendationItem {
  final String solution;
  final String details;
  final String? source;

  const RecommendationItem({
    required this.solution,
    required this.details,
    this.source,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      solution: json['solution'] as String,
      details: json['details'] as String,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'solution': solution,
        'details': details,
        'source': source,
      };
}

// ─── History entry ────────────────────────────────────────────────────────────

class HistoryEntry {
  final String id;
  final DateTime date;
  final AnalysisType analysisType;
  final AnalysisResponse response;
  final String? imagePath;

  const HistoryEntry({
    required this.id,
    required this.date,
    required this.analysisType,
    required this.response,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'analysisType': analysisType.value,
        'response': response.toJson(),
        'imagePath': imagePath,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        analysisType: AnalysisType.values.firstWhere(
          (t) => t.value == json['analysisType'],
          orElse: () => AnalysisType.plantPest,
        ),
        response: AnalysisResponse.fromJson(
            json['response'] as Map<String, dynamic>),
        imagePath: json['imagePath'] as String?,
      );
}
