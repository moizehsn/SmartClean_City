import 'package:flutter/material.dart';

/// Lightweight translation helper.
/// Usage: `AppLocalizations.of(context).t('key')`
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('fr'));
  }

  static const delegate = _AppLocalizationsDelegate();

  /// Returns true when the current locale is Arabic (RTL).
  bool get isArabic => locale.languageCode == 'ar';

  String t(String key) =>
      _strings[locale.languageCode]?[key] ?? _strings['fr']![key] ?? key;

  // ── Translation tables ────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _strings = {
    // ── French ───────────────────────────────────────────────────────────────
    'fr': {
      // Nav labels — Citizen
      'accueil': 'Accueil',
      'signalements': 'Signalements',
      'carte': 'Carte',
      'ecobot': 'Eco-Bot',
      'profil': 'Profil',

      // Nav labels — Driver
      'historique': 'Historique',

      // Greeting
      'bonjour': 'Bonjour,',
      'chauffeur': 'Chauffeur',

      // Accueil / dashboard
      'apercu_temps_reel': 'Aperçu en temps réel',
      'apercu_missions': 'Aperçu des missions',
      'filtres_actifs': 'Filtres actifs',
      'signalements_recents': 'Signalements récents',
      'voir_tout': 'Voir tout',
      'aucun_signalement':
          'Aucun signalement pour l\'instant.\nAppuyez sur + pour en créer un.',
      'appuyer_localiser': 'Appuyez pour localiser',

      // Stats labels
      'en_cours': 'En cours',
      'acceptes': 'Acceptés',
      'resolus': 'Résolus',
      'nouveaux': 'Nouveaux',
      'termines': 'Terminés',

      // Status labels
      'statut_en_attente': 'En attente',
      'statut_en_cours': 'En cours',
      'statut_termine': 'Terminé',
      'statut_rejete': 'Rejeté',

      // Mission section titles
      'missions_en_attente': 'Missions en attente',
      'missions_en_cours': 'Missions en cours',
      'missions_terminees': 'Missions terminées',

      // Signalements screen
      'mes_signalements': 'Mes Signalements',
      'tous': 'Tous',
      'aucun_signalement_court': 'Aucun signalement',
      'creer_premier': 'Appuyez sur + pour créer votre premier signalement.',
      'aucun_categorie': 'Aucun signalement dans cette catégorie.',
      'voir_details': 'Voir détails',
      'rapport_citoyen': 'Rapport citoyen automatique',

      // Cancel report
      'annuler_signalement': 'Annuler le signalement',
      'confirmation_annulation':
          'Voulez-vous vraiment annuler ce signalement ?\nCette action est irréversible.',
      'oui_annuler': 'Oui, annuler',
      'non': 'Non',

      // Profile screen — Citizen
      'statistiques': 'Statistiques',
      'compte': 'Compte',
      'total_signalements': 'Total\nSignalements',
      'signalements_acceptes': 'Signalements\nAcceptés',
      'signalements_resolus': 'Signalements\nRésolus',
      'jours_actifs': 'Jours\nActifs',
      'modifier_profil': 'Modifier le profil',
      'notifications': 'Notifications',
      'changer_langue': 'Changer la langue',
      'confidentialite': 'Confidentialité',
      'se_deconnecter': 'Se déconnecter',
      'membre_depuis': 'Membre depuis',

      // Profile screen — Driver
      'performance': 'Performance',
      'missions_accomplies': 'Missions Accomplies',
      'total_traites': 'Total des signalements traités',
      'conducteur_benne': 'Conducteur de camion benne',
      'camion_benne': 'Camion Benne',

      // Driver history screen
      'historique_missions': 'Historique des missions',
      'erreur_chargement': 'Erreur de chargement',
      'aucune_mission_terminee': 'Aucune mission terminée',
      'missions_terminees_ici': 'Vos missions terminées apparaîtront ici',
      'date_inconnue': 'Date inconnue',
      'avant': 'Avant',
      'apres': 'Après',
      'non_disponible': 'Non disponible',

      // Driver map screen
      'carte_missions': 'Carte des missions',
      'nouveau_signalement_map': 'Nouveau signalement',
      'mission_en_cours_map': 'Mission en cours',
      'accepter_mission': 'Accepter la mission',
      'continuer_mission': 'Continuer la mission',

      // Mission active screen
      'mission_en_cours': 'Mission en cours',
      'photo_signalement_avant': 'Photo du signalement (Avant)',
      'localisation': 'Localisation',
      'adresse': 'Adresse',
      'itineraire': 'Itinéraire',
      'photo_apres_nettoyage': 'Photo après nettoyage',
      'obligatoire_cloturer': 'Obligatoire pour clôturer la mission',
      'photo_apres_preuve':
          'La photo « Après » sera envoyée comme preuve de nettoyage et consultable par le citoyen.',
      'cloturer_mission': 'Clôturer la mission',
      'photo_apres_requise': 'Photo « Après » requise pour clôturer',
      'photo_apres_capturee': '✓ Photo « Après » capturée',
      'reprendre': 'Reprendre',
      'appuyer_prendre_photo': 'Appuyez pour prendre la photo',
      'apres_nettoyage': 'après le nettoyage',
      'photo_non_disponible': 'Photo non disponible',
      'mission_cloturee_succes': 'Mission clôturée avec succès !',
      'erreur_camera': 'Erreur caméra',
      'coordonnees_non_dispo': 'Coordonnées GPS non disponibles',
      'impossible_google_maps': 'Impossible d\'ouvrir Google Maps',
      'adresse_inconnue': 'Adresse inconnue',

      // EcoBot
      'ecobot_titre': 'Eco-Bot',
      'ecobot_en_ligne': 'IA · En ligne',
      'ecobot_typing': 'en train d\'écrire…',
      'ecobot_hint': 'Demander à Eco-Bot…',
      'ecobot_reflexion': 'Eco-Bot réfléchit',
      'ecobot_bienvenue':
          'Bonjour ! 🌿 Je suis Eco-Bot, ton assistant écologique. '
          'Comment puis-je t\'aider aujourd\'hui ?',
      'ecobot_erreur':
          'Désolé, j\'ai rencontré un problème de connexion. Veuillez réessayer. 🔄',

      // Map
      'carte_titre': 'Carte des Signalements',

      // New report
      'nouveau_signalement': 'Nouveau Signalement',

      // Errors
      'erreur_firestore': 'Erreur Firestore — copiez le lien ci-dessous',
      'erreur_inconnue': 'Erreur inconnue',

      // Timestamps
      'il_y_a_instant': 'À l\'instant',
      'il_y_a_min': 'il y a {n} min',
      'il_y_a_heures': 'il y a {n}h',
      'il_y_a_jours': 'il y a {n}j',

      // Nouveau Signalement additions
      'prenez_une_photo': 'Prenez une photo',
      'detectez_position': 'Détectez votre position',
      'photo_plus_localisation':
          'Photo + localisation suffisent — aucune description requise.',
      'soumettre_signalement': 'Soumettre le signalement',
      'photo_et_position_requises': 'Photo et position requises',
      'photo_requise': 'Photo requise',
      'position_requise': 'Position GPS requise',
      'photo_capturee_valide': '✓ Photo capturée — Signalement valide',
      'appuyez_pour_photo': 'Appuyez pour prendre une photo',
      'des_dechets': 'des déchets à signaler',
      'position_detectee': 'Position détectée',
      'echec_reessayer': 'Échec — Appuyez pour réessayer',
      'appuyez_pour_position': 'Appuyez pour détecter votre position',
      'service_desactive':
          'Le service de localisation est désactivé sur cet appareil.',
      'permission_refusee': 'Permission de localisation refusée.',
      'permission_definitivement':
          'Permission de localisation définitivement refusée. Activez-la dans les paramètres.',

      // Timeline / Details additions
      'suivi_intervention': 'Suivi de l\'intervention',
      'signalement_recu': 'Signalement reçu',
      'signalement_enregistre': 'Votre rapport a été enregistré',
      'verification_ia': 'Vérification IA',
      'analyse_photo_terminee': 'Analyse de la photo terminée',
      'assigne_equipe': 'Assigné à l\'équipe',
      'equipe_en_route': 'Équipe de nettoyage en route',
      'nettoyage_effectue': 'Nettoyage effectué',
      'confirmation_attente': 'Confirmation visuelle en attente',

      // Cancel Report Dialog
      'titre_annuler': 'Annuler le signalement',
      'contenu_annuler': 'Êtes-vous sûr de vouloir annuler ce signalement ?',
      'btn_annuler_non': 'Non',
      'btn_annuler_oui': 'Oui, annuler',

      // AI Validation & GPS Duplicate Prevention
      'verification_gps': 'Vérification GPS…',
      'analyse_ia_cours': 'Analyse IA en cours…',
      'envoi_signalement': 'Envoi du signalement…',
      'verification_nettoyage': 'Vérification IA du nettoyage…',
      'envoi_validation': 'Envoi de la validation…',
      'doublon_titre': 'Signalement existant',
      'doublon_message':
          'Un signalement existe déjà à proximité et est en cours de traitement. Merci pour votre coopération !',
      'ia_rejet_citoyen_titre': 'Photo non valide',
      'ia_rejet_citoyen_message':
          'La photo ne montre pas clairement de déchets. Veuillez vérifier la photo et réessayer.',
      'ia_rejet_chauffeur_titre': 'Photo refusée',
      'ia_rejet_chauffeur_message':
          'Le lieu ne semble pas entièrement propre. Veuillez re-nettoyer et reprendre une photo.',
      'compris': 'Compris',
      'reessayer': 'Réessayer',
    },

    // ── Arabic ────────────────────────────────────────────────────────────────
    'ar': {
      // Nav labels — Citizen
      'accueil': 'الرئيسية',
      'signalements': 'البلاغات',
      'carte': 'الخريطة',
      'ecobot': 'إيكو-بوت',
      'profil': 'حسابي',

      // Nav labels — Driver
      'historique': 'السجل',

      // Greeting
      'bonjour': 'مرحباً،',
      'chauffeur': 'السائق',

      // Accueil / dashboard
      'apercu_temps_reel': 'نظرة عامة فورية',
      'apercu_missions': 'نظرة عامة على المهام',
      'filtres_actifs': 'الفلاتر النشطة',
      'signalements_recents': 'البلاغات الأخيرة',
      'voir_tout': 'عرض الكل',
      'aucun_signalement': 'لا توجد بلاغات حتى الآن.\nاضغط + لإنشاء بلاغ جديد.',
      'appuyer_localiser': 'اضغط لتحديد الموقع',

      // Stats labels
      'en_cours': 'قيد التنفيذ',
      'acceptes': 'مقبولة',
      'resolus': 'تم حلها',
      'nouveaux': 'جديدة',
      'termines': 'منتهية',

      // Status labels
      'statut_en_attente': 'قيد الانتظار',
      'statut_en_cours': 'قيد التنفيذ',
      'statut_termine': 'منتهي',
      'statut_rejete': 'مرفوض',

      // Mission section titles
      'missions_en_attente': 'المهام قيد الانتظار',
      'missions_en_cours': 'المهام قيد التنفيذ',
      'missions_terminees': 'المهام المنتهية',

      // Signalements screen
      'mes_signalements': 'بلاغاتي',
      'tous': 'الكل',
      'aucun_signalement_court': 'لا توجد بلاغات',
      'creer_premier': 'اضغط + لإنشاء أول بلاغ.',
      'aucun_categorie': 'لا توجد بلاغات في هذه الفئة.',
      'voir_details': 'عرض التفاصيل',
      'rapport_citoyen': 'بلاغ مواطن تلقائي',

      // Cancel report
      'annuler_signalement': 'إلغاء البلاغ',
      'confirmation_annulation':
          'هل تريد حقاً إلغاء هذا البلاغ؟\nهذا الإجراء لا يمكن التراجع عنه.',
      'oui_annuler': 'نعم، إلغاء',
      'non': 'لا',

      // Profile screen — Citizen
      'statistiques': 'الإحصائيات',
      'compte': 'الحساب',
      'total_signalements': 'إجمالي\nالبلاغات',
      'signalements_acceptes': 'البلاغات\nالمقبولة',
      'signalements_resolus': 'البلاغات\nالمحلولة',
      'jours_actifs': 'أيام\nالنشاط',
      'modifier_profil': 'تعديل الملف الشخصي',
      'notifications': 'الإشعارات',
      'changer_langue': 'تغيير اللغة',
      'confidentialite': 'الخصوصية',
      'se_deconnecter': 'تسجيل الخروج',
      'membre_depuis': 'عضو منذ',

      // Profile screen — Driver
      'performance': 'الأداء',
      'missions_accomplies': 'المهام المنجزة',
      'total_traites': 'إجمالي البلاغات المعالجة',
      'conducteur_benne': 'سائق شاحنة النظافة',
      'camion_benne': 'شاحنة النظافة',

      // Driver history screen
      'historique_missions': 'سجل المهام',
      'erreur_chargement': 'خطأ في التحميل',
      'aucune_mission_terminee': 'لا توجد مهام منتهية',
      'missions_terminees_ici': 'مهامك المنتهية ستظهر هنا',
      'date_inconnue': 'تاريخ غير معروف',
      'avant': 'قبل',
      'apres': 'بعد',
      'non_disponible': 'غير متوفرة',

      // Driver map screen
      'carte_missions': 'خريطة المهام',
      'nouveau_signalement_map': 'بلاغ جديد',
      'mission_en_cours_map': 'مهمة قيد التنفيذ',
      'accepter_mission': 'قبول المهمة',
      'continuer_mission': 'متابعة المهمة',

      // Mission active screen
      'mission_en_cours': 'مهمة قيد التنفيذ',
      'photo_signalement_avant': 'صورة البلاغ (قبل)',
      'localisation': 'الموقع',
      'adresse': 'العنوان',
      'itineraire': 'المسار',
      'photo_apres_nettoyage': 'صورة بعد التنظيف',
      'obligatoire_cloturer': 'مطلوبة لإغلاق المهمة',
      'photo_apres_preuve':
          'ستُرسل صورة « بعد » كدليل على التنظيف ويمكن للمواطن الاطلاع عليها.',
      'cloturer_mission': 'إغلاق المهمة',
      'photo_apres_requise': 'صورة « بعد » مطلوبة للإغلاق',
      'photo_apres_capturee': '✓ تم التقاط صورة « بعد »',
      'reprendre': 'إعادة التقاط',
      'appuyer_prendre_photo': 'اضغط لالتقاط الصورة',
      'apres_nettoyage': 'بعد التنظيف',
      'photo_non_disponible': 'الصورة غير متوفرة',
      'mission_cloturee_succes': 'تم إغلاق المهمة بنجاح!',
      'erreur_camera': 'خطأ في الكاميرا',
      'coordonnees_non_dispo': 'إحداثيات GPS غير متوفرة',
      'impossible_google_maps': 'تعذّر فتح خرائط Google',
      'adresse_inconnue': 'عنوان غير معروف',

      // EcoBot
      'ecobot_titre': 'إيكو-بوت',
      'ecobot_en_ligne': 'ذكاء اصطناعي · متصل',
      'ecobot_typing': 'يكتب…',
      'ecobot_hint': 'اسأل إيكو-بوت…',
      'ecobot_reflexion': 'إيكو-بوت يفكر',
      'ecobot_bienvenue':
          'مرحباً! 🌿 أنا إيكو-بوت، مساعدك البيئي. كيف يمكنني مساعدتك اليوم؟',
      'ecobot_erreur':
          'عذراً، واجهت مشكلة في الاتصال. يرجى المحاولة مجدداً. 🔄',

      // Map
      'carte_titre': 'خريطة البلاغات',

      // New report
      'nouveau_signalement': 'بلاغ جديد',

      // Errors
      'erreur_firestore': 'خطأ Firestore — انسخ الرابط أدناه',
      'erreur_inconnue': 'خطأ غير معروف',

      // Timestamps
      'il_y_a_instant': 'الآن',
      'il_y_a_min': 'منذ {n} دقيقة',
      'il_y_a_heures': 'منذ {n} ساعة',
      'il_y_a_jours': 'منذ {n} يوم',

      // Nouveau Signalement additions
      'prenez_une_photo': 'التقط صورة',
      'detectez_position': 'حدد موقعك',
      'photo_plus_localisation': 'الصورة والموقع يكفيان — لا حاجة لوصف إضافي.',
      'soumettre_signalement': 'إرسال البلاغ',
      'photo_et_position_requises': 'الصورة والموقع مطلوبان',
      'photo_requise': 'الصورة مطلوبة',
      'position_requise': 'موقع GPS مطلوب',
      'photo_capturee_valide': '✓ تم التقاط الصورة — البلاغ صالح',
      'appuyez_pour_photo': 'اضغط لالتقاط صورة',
      'des_dechets': 'للنفايات المراد الإبلاغ عنها',
      'position_detectee': 'تم تحديد الموقع',
      'echec_reessayer': 'فشل — اضغط للمحاولة مرة أخرى',
      'appuyez_pour_position': 'اضغط لتحديد موقعك',
      'service_desactive': 'خدمة الموقع معطلة على هذا الجهاز.',
      'permission_refusee': 'تم رفض إذن الموقع.',
      'permission_definitivement':
          'تم رفض إذن الموقع نهائياً. قم بتفعيله من الإعدادات.',

      // Timeline / Details additions
      'suivi_intervention': 'مسار البلاغ',
      'signalement_recu': 'تم استلام البلاغ',
      'signalement_enregistre': 'تم تسجيل بلاغك',
      'verification_ia': 'تحليل الذكاء الاصطناعي',
      'analyse_photo_terminee': 'اكتمل تحليل الصورة',
      'assigne_equipe': 'تم التوجيه للفريق',
      'equipe_en_route': 'فريق التنظيف في الطريق',
      'nettoyage_effectue': 'تم التنظيف',
      'confirmation_attente': 'في انتظار التأكيد المرئي',

      // Cancel Report Dialog
      'titre_annuler': 'تأكيد حذف البلاغ',
      'contenu_annuler':
          'هل أنت متأكد أنك تريد إلغاء هذا البلاغ وحذفه نهائياً؟ لا يمكن التراجع عن هذه الخطوة.',
      'btn_annuler_non': 'تراجع',
      'btn_annuler_oui': 'نعم، احذف البلاغ',

      // AI Validation & GPS Duplicate Prevention
      'verification_gps': 'التحقق من الموقع...',
      'analyse_ia_cours': 'تحليل الذكاء الاصطناعي...',
      'envoi_signalement': 'إرسال البلاغ...',
      'verification_nettoyage': 'تحليل نظافة المكان...',
      'envoi_validation': 'إرسال التأكيد...',
      'doublon_titre': 'بلاغ مكرر',
      'doublon_message':
          'عذراً، لقد تم التبليغ عن هذا الموقع مسبقاً من طرف مواطن آخر، والعمل جارٍ عليه. شكراً لتعاونك!',
      'ia_rejet_citoyen_titre': 'صورة غير صالحة',
      'ia_rejet_citoyen_message':
          'عفواً، الصورة لا تظهر أي نفايات واضحة. يرجى التأكد من الصورة والمحاولة مجدداً.',
      'ia_rejet_chauffeur_titre': 'الصورة مرفوضة',
      'ia_rejet_chauffeur_message':
          'الصورة مرفوضة. المكان لا يبدو نظيفاً بالكامل، يرجى إعادة التنظيف والتصوير.',
      'compris': 'حسناً',
      'reessayer': 'حاول مرة أخرى',
    },
  };
}

// ── Delegate ──────────────────────────────────────────────────────────────────
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['fr', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
