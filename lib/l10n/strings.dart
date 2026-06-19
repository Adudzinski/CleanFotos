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
      'CleanFotos finds your duplicate & similar photos and helps you delete them fast.';
  String get startAnalysis => 'Analyze My Photos';
  String get analyzingPhotos => 'Analyzing your photos…';
  String get chooseMode => 'Choose mode';
  String get refresh => 'Refresh';
  String get allClean => 'All clean! 🎉';

  // ── Modes ─────────────────────────────────────────────────────────────────
  String get groupMode => 'Group Review';
  String get groupModeDesc =>
      'See 4 similar photos at once and tap to delete.';
  String get swipeMode => 'Swipe Mode';
  String get swipeModeDesc =>
      'Swipe left to delete, right to keep — like Tinder.';

  // ── Stats ─────────────────────────────────────────────────────────────────
  String get totalPhotos => 'Total Photos';
  String get similarGroups => 'Similar Groups';
  String get librarySize => 'Library Size';
  String get couldSave => 'Could Save';
  String get freedSpace => 'Space Freed';
  String get deletedPhotos => 'Photos Deleted';

  // ── Group Review ──────────────────────────────────────────────────────────
  String groupOf(int current, int total) => 'Group $current of $total';
  String photosInGroup(int n) => '$n photos';
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

  // ── Celebration ───────────────────────────────────────────────────────────
  String deleted(int n, String size) => '$n photo${n == 1 ? '' : 's'} deleted · $size freed!';

  // ── Permissions ───────────────────────────────────────────────────────────
  String get permissionTitle => 'Photo Access Required';
  String get permissionBody =>
      'CleanFotos needs access to your photos to find duplicates. Please grant permission in Settings.';
  String get openSettings => 'Open Settings';

  // ── Error ─────────────────────────────────────────────────────────────────
  String get errorMessage => 'Something went wrong';
  String get retry => 'Try Again';

  // ── Settings ──────────────────────────────────────────────────────────────
  String get settings => 'Settings';
  String get statistics => 'Statistics';
  String get language => 'Language';
  String get monetization => 'Monetization';
  String get enableAds => 'Show Ads';
  String get adsDesc =>
      'Ads keep CleanFotos free. Thank you for your support!';
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
      'CleanFotos encuentra tus fotos duplicadas y similares y te ayuda a eliminarlas rápido.';
  @override String get startAnalysis => 'Analizar mis fotos';
  @override String get analyzingPhotos => 'Analizando tus fotos…';
  @override String get chooseMode => 'Elige modo';
  @override String get refresh => 'Actualizar';
  @override String get allClean => 'Todo limpio! 🎉';
  @override String get groupMode => 'Revisar grupos';
  @override String get groupModeDesc => 'Ve 4 fotos similares a la vez y toca para borrar.';
  @override String get swipeMode => 'Modo swipe';
  @override String get swipeModeDesc => 'Desliza izquierda para borrar, derecha para conservar.';
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
  @override String deleted(int n, String size) => '${n} foto${n == 1 ? '' : 's'} eliminada${n == 1 ? '' : 's'} · ¡$size liberado!';
  @override String get permissionTitle => 'Acceso a fotos requerido';
  @override String get permissionBody => 'CleanFotos necesita acceso a tus fotos.';
  @override String get openSettings => 'Abrir ajustes';
  @override String get errorMessage => 'Algo salió mal';
  @override String get retry => 'Reintentar';
  @override String get settings => 'Ajustes';
  @override String get statistics => 'Estadísticas';
  @override String get language => 'Idioma';
  @override String get monetization => 'Monetización';
  @override String get enableAds => 'Mostrar anuncios';
  @override String get adsDesc => '¡Los anuncios mantienen CleanFotos gratis!';
  @override String get monetizationTips => 'Formas de monetizar';
  @override String get tip1 => 'Anuncios banner e intersticiales con Google AdMob.';
  @override String get tip2 => 'Compra única "Pro" para eliminar anuncios.';
  @override String get tip3 => 'Suscripción con sincronización inteligente.';
  @override String get tip4 => 'ASO + valoraciones positivas = más descargas.';
  @override String get about => 'Acerca de';
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
      'CleanFotos findet doppelte und ähnliche Fotos und hilft dir, sie schnell zu löschen.';
  @override String get startAnalysis => 'Fotos analysieren';
  @override String get analyzingPhotos => 'Fotos werden analysiert…';
  @override String get chooseMode => 'Modus wählen';
  @override String get refresh => 'Aktualisieren';
  @override String get allClean => 'Alles sauber! 🎉';
  @override String get groupMode => 'Gruppen-Überprüfung';
  @override String get groupModeDesc => '4 ähnliche Fotos gleichzeitig anzeigen und zum Löschen tippen.';
  @override String get swipeMode => 'Wischen-Modus';
  @override String get swipeModeDesc => 'Links wischen zum Löschen, rechts zum Behalten.';
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
  @override String deleted(int n, String size) => '$n Foto${n == 1 ? '' : 's'} gelöscht · $size freigegeben!';
  @override String get permissionTitle => 'Fotozugriff erforderlich';
  @override String get permissionBody => 'CleanFotos benötigt Zugriff auf deine Fotos.';
  @override String get openSettings => 'Einstellungen öffnen';
  @override String get errorMessage => 'Etwas ist schiefgelaufen';
  @override String get retry => 'Erneut versuchen';
  @override String get settings => 'Einstellungen';
  @override String get statistics => 'Statistiken';
  @override String get language => 'Sprache';
  @override String get monetization => 'Monetarisierung';
  @override String get enableAds => 'Werbung anzeigen';
  @override String get adsDesc => 'Werbung hält CleanFotos kostenlos!';
  @override String get monetizationTips => 'Monetarisierungsoptionen';
  @override String get tip1 => 'Banner- & Interstitial-Werbung über Google AdMob.';
  @override String get tip2 => 'Einmaliger "Pro"-Kauf zum Entfernen von Werbung.';
  @override String get tip3 => 'Abonnement mit smarter Cloud-Synchronisation.';
  @override String get tip4 => 'ASO + gute Bewertungen = mehr Downloads.';
  @override String get about => 'Über';
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
      'CleanFotos trouve vos photos similaires et vous aide à les supprimer rapidement.';
  @override String get startAnalysis => 'Analyser mes photos';
  @override String get analyzingPhotos => 'Analyse en cours…';
  @override String get chooseMode => 'Choisir un mode';
  @override String get refresh => 'Actualiser';
  @override String get allClean => 'Tout est propre ! 🎉';
  @override String get groupMode => 'Révision par groupe';
  @override String get groupModeDesc => 'Voir 4 photos similaires et appuyer pour supprimer.';
  @override String get swipeMode => 'Mode swipe';
  @override String get swipeModeDesc => 'Balayez à gauche pour supprimer, à droite pour garder.';
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
  @override String deleted(int n, String size) => '$n photo${n == 1 ? '' : 's'} supprimée${n == 1 ? '' : 's'} · $size libéré !';
  @override String get permissionTitle => 'Accès aux photos requis';
  @override String get permissionBody => 'CleanFotos a besoin d\'accéder à vos photos.';
  @override String get openSettings => 'Ouvrir les paramètres';
  @override String get errorMessage => 'Une erreur s\'est produite';
  @override String get retry => 'Réessayer';
  @override String get settings => 'Paramètres';
  @override String get statistics => 'Statistiques';
  @override String get language => 'Langue';
  @override String get monetization => 'Monétisation';
  @override String get enableAds => 'Afficher les publicités';
  @override String get adsDesc => 'Les pubs gardent CleanFotos gratuit !';
  @override String get monetizationTips => 'Options de monétisation';
  @override String get tip1 => 'Publicités bannière & interstitielles via AdMob.';
  @override String get tip2 => 'Achat unique "Pro" pour supprimer les pubs.';
  @override String get tip3 => 'Abonnement avec synchronisation cloud intelligente.';
  @override String get tip4 => 'ASO + avis positifs = plus de téléchargements.';
  @override String get about => 'À propos';
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
      'CleanFotos encontra fotos duplicadas e similares e ajuda você a deletá-las rapidamente.';
  @override String get startAnalysis => 'Analisar minhas fotos';
  @override String get analyzingPhotos => 'Analisando fotos…';
  @override String get chooseMode => 'Escolha o modo';
  @override String get refresh => 'Atualizar';
  @override String get allClean => 'Tudo limpo! 🎉';
  @override String get groupMode => 'Revisão em grupo';
  @override String get groupModeDesc => 'Veja 4 fotos similares e toque para deletar.';
  @override String get swipeMode => 'Modo swipe';
  @override String get swipeModeDesc => 'Deslize para esquerda para deletar, direita para manter.';
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
  @override String deleted(int n, String size) => '$n foto${n == 1 ? '' : 's'} deletada${n == 1 ? '' : 's'} · $size liberado!';
  @override String get permissionTitle => 'Acesso às fotos necessário';
  @override String get permissionBody => 'CleanFotos precisa de acesso às suas fotos.';
  @override String get openSettings => 'Abrir configurações';
  @override String get errorMessage => 'Algo deu errado';
  @override String get retry => 'Tentar novamente';
  @override String get settings => 'Configurações';
  @override String get statistics => 'Estatísticas';
  @override String get language => 'Idioma';
  @override String get monetization => 'Monetização';
  @override String get enableAds => 'Mostrar anúncios';
  @override String get adsDesc => 'Os anúncios mantêm o CleanFotos gratuito!';
  @override String get monetizationTips => 'Formas de monetizar';
  @override String get tip1 => 'Anúncios banner e intersticiais via Google AdMob.';
  @override String get tip2 => 'Compra única "Pro" para remover anúncios.';
  @override String get tip3 => 'Assinatura com sincronização inteligente.';
  @override String get tip4 => 'ASO + avaliações positivas = mais downloads.';
  @override String get about => 'Sobre';
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
      'CleanFotos trova le tue foto duplicate e simili e ti aiuta a eliminarle velocemente.';
  @override String get startAnalysis => 'Analizza le mie foto';
  @override String get analyzingPhotos => 'Analisi in corso…';
  @override String get chooseMode => 'Scegli modalità';
  @override String get refresh => 'Aggiorna';
  @override String get allClean => 'Tutto pulito! 🎉';
  @override String get groupMode => 'Revisione per gruppo';
  @override String get groupModeDesc => 'Vedi 4 foto simili e tocca per eliminare.';
  @override String get swipeMode => 'Modalità swipe';
  @override String get swipeModeDesc => 'Scorri a sinistra per eliminare, a destra per tenere.';
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
  @override String deleted(int n, String size) => '$n foto eliminate · $size liberato!';
  @override String get permissionTitle => 'Accesso alle foto richiesto';
  @override String get permissionBody => 'CleanFotos ha bisogno di accedere alle tue foto.';
  @override String get openSettings => 'Apri impostazioni';
  @override String get errorMessage => 'Qualcosa è andato storto';
  @override String get retry => 'Riprova';
  @override String get settings => 'Impostazioni';
  @override String get statistics => 'Statistiche';
  @override String get language => 'Lingua';
  @override String get monetization => 'Monetizzazione';
  @override String get enableAds => 'Mostra pubblicità';
  @override String get adsDesc => 'Le pubblicità mantengono CleanFotos gratuito!';
  @override String get monetizationTips => 'Modi per monetizzare';
  @override String get tip1 => 'Banner e annunci interstitiziali via Google AdMob.';
  @override String get tip2 => 'Acquisto unico "Pro" per rimuovere le pub.';
  @override String get tip3 => 'Abbonamento con sincronizzazione cloud intelligente.';
  @override String get tip4 => 'ASO + recensioni positive = più download.';
  @override String get about => 'Informazioni';
  @override String get appVersion => 'Versione';
  @override String get buildWith => 'Creato con';
  @override String get developerTip => 'Consiglio';
  @override String get developerTipValue => 'Pubblica su App Store e Play Store';
}
