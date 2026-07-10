/// Simple in-code localization (avoids code-gen dependency for initial setup).
/// Replace with generated ARB-based localizations for production.
class AppStrings {
  final String languageCode;

  const AppStrings._(this.languageCode);

  factory AppStrings.of(String code) {
    switch (code) {
      case 'es':
        return const _SpanishStrings();
      case 'de':
        return const _GermanStrings();
      case 'fr':
        return const _FrenchStrings();
      case 'pt':
        return const _PortugueseStrings();
      case 'it':
        return const _ItalianStrings();
      default:
        return const _EnglishStrings();
    }
  }

  // ── Home ──────────────────────────────────────────────────────────────────
  String get welcomeTitle => 'Clean up your photos';
  String get welcomeSubtitle =>
      'CleanPics finds your duplicate & similar photos and helps you delete them fast.';
  String get startAnalysis => 'Analyze My Photos';
  String get analyzingPhotos => 'Analyzing your photos…';
  String get refresh => 'Refresh';
  String get allClean => 'All clean! 🎉';

  // ── Modes ─────────────────────────────────────────────────────────────────
  String get coachNext => 'Next';
  String get coachDone => 'Got it';
  String get groupMode => 'Group Review';
  String get groupModeDesc =>
      'Review photos taken within 3 minutes of each other. Single photos are in Picture Swipe.';
  String get swipeMode => 'Picture Swipe';
  String get swipeModeDesc =>
      'Swipe left to delete, right to keep.';
  String get videoMode => 'Video Swipe';
  String get videoModeDesc =>
      'Swipe left to delete, right to keep, hold to preview.';
  String get swipeAnyToContinue => 'Swipe either way to continue';

  // ── Stats ─────────────────────────────────────────────────────────────────
  String get totalPhotos => 'Total Photos';
  String get similarGroups => 'Similar Groups';
  String get librarySize => 'Library Size';
  String get couldSave => 'To Be Saved';
  String get freedSpace => 'Space Freed';
  String get deletedPhotos => 'Photos Deleted';

  // ── Group Review ──────────────────────────────────────────────────────────
  String groupOf(int current, int total) => 'Group $current of $total';
  String photosInGroup(int n) => '$n photos';
  String saveUpTo(String size) => 'Save ~$size';
  String get tapToSelectDelete => 'Tap photos to mark for deletion';
  String get tapToDeselect => 'Tap again to deselect';
  String get continueBtn => 'Skip';
  String get deleteBtn => 'Delete';
  String deleteCount(int n) => 'Delete ($n)';
  String get remaining => 'left';

  // ── Swipe ─────────────────────────────────────────────────────────────────
  String get swipeHint => '← Swipe left to delete  ·  Swipe right to keep →';
  String get swipeDelete => 'Delete';
  String get swipeKeep => 'Keep';
  String get swipeDone => 'You\'re done!';
  String get deleted_noun => 'deleted';
  String get backHome => 'Back to Home';
  String get recoverHint =>
      'Deleted photos stay in your phone\'s "Recently Deleted" for ~30 days.';
  String get sponsored => 'Sponsored';
  String get adSwipeHint => 'Swipe either way to continue';

  // ── Celebration ───────────────────────────────────────────────────────────
  String deleted(int n, String size) => '$n photo${n == 1 ? '' : 's'} deleted · $size freed!';

  // ── Permissions ───────────────────────────────────────────────────────────
  String get permissionTitle => 'Photo Access Required';
  String get permissionBody =>
      'CleanPics needs access to your photos to find duplicates. Please grant permission in Settings.';
  String get openSettings => 'Open Settings';
  String get videoAccessTitle => 'Allow video access';
  String get videoAccessBody =>
      'To clean up videos, CleanPics needs access to all your videos. Open Settings and set "Photos and videos" to Allow all.';
  String get limitedAccessTitle => 'Not all photos visible';
  String get limitedAccessBody =>
      'CleanPics can only see the photos you selected. Open Settings and set "Photos and videos" to Allow all.';
  String get notNow => 'Not now';

  // ── Error ─────────────────────────────────────────────────────────────────
  String get errorMessage => 'Something went wrong';
  String get deleteFailed =>
      'Photos were not deleted. Check that CleanPics has full photo access in Settings.';
  String get retry => 'Try Again';

  // ── Settings ──────────────────────────────────────────────────────────────
  String get settings => 'Settings';
  String get cleanappsPromoTitle => 'Try CleanApps';
  String get cleanappsPromoSubtitle =>
      'Swipe away the apps you never use and free up even more space.';
  String get cleanappsPromoCta => 'Get it';
  String get statistics => 'Statistics';
  String get language => 'Language';
  String get reminders => 'Reminders';
  String get monthlyReminder => 'Monthly cleanup reminder';
  String get monthlyReminderDesc =>
      'Get a nudge once a month to tidy up your photos.';
  String get reminderTitle => 'Time to clean up! 📸';
  String get reminderBody =>
      'Free up space — review your similar photos in CleanPics.';
  String get monetization => 'Monetization';
  String get removeAds => 'Remove Ads';
  String get homeProCta => 'Remove Ads with CleanPics Pro';
  String get proTitle => 'CleanPics Pro';
  String get proDesc => 'Remove all ads forever with a one-time purchase.';
  String proButton(String price) => 'Remove Ads · $price';
  String get proButtonNoPrice => 'Remove Ads';
  String get restorePurchase => 'Restore Purchase';
  String get proUnlocked => 'Pro unlocked — thank you! 🎉';
  String get enableAds => 'Show Ads';
  String get adsDesc =>
      'Ads keep CleanPics free. Thank you for your support!';
  String get monetizationTips => 'Ways to monetize this app';
  String get tip1 =>
      'Banner & interstitial ads via Google AdMob — already wired in.';
  String get tip2 =>
      'One-time "Pro" unlock (remove ads + advanced stats) via in-app purchase.';
  String get tip3 =>
      'Subscription tier with iCloud/Google Photos smart-sync features.';
  String get tip4 =>
      'App Store Optimization + positive ratings drive organic installs.';
  String get about => 'About';
  String get privacyPolicy => 'Privacy Policy';
  String get rateApp => 'Rate CleanPics';
  String get privacyOptions => 'Ad privacy options';
  String get appVersion => 'Version';
  String get buildWith => 'Built with';
  String get developerTip => 'Tip for launch';
  String get developerTipValue => 'Submit to App Store + Play Store';
}

// ─── English ────────────────────────────────────────────────────────────────────
// Uses all the default strings defined in the base AppStrings class.
class _EnglishStrings extends AppStrings {
  const _EnglishStrings() : super._('en');
}

// ─── Spanish ──────────────────────────────────────────────────────────────────
class _SpanishStrings extends AppStrings {
  const _SpanishStrings() : super._('es');

  @override String get welcomeTitle => 'Limpia tus fotos';
  @override String get welcomeSubtitle =>
      'CleanPics encuentra tus fotos duplicadas y similares y te ayuda a eliminarlas rápido.';
  @override String get startAnalysis => 'Analizar mis fotos';
  @override String get analyzingPhotos => 'Analizando tus fotos…';
  @override String get refresh => 'Actualizar';
  @override String get allClean => 'Todo limpio! 🎉';
  @override String get coachNext => 'Siguiente';
  @override String get coachDone => 'Entendido';
  @override String get groupMode => 'Revisar grupos';
  @override String get groupModeDesc => 'Ve 4 fotos similares a la vez y toca para borrar.';
  @override String get swipeMode => 'Deslizar fotos';
  @override String get swipeModeDesc => 'Desliza izquierda para borrar, derecha para conservar.';
  @override String get videoMode => 'Deslizar videos';
  @override String get videoModeDesc => 'Desliza izquierda para borrar, derecha para conservar, mantén para ver.';
  @override String get swipeAnyToContinue => 'Desliza en cualquier dirección para continuar';
  @override String get totalPhotos => 'Total fotos';
  @override String get similarGroups => 'Grupos similares';
  @override String get librarySize => 'Tamaño';
  @override String get couldSave => 'Podrías ahorrar';
  @override String get freedSpace => 'Espacio liberado';
  @override String get deletedPhotos => 'Fotos eliminadas';
  @override String groupOf(int c, int t) => 'Grupo $c de $t';
  @override String photosInGroup(int n) => '$n fotos';
  @override String get tapToSelectDelete => 'Toca para marcar y borrar';
  @override String get tapToDeselect => 'Toca de nuevo para deseleccionar';
  @override String get continueBtn => 'Saltar';
  @override String get deleteBtn => 'Eliminar';
  @override String deleteCount(int n) => 'Eliminar ($n)';
  @override String get remaining => 'restantes';
  @override String get swipeHint => '← Desliza izq. borrar  ·  Desliza der. guardar →';
  @override String get swipeDelete => 'Borrar';
  @override String get swipeKeep => 'Guardar';
  @override String get swipeDone => '¡Listo!';
  @override String get deleted_noun => 'borradas';
  @override String get backHome => 'Volver';
  @override String get recoverHint => 'Las fotos borradas quedan en "Eliminadas recientemente" del teléfono ~30 días.';
  @override String get sponsored => 'Publicidad';
  @override String get adSwipeHint => 'Desliza en cualquier dirección para continuar';
  @override String deleted(int n, String size) => '${n} foto${n == 1 ? '' : 's'} eliminada${n == 1 ? '' : 's'} · ¡$size liberado!';
  @override String get permissionTitle => 'Acceso a fotos requerido';
  @override String get permissionBody => 'CleanPics necesita acceso a tus fotos.';
  @override String get openSettings => 'Abrir ajustes';
  @override String get videoAccessTitle => 'Permitir acceso a videos';
  @override String get videoAccessBody => 'Para limpiar videos, CleanPics necesita acceso a todos tus videos. Abre Ajustes y pon "Fotos y videos" en Permitir todo.';
  @override String get limitedAccessTitle => 'No se ven todas las fotos';
  @override String get limitedAccessBody => 'CleanPics solo puede ver las fotos que seleccionaste. Abre Ajustes y pon "Fotos y videos" en Permitir todo.';
  @override String get notNow => 'Ahora no';
  @override String get errorMessage => 'Algo salió mal';
  @override String get retry => 'Reintentar';
  @override String get settings => 'Ajustes';
  @override String get cleanappsPromoTitle => 'Prueba CleanApps';
  @override String get cleanappsPromoSubtitle => 'Desliza para desinstalar apps que no usas y libera aún más espacio.';
  @override String get cleanappsPromoCta => 'Obtener';
  @override String get statistics => 'Estadísticas';
  @override String get language => 'Idioma';
  @override String get reminders => 'Recordatorios';
  @override String get monthlyReminder => 'Recordatorio mensual';
  @override String get monthlyReminderDesc => 'Recibe un aviso una vez al mes para ordenar tus fotos.';
  @override String get reminderTitle => '¡Hora de limpiar! 📸';
  @override String get reminderBody => 'Libera espacio: revisa tus fotos similares en CleanPics.';
  @override String get monetization => 'Monetización';
  @override String saveUpTo(String size) => 'Ahorra ~$size';
  @override String get removeAds => 'Quitar anuncios';
  @override String get homeProCta => 'Quita los anuncios con CleanPics Pro';
  @override String get proTitle => 'CleanPics Pro';
  @override String get proDesc => 'Elimina todos los anuncios para siempre con una compra única.';
  @override String proButton(String price) => 'Quitar anuncios · $price';
  @override String get proButtonNoPrice => 'Quitar anuncios';
  @override String get restorePurchase => 'Restaurar compra';
  @override String get proUnlocked => 'Pro activado — ¡gracias! 🎉';
  @override String get enableAds => 'Mostrar anuncios';
  @override String get adsDesc => '¡Los anuncios mantienen CleanPics gratis!';
  @override String get monetizationTips => 'Formas de monetizar';
  @override String get tip1 => 'Anuncios banner e intersticiales con Google AdMob.';
  @override String get tip2 => 'Compra única "Pro" para eliminar anuncios.';
  @override String get tip3 => 'Suscripción con sincronización inteligente.';
  @override String get tip4 => 'ASO + valoraciones positivas = más descargas.';
  @override String get about => 'Acerca de';
  @override String get privacyPolicy => 'Política de privacidad';
  @override String get rateApp => 'Valorar CleanPics';
  @override String get privacyOptions => 'Opciones de privacidad de anuncios';
  @override String get appVersion => 'Versión';
  @override String get buildWith => 'Creado con';
  @override String get developerTip => 'Consejo';
  @override String get developerTipValue => 'Lanza en App Store y Play Store';
}

// ─── German ───────────────────────────────────────────────────────────────────
class _GermanStrings extends AppStrings {
  const _GermanStrings() : super._('de');

  @override String get welcomeTitle => 'Fotos aufräumen';
  @override String get welcomeSubtitle =>
      'CleanPics findet doppelte und ähnliche Fotos und hilft dir, sie schnell zu löschen.';
  @override String get startAnalysis => 'Fotos analysieren';
  @override String get analyzingPhotos => 'Fotos werden analysiert…';
  @override String get refresh => 'Aktualisieren';
  @override String get allClean => 'Alles sauber! 🎉';
  @override String get coachNext => 'Weiter';
  @override String get coachDone => 'Verstanden';
  @override String get groupMode => 'Gruppen ansehen';
  @override String get groupModeDesc => '4 ähnliche Fotos gleichzeitig anzeigen und zum Löschen tippen.';
  @override String get swipeMode => 'Bilder wischen';
  @override String get swipeModeDesc => 'Links wischen zum Löschen, rechts zum Behalten.';
  @override String get videoMode => 'Videos wischen';
  @override String get videoModeDesc => 'Links wischen zum Löschen, rechts zum Behalten, halten zum Ansehen.';
  @override String get swipeAnyToContinue => 'In beide Richtungen wischen zum Fortfahren';
  @override String get totalPhotos => 'Fotos gesamt';
  @override String get similarGroups => 'Ähnliche Gruppen';
  @override String get librarySize => 'Bibliotheksgröße';
  @override String get couldSave => 'Einsparpotenzial';
  @override String get freedSpace => 'Freigegebener Speicher';
  @override String get deletedPhotos => 'Gelöschte Fotos';
  @override String groupOf(int c, int t) => 'Gruppe $c von $t';
  @override String photosInGroup(int n) => '$n Fotos';
  @override String get tapToSelectDelete => 'Tippe, um zum Löschen zu markieren';
  @override String get tapToDeselect => 'Nochmal tippen zum Abwählen';
  @override String get continueBtn => 'Überspringen';
  @override String get deleteBtn => 'Löschen';
  @override String deleteCount(int n) => 'Löschen ($n)';
  @override String get remaining => 'verbleibend';
  @override String get swipeHint => '← Links: löschen  ·  Rechts: behalten →';
  @override String get swipeDelete => 'Löschen';
  @override String get swipeKeep => 'Behalten';
  @override String get swipeDone => 'Fertig!';
  @override String get deleted_noun => 'gelöscht';
  @override String get backHome => 'Zurück';
  @override String get recoverHint => 'Gelöschte Fotos bleiben ~30 Tage im Ordner „Zuletzt gelöscht" deines Handys.';
  @override String get sponsored => 'Anzeige';
  @override String get adSwipeHint => 'Wische in eine Richtung, um fortzufahren';
  @override String deleted(int n, String size) => '$n Foto${n == 1 ? '' : 's'} gelöscht · $size freigegeben!';
  @override String get permissionTitle => 'Fotozugriff erforderlich';
  @override String get permissionBody => 'CleanPics benötigt Zugriff auf deine Fotos.';
  @override String get openSettings => 'Einstellungen öffnen';
  @override String get videoAccessTitle => 'Videozugriff erlauben';
  @override String get videoAccessBody => 'Um Videos aufzuräumen, benötigt CleanPics Zugriff auf alle deine Videos. Öffne die Einstellungen und stelle „Fotos und Videos" auf Alle zulassen.';
  @override String get limitedAccessTitle => 'Nicht alle Fotos sichtbar';
  @override String get limitedAccessBody => 'CleanPics sieht nur die von dir ausgewählten Fotos. Öffne die Einstellungen und stelle „Fotos und Videos" auf Alle zulassen.';
  @override String get notNow => 'Nicht jetzt';
  @override String get errorMessage => 'Etwas ist schiefgelaufen';
  @override String get retry => 'Erneut versuchen';
  @override String get settings => 'Einstellungen';
  @override String get cleanappsPromoTitle => 'CleanApps ausprobieren';
  @override String get cleanappsPromoSubtitle => 'Wische ungenutzte Apps weg und schaffe noch mehr Platz.';
  @override String get cleanappsPromoCta => 'Installieren';
  @override String get statistics => 'Statistiken';
  @override String get language => 'Sprache';
  @override String get reminders => 'Erinnerungen';
  @override String get monthlyReminder => 'Monatliche Erinnerung';
  @override String get monthlyReminderDesc => 'Erhalte einmal im Monat einen Hinweis, deine Fotos aufzuräumen.';
  @override String get reminderTitle => 'Zeit zum Aufräumen! 📸';
  @override String get reminderBody => 'Schaffe Platz – überprüfe deine ähnlichen Fotos in CleanPics.';
  @override String get monetization => 'Monetarisierung';
  @override String saveUpTo(String size) => 'Spare ~$size';
  @override String get removeAds => 'Werbung entfernen';
  @override String get homeProCta => 'Werbung entfernen mit CleanPics Pro';
  @override String get proTitle => 'CleanPics Pro';
  @override String get proDesc => 'Entferne alle Werbung dauerhaft mit einem einmaligen Kauf.';
  @override String proButton(String price) => 'Werbung entfernen · $price';
  @override String get proButtonNoPrice => 'Werbung entfernen';
  @override String get restorePurchase => 'Kauf wiederherstellen';
  @override String get proUnlocked => 'Pro freigeschaltet — danke! 🎉';
  @override String get enableAds => 'Werbung anzeigen';
  @override String get adsDesc => 'Werbung hält CleanPics kostenlos!';
  @override String get monetizationTips => 'Monetarisierungsoptionen';
  @override String get tip1 => 'Banner- & Interstitial-Werbung über Google AdMob.';
  @override String get tip2 => 'Einmaliger "Pro"-Kauf zum Entfernen von Werbung.';
  @override String get tip3 => 'Abonnement mit smarter Cloud-Synchronisation.';
  @override String get tip4 => 'ASO + gute Bewertungen = mehr Downloads.';
  @override String get about => 'Über';
  @override String get privacyPolicy => 'Datenschutz';
  @override String get rateApp => 'CleanPics bewerten';
  @override String get privacyOptions => 'Datenschutzoptionen für Werbung';
  @override String get appVersion => 'Version';
  @override String get buildWith => 'Erstellt mit';
  @override String get developerTip => 'Tipp';
  @override String get developerTipValue => 'App Store & Play Store veröffentlichen';
}

// ─── French ───────────────────────────────────────────────────────────────────
class _FrenchStrings extends AppStrings {
  const _FrenchStrings() : super._('fr');

  @override String get welcomeTitle => 'Nettoyez vos photos';
  @override String get welcomeSubtitle =>
      'CleanPics trouve vos photos similaires et vous aide à les supprimer rapidement.';
  @override String get startAnalysis => 'Analyser mes photos';
  @override String get analyzingPhotos => 'Analyse en cours…';
  @override String get refresh => 'Actualiser';
  @override String get allClean => 'Tout est propre ! 🎉';
  @override String get coachNext => 'Suivant';
  @override String get coachDone => 'Compris';
  @override String get groupMode => 'Révision par groupe';
  @override String get groupModeDesc => 'Voir 4 photos similaires et appuyer pour supprimer.';
  @override String get swipeMode => 'Balayer les photos';
  @override String get swipeModeDesc => 'Balayez à gauche pour supprimer, à droite pour garder.';
  @override String get videoMode => 'Balayer les vidéos';
  @override String get videoModeDesc => 'Balayez à gauche pour supprimer, à droite pour garder, maintenez pour prévisualiser.';
  @override String get swipeAnyToContinue => 'Balayez dans un sens ou l\'autre pour continuer';
  @override String get totalPhotos => 'Total photos';
  @override String get similarGroups => 'Groupes similaires';
  @override String get librarySize => 'Taille de la bibliothèque';
  @override String get couldSave => 'Économies possibles';
  @override String get freedSpace => 'Espace libéré';
  @override String get deletedPhotos => 'Photos supprimées';
  @override String groupOf(int c, int t) => 'Groupe $c sur $t';
  @override String photosInGroup(int n) => '$n photos';
  @override String get tapToSelectDelete => 'Appuyez pour marquer à supprimer';
  @override String get tapToDeselect => 'Appuyez à nouveau pour déselectionner';
  @override String get continueBtn => 'Passer';
  @override String get deleteBtn => 'Supprimer';
  @override String deleteCount(int n) => 'Supprimer ($n)';
  @override String get remaining => 'restantes';
  @override String get swipeHint => '← Gauche: supprimer  ·  Droite: garder →';
  @override String get swipeDelete => 'Supprimer';
  @override String get swipeKeep => 'Garder';
  @override String get swipeDone => 'Terminé !';
  @override String get deleted_noun => 'supprimées';
  @override String get backHome => 'Retour';
  @override String get recoverHint => 'Les photos supprimées restent ~30 jours dans « Supprimées récemment ».';
  @override String get sponsored => 'Sponsorisé';
  @override String get adSwipeHint => 'Balayez dans un sens pour continuer';
  @override String deleted(int n, String size) => '$n photo${n == 1 ? '' : 's'} supprimée${n == 1 ? '' : 's'} · $size libéré !';
  @override String get permissionTitle => 'Accès aux photos requis';
  @override String get permissionBody => 'CleanPics a besoin d\'accéder à vos photos.';
  @override String get openSettings => 'Ouvrir les paramètres';
  @override String get videoAccessTitle => 'Autoriser l\'accès aux vidéos';
  @override String get videoAccessBody => 'Pour nettoyer les vidéos, CleanPics a besoin d\'accéder à toutes vos vidéos. Ouvrez les Paramètres et réglez « Photos et vidéos » sur Tout autoriser.';
  @override String get limitedAccessTitle => 'Toutes les photos ne sont pas visibles';
  @override String get limitedAccessBody => 'CleanPics ne voit que les photos que vous avez sélectionnées. Ouvrez les Paramètres et réglez « Photos et vidéos » sur Tout autoriser.';
  @override String get notNow => 'Pas maintenant';
  @override String get errorMessage => 'Une erreur s\'est produite';
  @override String get retry => 'Réessayer';
  @override String get settings => 'Paramètres';
  @override String get cleanappsPromoTitle => 'Essayez CleanApps';
  @override String get cleanappsPromoSubtitle => 'Balayez pour désinstaller les apps inutilisées et libérez encore plus d\'espace.';
  @override String get cleanappsPromoCta => 'Obtenir';
  @override String get statistics => 'Statistiques';
  @override String get language => 'Langue';
  @override String get reminders => 'Rappels';
  @override String get monthlyReminder => 'Rappel mensuel';
  @override String get monthlyReminderDesc => 'Recevez un rappel une fois par mois pour ranger vos photos.';
  @override String get reminderTitle => 'C\'est l\'heure du tri ! 📸';
  @override String get reminderBody => 'Libérez de l\'espace : passez en revue vos photos similaires dans CleanPics.';
  @override String get monetization => 'Monétisation';
  @override String saveUpTo(String size) => 'Gagnez ~$size';
  @override String get removeAds => 'Supprimer les pubs';
  @override String get homeProCta => 'Supprimez les pubs avec CleanPics Pro';
  @override String get proTitle => 'CleanPics Pro';
  @override String get proDesc => 'Supprimez toutes les pubs pour toujours avec un achat unique.';
  @override String proButton(String price) => 'Supprimer les pubs · $price';
  @override String get proButtonNoPrice => 'Supprimer les pubs';
  @override String get restorePurchase => 'Restaurer l\'achat';
  @override String get proUnlocked => 'Pro activé — merci ! 🎉';
  @override String get enableAds => 'Afficher les publicités';
  @override String get adsDesc => 'Les pubs gardent CleanPics gratuit !';
  @override String get monetizationTips => 'Options de monétisation';
  @override String get tip1 => 'Publicités bannière & interstitielles via AdMob.';
  @override String get tip2 => 'Achat unique "Pro" pour supprimer les pubs.';
  @override String get tip3 => 'Abonnement avec synchronisation cloud intelligente.';
  @override String get tip4 => 'ASO + avis positifs = plus de téléchargements.';
  @override String get about => 'À propos';
  @override String get privacyPolicy => 'Politique de confidentialité';
  @override String get rateApp => 'Noter CleanPics';
  @override String get privacyOptions => 'Options de confidentialité des annonces';
  @override String get appVersion => 'Version';
  @override String get buildWith => 'Créé avec';
  @override String get developerTip => 'Conseil';
  @override String get developerTipValue => 'Publier sur App Store & Play Store';
}

// ─── Portuguese ───────────────────────────────────────────────────────────────
class _PortugueseStrings extends AppStrings {
  const _PortugueseStrings() : super._('pt');

  @override String get welcomeTitle => 'Organize suas fotos';
  @override String get welcomeSubtitle =>
      'CleanPics encontra fotos duplicadas e similares e ajuda você a deletá-las rapidamente.';
  @override String get startAnalysis => 'Analisar minhas fotos';
  @override String get analyzingPhotos => 'Analisando fotos…';
  @override String get refresh => 'Atualizar';
  @override String get allClean => 'Tudo limpo! 🎉';
  @override String get coachNext => 'Próximo';
  @override String get coachDone => 'Entendi';
  @override String get groupMode => 'Revisão em grupo';
  @override String get groupModeDesc => 'Veja 4 fotos similares e toque para deletar.';
  @override String get swipeMode => 'Deslizar fotos';
  @override String get swipeModeDesc => 'Deslize para esquerda para deletar, direita para manter.';
  @override String get videoMode => 'Deslizar vídeos';
  @override String get videoModeDesc => 'Deslize à esquerda para apagar, à direita para manter, segure para pré-visualizar.';
  @override String get swipeAnyToContinue => 'Deslize para qualquer lado para continuar';
  @override String get totalPhotos => 'Total de fotos';
  @override String get similarGroups => 'Grupos similares';
  @override String get librarySize => 'Tamanho';
  @override String get couldSave => 'Pode economizar';
  @override String get freedSpace => 'Espaço liberado';
  @override String get deletedPhotos => 'Fotos deletadas';
  @override String groupOf(int c, int t) => 'Grupo $c de $t';
  @override String photosInGroup(int n) => '$n fotos';
  @override String get tapToSelectDelete => 'Toque para marcar para deletar';
  @override String get tapToDeselect => 'Toque novamente para desmarcar';
  @override String get continueBtn => 'Pular';
  @override String get deleteBtn => 'Deletar';
  @override String deleteCount(int n) => 'Deletar ($n)';
  @override String get remaining => 'restantes';
  @override String get swipeHint => '← Esq: deletar  ·  Dir: manter →';
  @override String get swipeDelete => 'Deletar';
  @override String get swipeKeep => 'Manter';
  @override String get swipeDone => 'Concluído!';
  @override String get deleted_noun => 'deletadas';
  @override String get backHome => 'Voltar';
  @override String get recoverHint => 'Fotos apagadas ficam ~30 dias em "Apagadas recentemente" do telefone.';
  @override String get sponsored => 'Patrocinado';
  @override String get adSwipeHint => 'Deslize para qualquer lado para continuar';
  @override String deleted(int n, String size) => '$n foto${n == 1 ? '' : 's'} deletada${n == 1 ? '' : 's'} · $size liberado!';
  @override String get permissionTitle => 'Acesso às fotos necessário';
  @override String get permissionBody => 'CleanPics precisa de acesso às suas fotos.';
  @override String get openSettings => 'Abrir configurações';
  @override String get videoAccessTitle => 'Permitir acesso a vídeos';
  @override String get videoAccessBody => 'Para limpar vídeos, o CleanPics precisa de acesso a todos os seus vídeos. Abra as Configurações e defina "Fotos e vídeos" como Permitir tudo.';
  @override String get limitedAccessTitle => 'Nem todas as fotos estão visíveis';
  @override String get limitedAccessBody => 'O CleanPics só vê as fotos que você selecionou. Abra as Configurações e defina "Fotos e vídeos" como Permitir tudo.';
  @override String get notNow => 'Agora não';
  @override String get errorMessage => 'Algo deu errado';
  @override String get retry => 'Tentar novamente';
  @override String get settings => 'Configurações';
  @override String get cleanappsPromoTitle => 'Experimente CleanApps';
  @override String get cleanappsPromoSubtitle => 'Deslize para desinstalar apps que não usa e libere ainda mais espaço.';
  @override String get cleanappsPromoCta => 'Obter';
  @override String get statistics => 'Estatísticas';
  @override String get language => 'Idioma';
  @override String get reminders => 'Lembretes';
  @override String get monthlyReminder => 'Lembrete mensal';
  @override String get monthlyReminderDesc => 'Receba um aviso uma vez por mês para organizar suas fotos.';
  @override String get reminderTitle => 'Hora de limpar! 📸';
  @override String get reminderBody => 'Libere espaço — revise suas fotos similares no CleanPics.';
  @override String get monetization => 'Monetização';
  @override String saveUpTo(String size) => 'Economize ~$size';
  @override String get removeAds => 'Remover anúncios';
  @override String get homeProCta => 'Remova os anúncios com CleanPics Pro';
  @override String get proTitle => 'CleanPics Pro';
  @override String get proDesc => 'Remova todos os anúncios para sempre com uma compra única.';
  @override String proButton(String price) => 'Remover anúncios · $price';
  @override String get proButtonNoPrice => 'Remover anúncios';
  @override String get restorePurchase => 'Restaurar compra';
  @override String get proUnlocked => 'Pro ativado — obrigado! 🎉';
  @override String get enableAds => 'Mostrar anúncios';
  @override String get adsDesc => 'Os anúncios mantêm o CleanPics gratuito!';
  @override String get monetizationTips => 'Formas de monetizar';
  @override String get tip1 => 'Anúncios banner e intersticiais via Google AdMob.';
  @override String get tip2 => 'Compra única "Pro" para remover anúncios.';
  @override String get tip3 => 'Assinatura com sincronização inteligente.';
  @override String get tip4 => 'ASO + avaliações positivas = mais downloads.';
  @override String get about => 'Sobre';
  @override String get privacyPolicy => 'Política de privacidade';
  @override String get rateApp => 'Avaliar o CleanPics';
  @override String get privacyOptions => 'Opções de privacidade de anúncios';
  @override String get appVersion => 'Versão';
  @override String get buildWith => 'Criado com';
  @override String get developerTip => 'Dica';
  @override String get developerTipValue => 'Publicar na App Store e Play Store';
}

// ─── Italian ──────────────────────────────────────────────────────────────────
class _ItalianStrings extends AppStrings {
  const _ItalianStrings() : super._('it');

  @override String get welcomeTitle => 'Pulisci le tue foto';
  @override String get welcomeSubtitle =>
      'CleanPics trova le tue foto duplicate e simili e ti aiuta a eliminarle velocemente.';
  @override String get startAnalysis => 'Analizza le mie foto';
  @override String get analyzingPhotos => 'Analisi in corso…';
  @override String get refresh => 'Aggiorna';
  @override String get allClean => 'Tutto pulito! 🎉';
  @override String get coachNext => 'Avanti';
  @override String get coachDone => 'Capito';
  @override String get groupMode => 'Revisione per gruppo';
  @override String get groupModeDesc => 'Vedi 4 foto simili e tocca per eliminare.';
  @override String get swipeMode => 'Scorri foto';
  @override String get swipeModeDesc => 'Scorri a sinistra per eliminare, a destra per tenere.';
  @override String get videoMode => 'Scorri video';
  @override String get videoModeDesc => 'Scorri a sinistra per eliminare, a destra per tenere, tieni premuto per vedere.';
  @override String get swipeAnyToContinue => 'Scorri in una direzione per continuare';
  @override String get totalPhotos => 'Foto totali';
  @override String get similarGroups => 'Gruppi simili';
  @override String get librarySize => 'Dimensione libreria';
  @override String get couldSave => 'Potresti risparmiare';
  @override String get freedSpace => 'Spazio liberato';
  @override String get deletedPhotos => 'Foto eliminate';
  @override String groupOf(int c, int t) => 'Gruppo $c di $t';
  @override String photosInGroup(int n) => '$n foto';
  @override String get tapToSelectDelete => 'Tocca per selezionare da eliminare';
  @override String get tapToDeselect => 'Tocca di nuovo per deselezionare';
  @override String get continueBtn => 'Salta';
  @override String get deleteBtn => 'Elimina';
  @override String deleteCount(int n) => 'Elimina ($n)';
  @override String get remaining => 'rimanenti';
  @override String get swipeHint => '← Sin: elimina  ·  Des: tieni →';
  @override String get swipeDelete => 'Elimina';
  @override String get swipeKeep => 'Tieni';
  @override String get swipeDone => 'Fatto!';
  @override String get deleted_noun => 'eliminate';
  @override String get backHome => 'Torna alla home';
  @override String get recoverHint => 'Le foto eliminate restano ~30 giorni in "Eliminate di recente".';
  @override String get sponsored => 'Sponsorizzato';
  @override String get adSwipeHint => 'Scorri in una direzione per continuare';
  @override String deleted(int n, String size) => '$n foto eliminate · $size liberato!';
  @override String get permissionTitle => 'Accesso alle foto richiesto';
  @override String get permissionBody => 'CleanPics ha bisogno di accedere alle tue foto.';
  @override String get openSettings => 'Apri impostazioni';
  @override String get videoAccessTitle => 'Consenti accesso ai video';
  @override String get videoAccessBody => 'Per pulire i video, CleanPics ha bisogno di accedere a tutti i tuoi video. Apri le Impostazioni e imposta "Foto e video" su Consenti tutto.';
  @override String get limitedAccessTitle => 'Non tutte le foto sono visibili';
  @override String get limitedAccessBody => 'CleanPics vede solo le foto che hai selezionato. Apri le Impostazioni e imposta "Foto e video" su Consenti tutto.';
  @override String get notNow => 'Non ora';
  @override String get errorMessage => 'Qualcosa è andato storto';
  @override String get retry => 'Riprova';
  @override String get settings => 'Impostazioni';
  @override String get cleanappsPromoTitle => 'Prova CleanApps';
  @override String get cleanappsPromoSubtitle => 'Scorri per disinstallare le app inutilizzate e libera ancora più spazio.';
  @override String get cleanappsPromoCta => 'Scarica';
  @override String get statistics => 'Statistiche';
  @override String get language => 'Lingua';
  @override String get reminders => 'Promemoria';
  @override String get monthlyReminder => 'Promemoria mensile';
  @override String get monthlyReminderDesc => 'Ricevi un promemoria una volta al mese per sistemare le tue foto.';
  @override String get reminderTitle => 'È ora di fare pulizia! 📸';
  @override String get reminderBody => 'Libera spazio: rivedi le tue foto simili in CleanPics.';
  @override String get monetization => 'Monetizzazione';
  @override String saveUpTo(String size) => 'Risparmia ~$size';
  @override String get removeAds => 'Rimuovi pubblicità';
  @override String get homeProCta => 'Rimuovi la pubblicità con CleanPics Pro';
  @override String get proTitle => 'CleanPics Pro';
  @override String get proDesc => 'Rimuovi tutta la pubblicità per sempre con un acquisto unico.';
  @override String proButton(String price) => 'Rimuovi pubblicità · $price';
  @override String get proButtonNoPrice => 'Rimuovi pubblicità';
  @override String get restorePurchase => 'Ripristina acquisto';
  @override String get proUnlocked => 'Pro attivato — grazie! 🎉';
  @override String get enableAds => 'Mostra pubblicità';
  @override String get adsDesc => 'Le pubblicità mantengono CleanPics gratuito!';
  @override String get monetizationTips => 'Modi per monetizzare';
  @override String get tip1 => 'Banner e annunci interstitiziali via Google AdMob.';
  @override String get tip2 => 'Acquisto unico "Pro" per rimuovere le pub.';
  @override String get tip3 => 'Abbonamento con sincronizzazione cloud intelligente.';
  @override String get tip4 => 'ASO + recensioni positive = più download.';
  @override String get about => 'Informazioni';
  @override String get privacyPolicy => 'Informativa sulla privacy';
  @override String get rateApp => 'Valuta CleanPics';
  @override String get privacyOptions => 'Opzioni privacy degli annunci';
  @override String get appVersion => 'Versione';
  @override String get buildWith => 'Creato con';
  @override String get developerTip => 'Consiglio';
  @override String get developerTipValue => 'Pubblica su App Store e Play Store';
}
