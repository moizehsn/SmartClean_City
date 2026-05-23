import '../widgets/report_status_chip.dart';

// ─── Mock User ────────────────────────────────────────────────────────────────
class MockUser {
  static const String nom = 'Ahmed K.';
  static const String email = 'ahmed@example.com';
  static const String membreDepuis = 'Jan 2024';
  static const int totalSignalements = 15;
  static const int acceptes = 14;
  static const int resolus = 12;
  static const int joursActifs = 5;
  static const int score = 340;
  static const String quartier = 'Quartier El Atteuf, Laghouat';
}

// ─── Mock Report Model ────────────────────────────────────────────────────────
class MockReport {
  final String id;
  final String titre;
  final String adresse;
  final String ville;
  final String dateHeure;
  final ReportStatus statut;
  final String description;
  final String typeDechet;
  final String aiAnalyse;

  const MockReport({
    required this.id,
    required this.titre,
    required this.adresse,
    required this.ville,
    required this.dateHeure,
    required this.statut,
    required this.description,
    required this.typeDechet,
    required this.aiAnalyse,
  });
}

const List<MockReport> kMockReports = [
  MockReport(
    id: '#4829',
    titre: 'Bac plein',
    adresse: 'Sidi Yanis',
    ville: 'Laghouat',
    dateHeure: 'Il y a 2 heures',
    statut: ReportStatus.inProgress,
    description: 'Bac à ordures plein et débordant sur le trottoir.',
    typeDechet: 'Ordures ménagères',
    aiAnalyse: 'Dépassement de capacité du conteneur confirmé.',
  ),
  MockReport(
    id: '#4830',
    titre: 'Accumulation',
    adresse: 'Laghouat Centre',
    ville: 'Laghouat',
    dateHeure: 'Hier, 14:30',
    statut: ReportStatus.assigned,
    description: 'Accumulation de déchets divers au coin de rue.',
    typeDechet: 'Déchets mixtes',
    aiAnalyse: 'Accumulation de déchets confirmée.',
  ),
  MockReport(
    id: '#4831',
    titre: 'Dépôt sauvage',
    adresse: 'Rue de la République',
    ville: 'Laghouat, Algérie',
    dateHeure: 'Il y a 3 jours',
    statut: ReportStatus.pendingAdmin,
    description: 'Dépôt sauvage de gravats et plastiques.',
    typeDechet: 'Dépôt sauvage mixte (Gravats & Plastiques)',
    aiAnalyse: 'Identification confirmée de débris de construction volumineux.',
  ),
  MockReport(
    id: '#4825',
    titre: 'Dégradation mobilier',
    adresse: 'Place Centrale',
    ville: 'Laghouat',
    dateHeure: 'Il y a 5 jours',
    statut: ReportStatus.completed,
    description: 'Dégradation sur le mobilier urbain principal.',
    typeDechet: 'Mobilier urbain',
    aiAnalyse: 'Détérioration visible sur les équipements publics.',
  ),
  MockReport(
    id: '#4823',
    titre: 'Cartons abandonnés',
    adresse: 'Rue des Vergers',
    ville: 'Laghouat',
    dateHeure: 'Il y a 1 semaine',
    statut: ReportStatus.completed,
    description: 'Dépôt sauvage de cartons devant le n°42.',
    typeDechet: 'Cartons et emballages',
    aiAnalyse: 'Dépôt de cartons volumineux confirmé.',
  ),
  MockReport(
    id: '#4820',
    titre: 'Corbeille saturée',
    adresse: 'Parc des Cyprès',
    ville: 'Laghouat',
    dateHeure: 'Il y a 2 semaines',
    statut: ReportStatus.rejected,
    description: "Corbeille pleine à proximité de l'aire de jeux.",
    typeDechet: 'Ordures ménagères',
    aiAnalyse: 'Corbeille en dépassement de capacité.',
  ),
];

// ─── Mock Chat Messages ───────────────────────────────────────────────────────
class MockMessage {
  final String texte;
  final bool isUser;
  final String heure;
  const MockMessage({
    required this.texte,
    required this.isUser,
    required this.heure,
  });
}

const List<MockMessage> kMockMessages = [
  MockMessage(
    texte:
        "Bonjour ! Je suis Eco-Bot 🌿 Je peux vous aider à signaler des déchets ou répondre à vos questions sur la propreté urbaine à Laghouat.",
    isUser: false,
    heure: '09:10',
  ),
  MockMessage(
    texte: 'Où se trouve le point de collecte le plus proche ?',
    isUser: true,
    heure: '09:12',
  ),
  MockMessage(
    texte:
        "Voici le point de collecte de tri sélectif le plus proche de votre position :\n\n📍 Point de Tri — Quartier Sud\nÀ 450m  •  Verre, Plastique",
    isUser: false,
    heure: '09:12',
  ),
];
