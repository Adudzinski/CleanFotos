import '../models/delete_result.dart' show MediaKind;

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
      case 'pl':
        return const _PolishStrings();
      default:
        return const _EnglishStrings();
    }
  }

  // ── Home ──────────────────────────────────────────────────────────────────
  String get analyzingPhotos => 'Analyzing your photos…';
  String get allClean => 'All clean! 🎉';

  // ── Progress (Settings) ───────────────────────────────────────────────────
  String get freedSpace => 'Space Freed';
  String get deletedPhotos => 'Photos Deleted';

  // ── Cleanup modes ─────────────────────────────────────────────────────────
  String get swipeDelete => 'Delete';
  String get swipeKeep => 'Keep';
  String get backHome => 'Back to home';
  String get sponsored => 'Sponsored';
  String get adSwipeHint => 'Swipe either way to continue';

  // ── Permissions ───────────────────────────────────────────────────────────
  String get permissionTitle => 'Photo Access Required';
  String get permissionBody =>
      'CleanFotos needs access to your photos to find duplicates. Please grant permission in Settings.';
  String get openSettings => 'Open Settings';
  String get videoAccessTitle => 'Allow video access';
  String get videoAccessBody =>
      'To clean up videos, CleanFotos needs access to all your videos. Open Settings and set "Photos and videos" to Allow all.';
  String get limitedAccessTitle => 'Not all photos visible';
  String get limitedAccessBody =>
      'CleanFotos can only see the photos you selected. Open Settings and set "Photos and videos" to Allow all.';
  String get notNow => 'Not now';

  // ── Unfinished cleanup (marks that survived the app closing) ──────────────
  String get pendingTitle => 'Finish your cleanup';
  String pendingBody(int n) =>
      'You marked $n item${n == 1 ? '' : 's'} for deletion last time but didn\'t '
      'confirm it. Delete them now?';
  String get pendingConfirm => 'Delete them';
  String get pendingLater => 'Keep them';

  // ── Error ─────────────────────────────────────────────────────────────────
  String get errorMessage => 'Something went wrong';
  String get retry => 'Try Again';

  // ── Settings ──────────────────────────────────────────────────────────────
  String get settings => 'Settings';
  String get cleanappsPromoTitle => 'Try CleanApps';
  String get cleanappsPromoSubtitle =>
      'Swipe away the apps you never use and free up even more space.';
  String get cleanappsPromoCta => 'Get it';
  String get language => 'Language';
  // ── Theme ─────────────────────────────────────────────────────────────────
  String get feedback => 'Feedback';
  String get sounds => 'Sounds';
  String get haptics => 'Haptics';
  String get reminderTitle => 'Time to clean up! 📸';
  String get reminderBody =>
      'Free up space — review your similar photos in CleanFotos.';
  String get removeAds => 'Remove Ads';
  String get proTitle => 'CleanFotos Pro';
  String get proDesc => 'Remove all ads forever with a one-time purchase.';
  String proButton(String price) => 'Remove Ads · $price';
  String get proButtonNoPrice => 'Remove Ads';
  String get proUnavailable =>
      'The purchase isn\'t available right now. Please try again later.';
  String get restorePurchase => 'Restore Purchase';
  String get proUnlocked => 'Pro unlocked — thank you! 🎉';
  String get about => 'About';
  String get privacyPolicy => 'Privacy Policy';
  String get rateApp => 'Rate CleanFotos';
  String get privacyOptions => 'Ad privacy options';
  String get appVersion => 'Version';

  // ══ 1.3 Noir ══════════════════════════════════════════════════════════════

  // ── Home ──────────────────────────────────────────────────────────────────
  String get homeTitle => 'Clean up your library';
  String tabPhotos(String n) => 'Photos · $n';
  String tabVideos(String n) => 'Videos · $n';
  /// The Videos tab before we're allowed to count them.
  String get videosLabel => 'Videos';
  String get upToDate => 'Up to date · checked just now';
  String checkedAgo(int m) => 'Up to date · checked $m min ago';
  String get lookingForNew => 'Looking for new photos…';
  String get similarShots => 'Similar shots';
  String get similarShotsDesc => 'Bursts and retakes, grouped together.';
  String get similarClips => 'Similar clips';
  String get similarClipsDesc => 'Videos shot minutes apart, side by side.';
  String get swipe => 'Swipe';
  String get swipePhotosDesc => 'Every photo, newest first.';
  String get swipeVideosDesc => 'Every video, newest first. Hold to play.';
  String get findingGroups => 'Finding groups…';
  String get allowAccess => 'Allow access';
  String get selectMorePhotos => 'Select more photos';
  String get limitedAccessBodyIos =>
      'CleanFotos can only see the photos you selected. Select more, or allow full access in Settings.';
  String get nextMilestone => 'Next milestone';
  String toGo(String size) => '$size to go';
  String ofFreed(String size) => 'of $size freed';
  String firstMilestone(String size) => 'Free your first $size';
  String allMilestones(String size) => 'All milestones reached · $size freed';
  String get removeAdsLink => 'Remove ads · one-time purchase';

  // ── Counted nouns ([f] is the locale-formatted number) ────────────────────
  String groupsCount(int n, String f) => '$f group${n == 1 ? '' : 's'}';
  String photosCount(int n, String f) => '$f photo${n == 1 ? '' : 's'}';
  String videosCount(int n, String f) => '$f video${n == 1 ? '' : 's'}';
  String itemsCount(int n, String f) => '$f item${n == 1 ? '' : 's'}';
  String mediaCount(MediaKind k, int n, String f) => switch (k) {
        MediaKind.photos => photosCount(n, f),
        MediaKind.videos => videosCount(n, f),
        MediaKind.items => itemsCount(n, f),
      };

  // ── Cleanup session ───────────────────────────────────────────────────────
  String reviewed(String n) => '$n reviewed';
  String markedPending(String n, String size) => '$n marked · ~$size';
  String get confirmOnceNote =>
      'Marked photos are deleted when you finish — you confirm once.';
  String get confirmOnceNoteVideos =>
      'Marked videos are deleted when you finish — you confirm once.';
  String get swipeFirstHint => 'Swipe left to delete · right to keep';
  String get finish => 'Finish';
  String get undo => 'Undo';
  String get back => 'Back';
  String get holdToPlay => 'Hold to play';
  String get playing => 'Playing…';
  String similarCount(int n) => '$n similar photos';
  String similarClipsCount(int n) => '$n similar videos';
  String get tapToMark => "Tap the photos you don't want";
  String get tapToMarkVideos => "Tap the videos you don't want · Hold to play";
  String get keepAllNext => 'Keep all · Next';
  String deleteNext(int n) => 'Delete $n · Next';
  String get keepAllFinish => 'Keep all · Finish';
  String deleteFinish(int n) => 'Delete $n · Finish';
  String get previousGroup => 'Previous group';
  String markedToast(String size) => '+~$size marked';

  // ── Finished ──────────────────────────────────────────────────────────────
  String freed(String size) => '$size freed';
  String movedToRecentlyDeleted(MediaKind k, int n, String f) =>
      '${mediaCount(k, n, f)} moved to Recently Deleted. You can restore '
      '${n == 1 ? 'it' : 'them'} there for 30 days.';
  String movedToTrash(MediaKind k, int n, String f) =>
      '${mediaCount(k, n, f)} moved to the trash.';
  String deletedPlain(MediaKind k, int n, String f) =>
      '${mediaCount(k, n, f)} deleted.';
  String get milestoneReached => 'MILESTONE REACHED';
  String milestoneLine(String total, String n) =>
      '$total freed in total — room for about $n new photos.';
  String nextTier(String size) => 'Next: $size';
  String get keepGoing => 'Keep going';
  String get nothingDeleted => 'Nothing was deleted';
  String nothingDeletedBody(MediaKind k) =>
      'Your ${switch (k) { MediaKind.photos => 'photos', MediaKind.videos => 'videos', MediaKind.items => 'items' }} '
      'are untouched and your marks were cleared. No progress was counted.';

  // ── Milestones ────────────────────────────────────────────────────────────
  String get milestones => 'Milestones';
  String freedInTotal(String n) => 'freed in total · $n deleted';
  String reachedOn(String date) => 'Reached $date';
  String get reached => 'Reached';
  String aboutPhotos(String n) => '≈ $n photos';
  String ofTier(String a, String b) => '$a of $b';
  String get progress => 'Progress';

  // ── Dates ─────────────────────────────────────────────────────────────────
  String get today => 'Today';
  String get yesterday => 'Yesterday';
  /// Monday first (DateTime.weekday − 1).
  List<String> get weekdaysShort =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  List<String> get monthsShort => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
  String _wd(DateTime d) => weekdaysShort[d.weekday - 1];
  String _mo(DateTime d) => monthsShort[d.month - 1];

  /// "Sun, Oct 4" — a date in the current year.
  String dateThisYear(DateTime d) => '${_wd(d)}, ${_mo(d)} ${d.day}';

  /// "Sep 27, 2024".
  String dateWithYear(DateTime d) => '${_mo(d)} ${d.day}, ${d.year}';

  /// "Oct 4" — no weekday (milestone dates).
  String dayMonth(DateTime d) => '${_mo(d)} ${d.day}';

  /// "Today, 09:14" / "Yesterday, 23:02" / "Sun, Oct 4" / "Sep 27, 2024".
  /// [withTime] also adds the time to older dates (group headers).
  String shortDate(DateTime d, {bool withTime = false, DateTime? now}) {
    final n = now ?? DateTime.now();
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final day = DateTime(d.year, d.month, d.day);
    final todayStart = DateTime(n.year, n.month, n.day);
    final diff = todayStart.difference(day).inDays;
    if (diff == 0) return '$today, $time';
    if (diff == 1) return '$yesterday, $time';
    final date = d.year == n.year ? dateThisYear(d) : dateWithYear(d);
    return withTime ? '$date, $time' : date;
  }

  /// "Oct 4" this year, "Oct 4, 2024" before.
  String reachedDate(DateTime d, {DateTime? now}) =>
      d.year == (now ?? DateTime.now()).year ? dayMonth(d) : dateWithYear(d);
}

// ─── English ────────────────────────────────────────────────────────────────────
// Uses all the default strings defined in the base AppStrings class.
class _EnglishStrings extends AppStrings {
  const _EnglishStrings() : super._('en');
}

// ─── Spanish ──────────────────────────────────────────────────────────────────
class _SpanishStrings extends AppStrings {
  const _SpanishStrings() : super._('es');

  // ── 1.3 Noir ──
  @override String get homeTitle => 'Limpia tu galería';
  @override String tabPhotos(String n) => 'Fotos · $n';
  @override String tabVideos(String n) => 'Videos · $n';
  @override String get videosLabel => 'Videos';
  @override String get upToDate => 'Al día · revisado ahora mismo';
  @override String checkedAgo(int m) => 'Al día · revisado hace $m min';
  @override String get lookingForNew => 'Buscando fotos nuevas…';
  @override String get similarShots => 'Fotos parecidas';
  @override String get similarShotsDesc => 'Ráfagas y repeticiones, agrupadas.';
  @override String get similarClips => 'Videos parecidos';
  @override String get similarClipsDesc => 'Videos grabados con minutos de diferencia, juntos.';
  @override String get swipe => 'Deslizar';
  @override String get swipePhotosDesc => 'Todas las fotos, de la más nueva a la más antigua.';
  @override String get swipeVideosDesc => 'Todos los videos, del más nuevo al más antiguo. Mantén para ver.';
  @override String get findingGroups => 'Buscando grupos…';
  @override String get allowAccess => 'Permitir acceso';
  @override String get selectMorePhotos => 'Seleccionar más fotos';
  @override String get limitedAccessBodyIos => 'CleanFotos solo puede ver las fotos que seleccionaste. Selecciona más o permite el acceso completo en Ajustes.';
  @override String get nextMilestone => 'Próximo hito';
  @override String toGo(String size) => 'faltan $size';
  @override String ofFreed(String size) => 'de $size liberados';
  @override String firstMilestone(String size) => 'Libera tus primeros $size';
  @override String allMilestones(String size) => 'Todos los hitos logrados · $size liberados';
  @override String get removeAdsLink => 'Quitar anuncios · pago único';
  @override String groupsCount(int n, String f) => '$f grupo${n == 1 ? '' : 's'}';
  @override String photosCount(int n, String f) => '$f foto${n == 1 ? '' : 's'}';
  @override String videosCount(int n, String f) => '$f video${n == 1 ? '' : 's'}';
  @override String itemsCount(int n, String f) => '$f elemento${n == 1 ? '' : 's'}';
  @override String reviewed(String n) => '$n revisadas';
  @override String markedPending(String n, String size) => '$n marcadas · ~$size';
  @override String get confirmOnceNote => 'Las fotos marcadas se borran al terminar: confirmas una sola vez.';
  @override String get confirmOnceNoteVideos => 'Los videos marcados se borran al terminar: confirmas una sola vez.';
  @override String get swipeFirstHint => 'Desliza a la izquierda para borrar · a la derecha para conservar';
  @override String get finish => 'Terminar';
  @override String get undo => 'Deshacer';
  @override String get back => 'Atrás';
  @override String get holdToPlay => 'Mantén para ver';
  @override String get playing => 'Reproduciendo…';
  @override String similarCount(int n) => '$n fotos parecidas';
  @override String similarClipsCount(int n) => '$n videos parecidos';
  @override String get tapToMark => 'Toca las fotos que no quieres';
  @override String get tapToMarkVideos => 'Toca los videos que no quieres · Mantén para ver';
  @override String get keepAllNext => 'Conservar todas · Siguiente';
  @override String deleteNext(int n) => 'Borrar $n · Siguiente';
  @override String get keepAllFinish => 'Conservar todas · Terminar';
  @override String deleteFinish(int n) => 'Borrar $n · Terminar';
  @override String get previousGroup => 'Grupo anterior';
  @override String markedToast(String size) => '+~$size marcados';
  @override String freed(String size) => '$size liberados';
  String _esAdj(MediaKind k, int n, String stem) =>
      '$stem${k == MediaKind.photos ? 'a' : 'o'}${n == 1 ? '' : 's'}';
  @override String movedToRecentlyDeleted(MediaKind k, int n, String f) =>
      '${mediaCount(k, n, f)} ${_esAdj(k, n, 'movid')} a «Eliminado». Puedes '
      'recuperarl${k == MediaKind.photos ? 'a' : 'o'}${n == 1 ? '' : 's'} allí durante 30 días.';
  @override String movedToTrash(MediaKind k, int n, String f) =>
      '${mediaCount(k, n, f)} ${_esAdj(k, n, 'movid')} a la papelera.';
  @override String deletedPlain(MediaKind k, int n, String f) =>
      '${mediaCount(k, n, f)} ${_esAdj(k, n, 'eliminad')}.';
  @override String get milestoneReached => 'HITO LOGRADO';
  @override String milestoneLine(String total, String n) => '$total liberados en total: espacio para unas $n fotos nuevas.';
  @override String nextTier(String size) => 'Siguiente: $size';
  @override String get keepGoing => 'Seguir';
  @override String get nothingDeleted => 'No se borró nada';
  @override String nothingDeletedBody(MediaKind k) => switch (k) {
        MediaKind.photos => 'Tus fotos siguen intactas y tus marcas se han borrado. No se ha contado ningún progreso.',
        MediaKind.videos => 'Tus videos siguen intactos y tus marcas se han borrado. No se ha contado ningún progreso.',
        MediaKind.items => 'Tus elementos siguen intactos y tus marcas se han borrado. No se ha contado ningún progreso.',
      };
  @override String get milestones => 'Hitos';
  @override String freedInTotal(String n) => 'liberados en total · $n borrados';
  @override String reachedOn(String date) => 'Logrado el $date';
  @override String get reached => 'Logrado';
  @override String aboutPhotos(String n) => '≈ $n fotos';
  @override String ofTier(String a, String b) => '$a de $b';
  @override String get progress => 'Progreso';
  @override String get today => 'Hoy';
  @override String get yesterday => 'Ayer';
  @override List<String> get weekdaysShort => const ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  @override List<String> get monthsShort => const ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'];
  @override String dateThisYear(DateTime d) => '${_wd(d)}, ${d.day} ${_mo(d)}';
  @override String dateWithYear(DateTime d) => '${d.day} ${_mo(d)} ${d.year}';
  @override String dayMonth(DateTime d) => '${d.day} ${_mo(d)}';

  @override String get feedback => 'Sonido y vibración';
  @override String get sounds => 'Sonidos';
  @override String get haptics => 'Vibración';

  @override String get analyzingPhotos => 'Analizando tus fotos…';
  @override String get allClean => 'Todo limpio! 🎉';
  @override String get freedSpace => 'Espacio liberado';
  @override String get deletedPhotos => 'Fotos eliminadas';
  @override String get swipeDelete => 'Borrar';
  @override String get swipeKeep => 'Guardar';
  @override String get backHome => 'Volver';
  @override String get sponsored => 'Publicidad';
  @override String get adSwipeHint => 'Desliza en cualquier dirección para continuar';
  @override String get permissionTitle => 'Acceso a fotos requerido';
  @override String get permissionBody => 'CleanFotos necesita acceso a tus fotos.';
  @override String get openSettings => 'Abrir ajustes';
  @override String get videoAccessTitle => 'Permitir acceso a videos';
  @override String get videoAccessBody => 'Para limpiar videos, CleanFotos necesita acceso a todos tus videos. Abre Ajustes y pon "Fotos y videos" en Permitir todo.';
  @override String get limitedAccessTitle => 'No se ven todas las fotos';
  @override String get limitedAccessBody => 'CleanFotos solo puede ver las fotos que seleccionaste. Abre Ajustes y pon "Fotos y videos" en Permitir todo.';
  @override String get notNow => 'Ahora no';
  @override String get pendingTitle => 'Termina la limpieza';
  @override String pendingBody(int n) => 'Marcaste $n elemento(s) para borrar la última vez pero no lo confirmaste. ¿Borrarlos ahora?';
  @override String get pendingConfirm => 'Borrarlos';
  @override String get pendingLater => 'Conservarlos';
  @override String get errorMessage => 'Algo salió mal';
  @override String get retry => 'Reintentar';
  @override String get settings => 'Ajustes';
  @override String get cleanappsPromoTitle => 'Prueba CleanApps';
  @override String get cleanappsPromoSubtitle => 'Desliza para desinstalar apps que no usas y libera aún más espacio.';
  @override String get cleanappsPromoCta => 'Obtener';
  @override String get language => 'Idioma';
  @override String get reminderTitle => '¡Hora de limpiar! 📸';
  @override String get reminderBody => 'Libera espacio: revisa tus fotos similares en CleanFotos.';
  @override String get removeAds => 'Quitar anuncios';
  @override String get proTitle => 'CleanFotos Pro';
  @override String get proDesc => 'Elimina todos los anuncios para siempre con una compra única.';
  @override String proButton(String price) => 'Quitar anuncios · $price';
  @override String get proButtonNoPrice => 'Quitar anuncios';
  @override String get proUnavailable => 'La compra no está disponible ahora mismo. Inténtalo más tarde.';
  @override String get restorePurchase => 'Restaurar compra';
  @override String get proUnlocked => 'Pro activado — ¡gracias! 🎉';
  @override String get about => 'Acerca de';
  @override String get privacyPolicy => 'Política de privacidad';
  @override String get rateApp => 'Valorar CleanFotos';
  @override String get privacyOptions => 'Opciones de privacidad de anuncios';
  @override String get appVersion => 'Versión';
}

// ─── German ───────────────────────────────────────────────────────────────────
class _GermanStrings extends AppStrings {
  const _GermanStrings() : super._('de');

  // ── 1.3 Noir ──
  @override String get homeTitle => 'Räume deine Mediathek auf';
  @override String tabPhotos(String n) => 'Fotos · $n';
  @override String tabVideos(String n) => 'Videos · $n';
  @override String get videosLabel => 'Videos';
  @override String get upToDate => 'Aktuell · gerade geprüft';
  @override String checkedAgo(int m) => 'Aktuell · vor $m Min. geprüft';
  @override String get lookingForNew => 'Suche nach neuen Fotos…';
  @override String get similarShots => 'Ähnliche Fotos';
  @override String get similarShotsDesc => 'Serienbilder und Wiederholungen, gruppiert.';
  @override String get similarClips => 'Ähnliche Videos';
  @override String get similarClipsDesc => 'Videos, die Minuten auseinander liegen, nebeneinander.';
  @override String get swipe => 'Wischen';
  @override String get swipePhotosDesc => 'Jedes Foto, das neueste zuerst.';
  @override String get swipeVideosDesc => 'Jedes Video, das neueste zuerst. Halten zum Abspielen.';
  @override String get findingGroups => 'Gruppen werden gesucht…';
  @override String get allowAccess => 'Zugriff erlauben';
  @override String get selectMorePhotos => 'Weitere Fotos auswählen';
  @override String get limitedAccessBodyIos => 'CleanFotos sieht nur die von dir ausgewählten Fotos. Wähle weitere aus oder erlaube in den Einstellungen vollen Zugriff.';
  @override String get nextMilestone => 'Nächster Meilenstein';
  @override String toGo(String size) => 'noch $size';
  @override String ofFreed(String size) => 'von $size frei';
  @override String firstMilestone(String size) => 'Schaffe deine ersten $size Platz';
  @override String allMilestones(String size) => 'Alle Meilensteine erreicht · $size frei';
  @override String get removeAdsLink => 'Werbung entfernen · einmaliger Kauf';
  @override String groupsCount(int n, String f) => '$f ${n == 1 ? 'Gruppe' : 'Gruppen'}';
  @override String photosCount(int n, String f) => '$f ${n == 1 ? 'Foto' : 'Fotos'}';
  @override String videosCount(int n, String f) => '$f ${n == 1 ? 'Video' : 'Videos'}';
  @override String itemsCount(int n, String f) => '$f ${n == 1 ? 'Element' : 'Elemente'}';
  @override String reviewed(String n) => '$n geprüft';
  @override String markedPending(String n, String size) => '$n markiert · ~$size';
  @override String get confirmOnceNote => 'Markierte Fotos werden gelöscht, wenn du fertig bist – du bestätigst nur einmal.';
  @override String get confirmOnceNoteVideos => 'Markierte Videos werden gelöscht, wenn du fertig bist – du bestätigst nur einmal.';
  @override String get swipeFirstHint => 'Nach links wischen zum Löschen · nach rechts zum Behalten';
  @override String get finish => 'Fertig';
  @override String get undo => 'Rückgängig';
  @override String get back => 'Zurück';
  @override String get holdToPlay => 'Halten zum Abspielen';
  @override String get playing => 'Wird abgespielt…';
  @override String similarCount(int n) => '$n ähnliche Fotos';
  @override String similarClipsCount(int n) => '$n ähnliche Videos';
  @override String get tapToMark => 'Tippe die Fotos an, die du nicht willst';
  @override String get tapToMarkVideos => 'Tippe die Videos an, die du nicht willst · Halten zum Abspielen';
  @override String get keepAllNext => 'Alle behalten · Weiter';
  @override String deleteNext(int n) => '$n löschen · Weiter';
  @override String get keepAllFinish => 'Alle behalten · Fertig';
  @override String deleteFinish(int n) => '$n löschen · Fertig';
  @override String get previousGroup => 'Vorherige Gruppe';
  @override String markedToast(String size) => '+~$size markiert';
  @override String freed(String size) => '$size frei';
  @override String movedToRecentlyDeleted(MediaKind k, int n, String f) =>
      '${mediaCount(k, n, f)} in „Zuletzt gelöscht“ verschoben. Dort kannst du '
      '${n == 1 ? 'es' : 'sie'} 30 Tage lang wiederherstellen.';
  @override String movedToTrash(MediaKind k, int n, String f) => '${mediaCount(k, n, f)} in den Papierkorb verschoben.';
  @override String deletedPlain(MediaKind k, int n, String f) => '${mediaCount(k, n, f)} gelöscht.';
  @override String get milestoneReached => 'MEILENSTEIN ERREICHT';
  @override String milestoneLine(String total, String n) => 'Insgesamt $total frei – Platz für etwa $n neue Fotos.';
  @override String nextTier(String size) => 'Nächster: $size';
  @override String get keepGoing => 'Weitermachen';
  @override String get nothingDeleted => 'Nichts wurde gelöscht';
  @override String nothingDeletedBody(MediaKind k) =>
      'Deine ${switch (k) { MediaKind.photos => 'Fotos', MediaKind.videos => 'Videos', MediaKind.items => 'Elemente' }} '
      'sind unverändert und deine Markierungen wurden entfernt. Es wurde kein Fortschritt gezählt.';
  @override String get milestones => 'Meilensteine';
  @override String freedInTotal(String n) => 'insgesamt frei · $n gelöscht';
  @override String reachedOn(String date) => 'Erreicht am $date';
  @override String get reached => 'Erreicht';
  @override String aboutPhotos(String n) => '≈ $n Fotos';
  @override String ofTier(String a, String b) => '$a von $b';
  @override String get progress => 'Fortschritt';
  @override String get today => 'Heute';
  @override String get yesterday => 'Gestern';
  @override List<String> get weekdaysShort => const ['Mo.', 'Di.', 'Mi.', 'Do.', 'Fr.', 'Sa.', 'So.'];
  @override List<String> get monthsShort => const ['Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', 'Juli', 'Aug.', 'Sept.', 'Okt.', 'Nov.', 'Dez.'];
  @override String dateThisYear(DateTime d) => '${_wd(d)}, ${d.day}. ${_mo(d)}';
  @override String dateWithYear(DateTime d) => '${d.day}. ${_mo(d)} ${d.year}';
  @override String dayMonth(DateTime d) => '${d.day}. ${_mo(d)}';

  @override String get feedback => 'Feedback';
  @override String get sounds => 'Töne';
  @override String get haptics => 'Haptik';

  @override String get analyzingPhotos => 'Fotos werden analysiert…';
  @override String get allClean => 'Alles sauber! 🎉';
  @override String get freedSpace => 'Freigegebener Speicher';
  @override String get deletedPhotos => 'Gelöschte Fotos';
  @override String get swipeDelete => 'Löschen';
  @override String get swipeKeep => 'Behalten';
  @override String get backHome => 'Zurück';
  @override String get sponsored => 'Anzeige';
  @override String get adSwipeHint => 'Wische in eine Richtung, um fortzufahren';
  @override String get permissionTitle => 'Fotozugriff erforderlich';
  @override String get permissionBody => 'CleanFotos benötigt Zugriff auf deine Fotos.';
  @override String get openSettings => 'Einstellungen öffnen';
  @override String get videoAccessTitle => 'Videozugriff erlauben';
  @override String get videoAccessBody => 'Um Videos aufzuräumen, benötigt CleanFotos Zugriff auf alle deine Videos. Öffne die Einstellungen und stelle „Fotos und Videos" auf Alle zulassen.';
  @override String get limitedAccessTitle => 'Nicht alle Fotos sichtbar';
  @override String get limitedAccessBody => 'CleanFotos sieht nur die von dir ausgewählten Fotos. Öffne die Einstellungen und stelle „Fotos und Videos" auf Alle zulassen.';
  @override String get notNow => 'Nicht jetzt';
  @override String get pendingTitle => 'Aufräumen abschließen';
  @override String pendingBody(int n) => 'Du hast beim letzten Mal $n Element(e) zum Löschen markiert, es aber nicht bestätigt. Jetzt löschen?';
  @override String get pendingConfirm => 'Löschen';
  @override String get pendingLater => 'Behalten';
  @override String get errorMessage => 'Etwas ist schiefgelaufen';
  @override String get retry => 'Erneut versuchen';
  @override String get settings => 'Einstellungen';
  @override String get cleanappsPromoTitle => 'CleanApps ausprobieren';
  @override String get cleanappsPromoSubtitle => 'Wische ungenutzte Apps weg und schaffe noch mehr Platz.';
  @override String get cleanappsPromoCta => 'Installieren';
  @override String get language => 'Sprache';
  @override String get reminderTitle => 'Zeit zum Aufräumen! 📸';
  @override String get reminderBody => 'Schaffe Platz – überprüfe deine ähnlichen Fotos in CleanFotos.';
  @override String get removeAds => 'Werbung entfernen';
  @override String get proTitle => 'CleanFotos Pro';
  @override String get proDesc => 'Entferne alle Werbung dauerhaft mit einem einmaligen Kauf.';
  @override String proButton(String price) => 'Werbung entfernen · $price';
  @override String get proButtonNoPrice => 'Werbung entfernen';
  @override String get proUnavailable => 'Der Kauf ist derzeit nicht verfügbar. Bitte versuche es später erneut.';
  @override String get restorePurchase => 'Kauf wiederherstellen';
  @override String get proUnlocked => 'Pro freigeschaltet — danke! 🎉';
  @override String get about => 'Über';
  @override String get privacyPolicy => 'Datenschutz';
  @override String get rateApp => 'CleanFotos bewerten';
  @override String get privacyOptions => 'Datenschutzoptionen für Werbung';
  @override String get appVersion => 'Version';
}

// ─── French ───────────────────────────────────────────────────────────────────
class _FrenchStrings extends AppStrings {
  const _FrenchStrings() : super._('fr');

  // ── 1.3 Noir ──
  @override String get homeTitle => 'Faites le tri dans votre photothèque';
  @override String tabPhotos(String n) => 'Photos · $n';
  @override String tabVideos(String n) => 'Vidéos · $n';
  @override String get videosLabel => 'Vidéos';
  @override String get upToDate => 'À jour · vérifié à l’instant';
  @override String checkedAgo(int m) => 'À jour · vérifié il y a $m min';
  @override String get lookingForNew => 'Recherche de nouvelles photos…';
  @override String get similarShots => 'Photos similaires';
  @override String get similarShotsDesc => 'Rafales et prises répétées, regroupées.';
  @override String get similarClips => 'Vidéos similaires';
  @override String get similarClipsDesc => 'Vidéos filmées à quelques minutes d’écart, côte à côte.';
  @override String get swipe => 'Balayer';
  @override String get swipePhotosDesc => 'Toutes les photos, les plus récentes d’abord.';
  @override String get swipeVideosDesc => 'Toutes les vidéos, les plus récentes d’abord. Maintenez pour lire.';
  @override String get findingGroups => 'Recherche de groupes…';
  @override String get allowAccess => 'Autoriser l’accès';
  @override String get selectMorePhotos => 'Sélectionner plus de photos';
  @override String get limitedAccessBodyIos => 'CleanFotos ne voit que les photos que vous avez sélectionnées. Sélectionnez-en plus ou autorisez l’accès complet dans Réglages.';
  @override String get nextMilestone => 'Prochain palier';
  @override String toGo(String size) => 'encore $size';
  @override String ofFreed(String size) => 'sur $size libérés';
  @override String firstMilestone(String size) => 'Libérez vos premiers $size';
  @override String allMilestones(String size) => 'Tous les paliers atteints · $size libérés';
  @override String get removeAdsLink => 'Supprimer les pubs · achat unique';
  @override String groupsCount(int n, String f) => '$f groupe${n <= 1 ? '' : 's'}';
  @override String photosCount(int n, String f) => '$f photo${n <= 1 ? '' : 's'}';
  @override String videosCount(int n, String f) => '$f vidéo${n <= 1 ? '' : 's'}';
  @override String itemsCount(int n, String f) => '$f élément${n <= 1 ? '' : 's'}';
  @override String reviewed(String n) => '$n vues';
  @override String markedPending(String n, String size) => '$n marquées · ~$size';
  @override String get confirmOnceNote => 'Les photos marquées sont supprimées à la fin — vous ne confirmez qu’une fois.';
  @override String get confirmOnceNoteVideos => 'Les vidéos marquées sont supprimées à la fin — vous ne confirmez qu’une fois.';
  @override String get swipeFirstHint => 'Balayez à gauche pour supprimer · à droite pour garder';
  @override String get finish => 'Terminer';
  @override String get undo => 'Annuler';
  @override String get back => 'Retour';
  @override String get holdToPlay => 'Maintenez pour lire';
  @override String get playing => 'Lecture…';
  @override String similarCount(int n) => '$n photos similaires';
  @override String similarClipsCount(int n) => '$n vidéos similaires';
  @override String get tapToMark => 'Touchez les photos dont vous ne voulez pas';
  @override String get tapToMarkVideos => 'Touchez les vidéos dont vous ne voulez pas · Maintenez pour lire';
  @override String get keepAllNext => 'Tout garder · Suivant';
  @override String deleteNext(int n) => 'Supprimer $n · Suivant';
  @override String get keepAllFinish => 'Tout garder · Terminer';
  @override String deleteFinish(int n) => 'Supprimer $n · Terminer';
  @override String get previousGroup => 'Groupe précédent';
  @override String markedToast(String size) => '+~$size marqués';
  @override String freed(String size) => '$size libérés';
  String _frAdj(MediaKind k, int n, String stem) =>
      '$stem${k == MediaKind.items ? '' : 'e'}${n <= 1 ? '' : 's'}';
  @override String movedToRecentlyDeleted(MediaKind k, int n, String f) =>
      '${mediaCount(k, n, f)} ${_frAdj(k, n, 'déplacé')} dans « Supprimés récemment ». '
      'Vous pouvez ${n <= 1 ? (k == MediaKind.items ? 'le' : 'la') : 'les'} restaurer pendant 30 jours.';
  @override String movedToTrash(MediaKind k, int n, String f) =>
      '${mediaCount(k, n, f)} ${_frAdj(k, n, 'déplacé')} dans la corbeille.';
  @override String deletedPlain(MediaKind k, int n, String f) =>
      '${mediaCount(k, n, f)} ${_frAdj(k, n, 'supprimé')}.';
  @override String get milestoneReached => 'PALIER ATTEINT';
  @override String milestoneLine(String total, String n) => '$total libérés au total — de la place pour environ $n nouvelles photos.';
  @override String nextTier(String size) => 'Suivant : $size';
  @override String get keepGoing => 'Continuer';
  @override String get nothingDeleted => 'Rien n’a été supprimé';
  @override String nothingDeletedBody(MediaKind k) => switch (k) {
        MediaKind.photos => 'Vos photos sont intactes et vos sélections ont été effacées. Aucun progrès n’a été compté.',
        MediaKind.videos => 'Vos vidéos sont intactes et vos sélections ont été effacées. Aucun progrès n’a été compté.',
        MediaKind.items => 'Vos éléments sont intacts et vos sélections ont été effacées. Aucun progrès n’a été compté.',
      };
  @override String get milestones => 'Paliers';
  @override String freedInTotal(String n) => 'libérés au total · $n supprimés';
  @override String reachedOn(String date) => 'Atteint le $date';
  @override String get reached => 'Atteint';
  @override String aboutPhotos(String n) => '≈ $n photos';
  @override String ofTier(String a, String b) => '$a sur $b';
  @override String get progress => 'Progression';
  @override String get today => 'Aujourd’hui';
  @override String get yesterday => 'Hier';
  @override List<String> get weekdaysShort => const ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
  @override List<String> get monthsShort => const ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
  @override String dateThisYear(DateTime d) => '${_wd(d)} ${d.day} ${_mo(d)}';
  @override String dateWithYear(DateTime d) => '${d.day} ${_mo(d)} ${d.year}';
  @override String dayMonth(DateTime d) => '${d.day} ${_mo(d)}';

  @override String get feedback => 'Retours';
  @override String get sounds => 'Sons';
  @override String get haptics => 'Vibrations';

  @override String get analyzingPhotos => 'Analyse en cours…';
  @override String get allClean => 'Tout est propre ! 🎉';
  @override String get freedSpace => 'Espace libéré';
  @override String get deletedPhotos => 'Photos supprimées';
  @override String get swipeDelete => 'Supprimer';
  @override String get swipeKeep => 'Garder';
  @override String get backHome => 'Retour';
  @override String get sponsored => 'Sponsorisé';
  @override String get adSwipeHint => 'Balayez dans un sens pour continuer';
  @override String get permissionTitle => 'Accès aux photos requis';
  @override String get permissionBody => 'CleanFotos a besoin d\'accéder à vos photos.';
  @override String get openSettings => 'Ouvrir les paramètres';
  @override String get videoAccessTitle => 'Autoriser l\'accès aux vidéos';
  @override String get videoAccessBody => 'Pour nettoyer les vidéos, CleanFotos a besoin d\'accéder à toutes vos vidéos. Ouvrez les Paramètres et réglez « Photos et vidéos » sur Tout autoriser.';
  @override String get limitedAccessTitle => 'Toutes les photos ne sont pas visibles';
  @override String get limitedAccessBody => 'CleanFotos ne voit que les photos que vous avez sélectionnées. Ouvrez les Paramètres et réglez « Photos et vidéos » sur Tout autoriser.';
  @override String get notNow => 'Pas maintenant';
  @override String get pendingTitle => 'Terminer le nettoyage';
  @override String pendingBody(int n) => 'Vous aviez marqué $n élément(s) à supprimer sans confirmer. Les supprimer maintenant ?';
  @override String get pendingConfirm => 'Supprimer';
  @override String get pendingLater => 'Conserver';
  @override String get errorMessage => 'Une erreur s\'est produite';
  @override String get retry => 'Réessayer';
  @override String get settings => 'Paramètres';
  @override String get cleanappsPromoTitle => 'Essayez CleanApps';
  @override String get cleanappsPromoSubtitle => 'Balayez pour désinstaller les apps inutilisées et libérez encore plus d\'espace.';
  @override String get cleanappsPromoCta => 'Obtenir';
  @override String get language => 'Langue';
  @override String get reminderTitle => 'C\'est l\'heure du tri ! 📸';
  @override String get reminderBody => 'Libérez de l\'espace : passez en revue vos photos similaires dans CleanFotos.';
  @override String get removeAds => 'Supprimer les pubs';
  @override String get proTitle => 'CleanFotos Pro';
  @override String get proDesc => 'Supprimez toutes les pubs pour toujours avec un achat unique.';
  @override String proButton(String price) => 'Supprimer les pubs · $price';
  @override String get proButtonNoPrice => 'Supprimer les pubs';
  @override String get proUnavailable => 'L\'achat n\'est pas disponible pour le moment. Réessayez plus tard.';
  @override String get restorePurchase => 'Restaurer l\'achat';
  @override String get proUnlocked => 'Pro activé — merci ! 🎉';
  @override String get about => 'À propos';
  @override String get privacyPolicy => 'Politique de confidentialité';
  @override String get rateApp => 'Noter CleanFotos';
  @override String get privacyOptions => 'Options de confidentialité des annonces';
  @override String get appVersion => 'Version';
}

// ─── Portuguese ───────────────────────────────────────────────────────────────
class _PortugueseStrings extends AppStrings {
  const _PortugueseStrings() : super._('pt');

  // ── 1.3 Noir ──
  @override String get homeTitle => 'Organize sua galeria';
  @override String tabPhotos(String n) => 'Fotos · $n';
  @override String tabVideos(String n) => 'Vídeos · $n';
  @override String get videosLabel => 'Vídeos';
  @override String get upToDate => 'Atualizado · verificado agora';
  @override String checkedAgo(int m) => 'Atualizado · verificado há $m min';
  @override String get lookingForNew => 'Procurando fotos novas…';
  @override String get similarShots => 'Fotos parecidas';
  @override String get similarShotsDesc => 'Sequências e repetições, agrupadas.';
  @override String get similarClips => 'Vídeos parecidos';
  @override String get similarClipsDesc => 'Vídeos gravados com minutos de diferença, lado a lado.';
  @override String get swipe => 'Deslizar';
  @override String get swipePhotosDesc => 'Todas as fotos, das mais novas às mais antigas.';
  @override String get swipeVideosDesc => 'Todos os vídeos, dos mais novos aos mais antigos. Segure para ver.';
  @override String get findingGroups => 'Procurando grupos…';
  @override String get allowAccess => 'Permitir acesso';
  @override String get selectMorePhotos => 'Selecionar mais fotos';
  @override String get limitedAccessBodyIos => 'O CleanFotos só vê as fotos que você selecionou. Selecione mais ou permita o acesso total nos Ajustes.';
  @override String get nextMilestone => 'Próxima meta';
  @override String toGo(String size) => 'faltam $size';
  @override String ofFreed(String size) => 'de $size liberados';
  @override String firstMilestone(String size) => 'Libere seus primeiros $size';
  @override String allMilestones(String size) => 'Todas as metas alcançadas · $size liberados';
  @override String get removeAdsLink => 'Remover anúncios · compra única';
  @override String groupsCount(int n, String f) => '$f grupo${n == 1 ? '' : 's'}';
  @override String photosCount(int n, String f) => '$f foto${n == 1 ? '' : 's'}';
  @override String videosCount(int n, String f) => '$f vídeo${n == 1 ? '' : 's'}';
  @override String itemsCount(int n, String f) => '$f ${n == 1 ? 'item' : 'itens'}';
  @override String reviewed(String n) => '$n revisadas';
  @override String markedPending(String n, String size) => '$n marcadas · ~$size';
  @override String get confirmOnceNote => 'As fotos marcadas são apagadas quando você termina — você confirma uma vez só.';
  @override String get confirmOnceNoteVideos => 'Os vídeos marcados são apagados quando você termina — você confirma uma vez só.';
  @override String get swipeFirstHint => 'Deslize para a esquerda para apagar · para a direita para manter';
  @override String get finish => 'Concluir';
  @override String get undo => 'Desfazer';
  @override String get back => 'Voltar';
  @override String get holdToPlay => 'Segure para ver';
  @override String get playing => 'Reproduzindo…';
  @override String similarCount(int n) => '$n fotos parecidas';
  @override String similarClipsCount(int n) => '$n vídeos parecidos';
  @override String get tapToMark => 'Toque nas fotos que você não quer';
  @override String get tapToMarkVideos => 'Toque nos vídeos que você não quer · Segure para ver';
  @override String get keepAllNext => 'Manter todas · Próximo';
  @override String deleteNext(int n) => 'Apagar $n · Próximo';
  @override String get keepAllFinish => 'Manter todas · Concluir';
  @override String deleteFinish(int n) => 'Apagar $n · Concluir';
  @override String get previousGroup => 'Grupo anterior';
  @override String markedToast(String size) => '+~$size marcados';
  @override String freed(String size) => '$size liberados';
  String _ptAdj(MediaKind k, int n, String stem) =>
      '$stem${k == MediaKind.photos ? 'a' : 'o'}${n == 1 ? '' : 's'}';
  @override String movedToRecentlyDeleted(MediaKind k, int n, String f) =>
      '${mediaCount(k, n, f)} ${_ptAdj(k, n, 'movid')} para "Apagados". Você pode '
      'recuperá-l${k == MediaKind.photos ? 'a' : 'o'}${n == 1 ? '' : 's'} lá por 30 dias.';
  @override String movedToTrash(MediaKind k, int n, String f) =>
      '${mediaCount(k, n, f)} ${_ptAdj(k, n, 'movid')} para a lixeira.';
  @override String deletedPlain(MediaKind k, int n, String f) =>
      '${mediaCount(k, n, f)} ${_ptAdj(k, n, 'apagad')}.';
  @override String get milestoneReached => 'META ALCANÇADA';
  @override String milestoneLine(String total, String n) => '$total liberados no total — espaço para cerca de $n fotos novas.';
  @override String nextTier(String size) => 'Próxima: $size';
  @override String get keepGoing => 'Continuar';
  @override String get nothingDeleted => 'Nada foi apagado';
  @override String nothingDeletedBody(MediaKind k) => switch (k) {
        MediaKind.photos => 'Suas fotos continuam intactas e suas marcações foram apagadas. Nenhum progresso foi contado.',
        MediaKind.videos => 'Seus vídeos continuam intactos e suas marcações foram apagadas. Nenhum progresso foi contado.',
        MediaKind.items => 'Seus itens continuam intactos e suas marcações foram apagadas. Nenhum progresso foi contado.',
      };
  @override String get milestones => 'Metas';
  @override String freedInTotal(String n) => 'liberados no total · $n apagados';
  @override String reachedOn(String date) => 'Alcançada em $date';
  @override String get reached => 'Alcançada';
  @override String aboutPhotos(String n) => '≈ $n fotos';
  @override String ofTier(String a, String b) => '$a de $b';
  @override String get progress => 'Progresso';
  @override String get today => 'Hoje';
  @override String get yesterday => 'Ontem';
  @override List<String> get weekdaysShort => const ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
  @override List<String> get monthsShort => const ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
  @override String dateThisYear(DateTime d) => '${_wd(d)}, ${d.day} ${_mo(d)}';
  @override String dateWithYear(DateTime d) => '${d.day} ${_mo(d)} ${d.year}';
  @override String dayMonth(DateTime d) => '${d.day} ${_mo(d)}';

  @override String get feedback => 'Sons e vibração';
  @override String get sounds => 'Sons';
  @override String get haptics => 'Vibração';

  @override String get analyzingPhotos => 'Analisando fotos…';
  @override String get allClean => 'Tudo limpo! 🎉';
  @override String get freedSpace => 'Espaço liberado';
  @override String get deletedPhotos => 'Fotos deletadas';
  @override String get swipeDelete => 'Deletar';
  @override String get swipeKeep => 'Manter';
  @override String get backHome => 'Voltar';
  @override String get sponsored => 'Patrocinado';
  @override String get adSwipeHint => 'Deslize para qualquer lado para continuar';
  @override String get permissionTitle => 'Acesso às fotos necessário';
  @override String get permissionBody => 'CleanFotos precisa de acesso às suas fotos.';
  @override String get openSettings => 'Abrir configurações';
  @override String get videoAccessTitle => 'Permitir acesso a vídeos';
  @override String get videoAccessBody => 'Para limpar vídeos, o CleanFotos precisa de acesso a todos os seus vídeos. Abra as Configurações e defina "Fotos e vídeos" como Permitir tudo.';
  @override String get limitedAccessTitle => 'Nem todas as fotos estão visíveis';
  @override String get limitedAccessBody => 'O CleanFotos só vê as fotos que você selecionou. Abra as Configurações e defina "Fotos e vídeos" como Permitir tudo.';
  @override String get notNow => 'Agora não';
  @override String get pendingTitle => 'Concluir a limpeza';
  @override String pendingBody(int n) => 'Você marcou $n item(ns) para excluir da última vez, mas não confirmou. Excluir agora?';
  @override String get pendingConfirm => 'Excluir';
  @override String get pendingLater => 'Manter';
  @override String get errorMessage => 'Algo deu errado';
  @override String get retry => 'Tentar novamente';
  @override String get settings => 'Configurações';
  @override String get cleanappsPromoTitle => 'Experimente CleanApps';
  @override String get cleanappsPromoSubtitle => 'Deslize para desinstalar apps que não usa e libere ainda mais espaço.';
  @override String get cleanappsPromoCta => 'Obter';
  @override String get language => 'Idioma';
  @override String get reminderTitle => 'Hora de limpar! 📸';
  @override String get reminderBody => 'Libere espaço — revise suas fotos similares no CleanFotos.';
  @override String get removeAds => 'Remover anúncios';
  @override String get proTitle => 'CleanFotos Pro';
  @override String get proDesc => 'Remova todos os anúncios para sempre com uma compra única.';
  @override String proButton(String price) => 'Remover anúncios · $price';
  @override String get proButtonNoPrice => 'Remover anúncios';
  @override String get proUnavailable => 'A compra não está disponível no momento. Tente novamente mais tarde.';
  @override String get restorePurchase => 'Restaurar compra';
  @override String get proUnlocked => 'Pro ativado — obrigado! 🎉';
  @override String get about => 'Sobre';
  @override String get privacyPolicy => 'Política de privacidade';
  @override String get rateApp => 'Avaliar o CleanFotos';
  @override String get privacyOptions => 'Opções de privacidade de anúncios';
  @override String get appVersion => 'Versão';
}

// ─── Italian ──────────────────────────────────────────────────────────────────
class _ItalianStrings extends AppStrings {
  const _ItalianStrings() : super._('it');

  // ── 1.3 Noir ──
  @override String get homeTitle => 'Fai pulizia nella libreria';
  @override String tabPhotos(String n) => 'Foto · $n';
  @override String tabVideos(String n) => 'Video · $n';
  @override String get videosLabel => 'Video';
  @override String get upToDate => 'Aggiornato · controllato ora';
  @override String checkedAgo(int m) => 'Aggiornato · controllato $m min fa';
  @override String get lookingForNew => 'Cerco nuove foto…';
  @override String get similarShots => 'Foto simili';
  @override String get similarShotsDesc => 'Raffiche e scatti ripetuti, raggruppati.';
  @override String get similarClips => 'Video simili';
  @override String get similarClipsDesc => 'Video girati a pochi minuti di distanza, affiancati.';
  @override String get swipe => 'Scorri';
  @override String get swipePhotosDesc => 'Tutte le foto, dalla più recente.';
  @override String get swipeVideosDesc => 'Tutti i video, dal più recente. Tieni premuto per vedere.';
  @override String get findingGroups => 'Cerco gruppi…';
  @override String get allowAccess => 'Consenti accesso';
  @override String get selectMorePhotos => 'Seleziona altre foto';
  @override String get limitedAccessBodyIos => 'CleanFotos vede solo le foto che hai selezionato. Selezionane altre o consenti l’accesso completo in Impostazioni.';
  @override String get nextMilestone => 'Prossimo traguardo';
  @override String toGo(String size) => 'mancano $size';
  @override String ofFreed(String size) => 'su $size liberati';
  @override String firstMilestone(String size) => 'Libera i tuoi primi $size';
  @override String allMilestones(String size) => 'Tutti i traguardi raggiunti · $size liberati';
  @override String get removeAdsLink => 'Rimuovi pubblicità · acquisto unico';
  @override String groupsCount(int n, String f) => '$f ${n == 1 ? 'gruppo' : 'gruppi'}';
  @override String photosCount(int n, String f) => '$f foto';
  @override String videosCount(int n, String f) => '$f video';
  @override String itemsCount(int n, String f) => '$f ${n == 1 ? 'elemento' : 'elementi'}';
  @override String reviewed(String n) => '$n esaminate';
  @override String markedPending(String n, String size) => '$n selezionate · ~$size';
  @override String get confirmOnceNote => 'Le foto selezionate vengono eliminate quando finisci: confermi una volta sola.';
  @override String get confirmOnceNoteVideos => 'I video selezionati vengono eliminati quando finisci: confermi una volta sola.';
  @override String get swipeFirstHint => 'Scorri a sinistra per eliminare · a destra per tenere';
  @override String get finish => 'Fine';
  @override String get undo => 'Annulla';
  @override String get back => 'Indietro';
  @override String get holdToPlay => 'Tieni premuto per vedere';
  @override String get playing => 'In riproduzione…';
  @override String similarCount(int n) => '$n foto simili';
  @override String similarClipsCount(int n) => '$n video simili';
  @override String get tapToMark => 'Tocca le foto che non vuoi';
  @override String get tapToMarkVideos => 'Tocca i video che non vuoi · Tieni premuto per vedere';
  @override String get keepAllNext => 'Tieni tutte · Avanti';
  @override String deleteNext(int n) => 'Elimina $n · Avanti';
  @override String get keepAllFinish => 'Tieni tutte · Fine';
  @override String deleteFinish(int n) => 'Elimina $n · Fine';
  @override String get previousGroup => 'Gruppo precedente';
  @override String markedToast(String size) => '+~$size selezionati';
  @override String freed(String size) => '$size liberati';
  String _itEnd(MediaKind k, int n) =>
      k == MediaKind.photos ? (n == 1 ? 'a' : 'e') : (n == 1 ? 'o' : 'i');
  @override String movedToRecentlyDeleted(MediaKind k, int n, String f) =>
      '${mediaCount(k, n, f)} spostat${_itEnd(k, n)} in "Eliminati di recente". '
      'Puoi recuperarl${_itEnd(k, n)} lì per 30 giorni.';
  @override String movedToTrash(MediaKind k, int n, String f) =>
      '${mediaCount(k, n, f)} spostat${_itEnd(k, n)} nel cestino.';
  @override String deletedPlain(MediaKind k, int n, String f) =>
      '${mediaCount(k, n, f)} eliminat${_itEnd(k, n)}.';
  @override String get milestoneReached => 'TRAGUARDO RAGGIUNTO';
  @override String milestoneLine(String total, String n) => '$total liberati in totale: spazio per circa $n nuove foto.';
  @override String nextTier(String size) => 'Prossimo: $size';
  @override String get keepGoing => 'Continua';
  @override String get nothingDeleted => 'Non è stato eliminato nulla';
  @override String nothingDeletedBody(MediaKind k) => switch (k) {
        MediaKind.photos => 'Le tue foto sono intatte e le selezioni sono state annullate. Nessun progresso è stato conteggiato.',
        MediaKind.videos => 'I tuoi video sono intatti e le selezioni sono state annullate. Nessun progresso è stato conteggiato.',
        MediaKind.items => 'I tuoi elementi sono intatti e le selezioni sono state annullate. Nessun progresso è stato conteggiato.',
      };
  @override String get milestones => 'Traguardi';
  @override String freedInTotal(String n) => 'liberati in totale · $n eliminati';
  @override String reachedOn(String date) => 'Raggiunto il $date';
  @override String get reached => 'Raggiunto';
  @override String aboutPhotos(String n) => '≈ $n foto';
  @override String ofTier(String a, String b) => '$a su $b';
  @override String get progress => 'Progressi';
  @override String get today => 'Oggi';
  @override String get yesterday => 'Ieri';
  @override List<String> get weekdaysShort => const ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'];
  @override List<String> get monthsShort => const ['gen', 'feb', 'mar', 'apr', 'mag', 'giu', 'lug', 'ago', 'set', 'ott', 'nov', 'dic'];
  @override String dateThisYear(DateTime d) => '${_wd(d)} ${d.day} ${_mo(d)}';
  @override String dateWithYear(DateTime d) => '${d.day} ${_mo(d)} ${d.year}';
  @override String dayMonth(DateTime d) => '${d.day} ${_mo(d)}';

  @override String get feedback => 'Feedback';
  @override String get sounds => 'Suoni';
  @override String get haptics => 'Vibrazione';

  @override String get analyzingPhotos => 'Analisi in corso…';
  @override String get allClean => 'Tutto pulito! 🎉';
  @override String get freedSpace => 'Spazio liberato';
  @override String get deletedPhotos => 'Foto eliminate';
  @override String get swipeDelete => 'Elimina';
  @override String get swipeKeep => 'Tieni';
  @override String get backHome => 'Torna alla home';
  @override String get sponsored => 'Sponsorizzato';
  @override String get adSwipeHint => 'Scorri in una direzione per continuare';
  @override String get permissionTitle => 'Accesso alle foto richiesto';
  @override String get permissionBody => 'CleanFotos ha bisogno di accedere alle tue foto.';
  @override String get openSettings => 'Apri impostazioni';
  @override String get videoAccessTitle => 'Consenti accesso ai video';
  @override String get videoAccessBody => 'Per pulire i video, CleanFotos ha bisogno di accedere a tutti i tuoi video. Apri le Impostazioni e imposta "Foto e video" su Consenti tutto.';
  @override String get limitedAccessTitle => 'Non tutte le foto sono visibili';
  @override String get limitedAccessBody => 'CleanFotos vede solo le foto che hai selezionato. Apri le Impostazioni e imposta "Foto e video" su Consenti tutto.';
  @override String get notNow => 'Non ora';
  @override String get pendingTitle => 'Completa la pulizia';
  @override String pendingBody(int n) => 'Hai contrassegnato $n elemento/i da eliminare l\'ultima volta senza confermare. Eliminarli ora?';
  @override String get pendingConfirm => 'Elimina';
  @override String get pendingLater => 'Mantieni';
  @override String get errorMessage => 'Qualcosa è andato storto';
  @override String get retry => 'Riprova';
  @override String get settings => 'Impostazioni';
  @override String get cleanappsPromoTitle => 'Prova CleanApps';
  @override String get cleanappsPromoSubtitle => 'Scorri per disinstallare le app inutilizzate e libera ancora più spazio.';
  @override String get cleanappsPromoCta => 'Scarica';
  @override String get language => 'Lingua';
  @override String get reminderTitle => 'È ora di fare pulizia! 📸';
  @override String get reminderBody => 'Libera spazio: rivedi le tue foto simili in CleanFotos.';
  @override String get removeAds => 'Rimuovi pubblicità';
  @override String get proTitle => 'CleanFotos Pro';
  @override String get proDesc => 'Rimuovi tutta la pubblicità per sempre con un acquisto unico.';
  @override String proButton(String price) => 'Rimuovi pubblicità · $price';
  @override String get proButtonNoPrice => 'Rimuovi pubblicità';
  @override String get proUnavailable => 'L\'acquisto non è disponibile al momento. Riprova più tardi.';
  @override String get restorePurchase => 'Ripristina acquisto';
  @override String get proUnlocked => 'Pro attivato — grazie! 🎉';
  @override String get about => 'Informazioni';
  @override String get privacyPolicy => 'Informativa sulla privacy';
  @override String get rateApp => 'Valuta CleanFotos';
  @override String get privacyOptions => 'Opzioni privacy degli annunci';
  @override String get appVersion => 'Versione';
}

// ─── Polish ─────────────────────────────────────────────────────────────────
class _PolishStrings extends AppStrings {
  const _PolishStrings() : super._('pl');

  // ── 1.3 Noir ──
  /// Polish plural: 1 → one; 2–4 (but not 12–14) → few; otherwise many.
  String _pl(int n, String one, String few, String many) {
    if (n == 1) return one;
    final m10 = n % 10, m100 = n % 100;
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
    return many;
  }
  @override String get homeTitle => 'Uporządkuj bibliotekę';
  @override String tabPhotos(String n) => 'Zdjęcia · $n';
  @override String tabVideos(String n) => 'Filmy · $n';
  @override String get videosLabel => 'Filmy';
  @override String get upToDate => 'Aktualne · sprawdzono przed chwilą';
  @override String checkedAgo(int m) => 'Aktualne · sprawdzono $m min temu';
  @override String get lookingForNew => 'Szukam nowych zdjęć…';
  @override String get similarShots => 'Podobne zdjęcia';
  @override String get similarShotsDesc => 'Serie i powtórki, zebrane w grupy.';
  @override String get similarClips => 'Podobne filmy';
  @override String get similarClipsDesc => 'Filmy nagrane w odstępie minut, obok siebie.';
  @override String get swipe => 'Przesuwanie';
  @override String get swipePhotosDesc => 'Wszystkie zdjęcia, od najnowszych.';
  @override String get swipeVideosDesc => 'Wszystkie filmy, od najnowszych. Przytrzymaj, aby odtworzyć.';
  @override String get findingGroups => 'Szukam grup…';
  @override String get allowAccess => 'Zezwól na dostęp';
  @override String get selectMorePhotos => 'Wybierz więcej zdjęć';
  @override String get limitedAccessBodyIos => 'CleanFotos widzi tylko wybrane przez Ciebie zdjęcia. Wybierz więcej albo zezwól na pełny dostęp w Ustawieniach.';
  @override String get nextMilestone => 'Następny próg';
  @override String toGo(String size) => 'jeszcze $size';
  @override String ofFreed(String size) => 'z $size zwolnione';
  @override String firstMilestone(String size) => 'Zwolnij pierwsze $size';
  @override String allMilestones(String size) => 'Wszystkie progi osiągnięte · zwolniono $size';
  @override String get removeAdsLink => 'Usuń reklamy · jednorazowy zakup';
  @override String groupsCount(int n, String f) => '$f ${_pl(n, 'grupa', 'grupy', 'grup')}';
  @override String photosCount(int n, String f) => '$f ${_pl(n, 'zdjęcie', 'zdjęcia', 'zdjęć')}';
  @override String videosCount(int n, String f) => '$f ${_pl(n, 'film', 'filmy', 'filmów')}';
  @override String itemsCount(int n, String f) => '$f ${_pl(n, 'element', 'elementy', 'elementów')}';
  @override String reviewed(String n) => 'przejrzane: $n';
  @override String markedPending(String n, String size) => 'oznaczone: $n · ~$size';
  @override String get confirmOnceNote => 'Oznaczone zdjęcia zostaną usunięte, gdy skończysz — potwierdzasz tylko raz.';
  @override String get confirmOnceNoteVideos => 'Oznaczone filmy zostaną usunięte, gdy skończysz — potwierdzasz tylko raz.';
  @override String get swipeFirstHint => 'Przesuń w lewo, aby usunąć · w prawo, aby zachować';
  @override String get finish => 'Zakończ';
  @override String get undo => 'Cofnij';
  @override String get back => 'Wstecz';
  @override String get holdToPlay => 'Przytrzymaj, aby odtworzyć';
  @override String get playing => 'Odtwarzanie…';
  @override String similarCount(int n) => '$n ${_pl(n, 'podobne zdjęcie', 'podobne zdjęcia', 'podobnych zdjęć')}';
  @override String similarClipsCount(int n) => '$n ${_pl(n, 'podobny film', 'podobne filmy', 'podobnych filmów')}';
  @override String get tapToMark => 'Dotknij zdjęć, których nie chcesz';
  @override String get tapToMarkVideos => 'Dotknij filmów, których nie chcesz · Przytrzymaj, aby odtworzyć';
  @override String get keepAllNext => 'Zachowaj wszystkie · Dalej';
  @override String deleteNext(int n) => 'Usuń $n · Dalej';
  @override String get keepAllFinish => 'Zachowaj wszystkie · Zakończ';
  @override String deleteFinish(int n) => 'Usuń $n · Zakończ';
  @override String get previousGroup => 'Poprzednia grupa';
  @override String markedToast(String size) => '+~$size oznaczone';
  @override String freed(String size) => 'Zwolniono $size';
  @override String movedToRecentlyDeleted(MediaKind k, int n, String f) =>
      'Przeniesiono ${mediaCount(k, n, f)} do „Ostatnio usunięte”. Możesz '
      '${n == 1 && k != MediaKind.photos ? 'go' : 'je'} tam przywrócić przez 30 dni.';
  @override String movedToTrash(MediaKind k, int n, String f) => 'Przeniesiono ${mediaCount(k, n, f)} do kosza.';
  @override String deletedPlain(MediaKind k, int n, String f) => 'Usunięto ${mediaCount(k, n, f)}.';
  @override String get milestoneReached => 'PRÓG OSIĄGNIĘTY';
  @override String milestoneLine(String total, String n) => 'Łącznie zwolniono $total — miejsce na około $n nowych zdjęć.';
  @override String nextTier(String size) => 'Następny: $size';
  @override String get keepGoing => 'Działaj dalej';
  @override String get nothingDeleted => 'Nic nie zostało usunięte';
  @override String nothingDeletedBody(MediaKind k) =>
      'Twoje ${switch (k) { MediaKind.photos => 'zdjęcia', MediaKind.videos => 'filmy', MediaKind.items => 'elementy' }} '
      'są nietknięte, a oznaczenia zostały wyczyszczone. Postęp nie został naliczony.';
  @override String get milestones => 'Progi';
  @override String freedInTotal(String n) => 'zwolnione łącznie · usunięto: $n';
  @override String reachedOn(String date) => 'Osiągnięto $date';
  @override String get reached => 'Osiągnięto';
  @override String aboutPhotos(String n) => '≈ $n zdjęć';
  @override String ofTier(String a, String b) => '$a z $b';
  @override String get progress => 'Postęp';
  @override String get today => 'Dziś';
  @override String get yesterday => 'Wczoraj';
  @override List<String> get weekdaysShort => const ['pon.', 'wt.', 'śr.', 'czw.', 'pt.', 'sob.', 'niedz.'];
  @override List<String> get monthsShort => const ['sty', 'lut', 'mar', 'kwi', 'maj', 'cze', 'lip', 'sie', 'wrz', 'paź', 'lis', 'gru'];
  @override String dateThisYear(DateTime d) => '${_wd(d)}, ${d.day} ${_mo(d)}';
  @override String dateWithYear(DateTime d) => '${d.day} ${_mo(d)} ${d.year}';
  @override String dayMonth(DateTime d) => '${d.day} ${_mo(d)}';

  @override String get feedback => 'Dźwięk i wibracje';
  @override String get sounds => 'Dźwięki';
  @override String get haptics => 'Wibracje';

  @override String get analyzingPhotos => 'Analizowanie zdjęć…';
  @override String get allClean => 'Wszystko czyste! 🎉';
  @override String get freedSpace => 'Zwolnione miejsce';
  @override String get deletedPhotos => 'Usunięte zdjęcia';
  @override String get swipeDelete => 'Usuń';
  @override String get swipeKeep => 'Zachowaj';
  @override String get backHome => 'Powrót do ekranu głównego';
  @override String get sponsored => 'Sponsorowane';
  @override String get adSwipeHint => 'Przesuń w dowolną stronę, aby kontynuować';
  @override String get permissionTitle => 'Wymagany dostęp do zdjęć';
  @override String get permissionBody => 'CleanFotos potrzebuje dostępu do Twoich zdjęć, aby znaleźć duplikaty. Przyznaj uprawnienia w Ustawieniach.';
  @override String get openSettings => 'Otwórz ustawienia';
  @override String get videoAccessTitle => 'Zezwól na dostęp do wideo';
  @override String get videoAccessBody => 'Aby uporządkować filmy, CleanFotos potrzebuje dostępu do wszystkich filmów. Otwórz Ustawienia i ustaw „Zdjęcia i wideo" na Zezwól na wszystkie.';
  @override String get limitedAccessTitle => 'Nie wszystkie zdjęcia są widoczne';
  @override String get limitedAccessBody => 'CleanFotos widzi tylko wybrane przez Ciebie zdjęcia. Otwórz Ustawienia i ustaw „Zdjęcia i wideo" na Zezwól na wszystkie.';
  @override String get notNow => 'Nie teraz';
  @override String get pendingTitle => 'Dokończ porządki';
  @override String pendingBody(int n) => 'Ostatnio oznaczono $n element(ów) do usunięcia, ale bez potwierdzenia. Usunąć teraz?';
  @override String get pendingConfirm => 'Usuń';
  @override String get pendingLater => 'Zachowaj';
  @override String get errorMessage => 'Coś poszło nie tak';
  @override String get retry => 'Spróbuj ponownie';
  @override String get settings => 'Ustawienia';
  @override String get cleanappsPromoTitle => 'Wypróbuj CleanApps';
  @override String get cleanappsPromoSubtitle => 'Przesuwaj, aby usunąć nieużywane aplikacje i zwolnić jeszcze więcej miejsca.';
  @override String get cleanappsPromoCta => 'Pobierz';
  @override String get language => 'Język';
  @override String get reminderTitle => 'Czas na porządki! 📸';
  @override String get reminderBody => 'Zwolnij miejsce — przejrzyj podobne zdjęcia w CleanFotos.';
  @override String get removeAds => 'Usuń reklamy';
  @override String get proTitle => 'CleanFotos Pro';
  @override String get proDesc => 'Usuń wszystkie reklamy na zawsze jednym zakupem.';
  @override String proButton(String price) => 'Usuń reklamy · $price';
  @override String get proButtonNoPrice => 'Usuń reklamy';
  @override String get proUnavailable => 'Zakup jest teraz niedostępny. Spróbuj ponownie później.';
  @override String get restorePurchase => 'Przywróć zakup';
  @override String get proUnlocked => 'Pro odblokowane — dziękujemy! 🎉';
  @override String get about => 'O aplikacji';
  @override String get privacyPolicy => 'Polityka prywatności';
  @override String get rateApp => 'Oceń CleanFotos';
  @override String get privacyOptions => 'Opcje prywatności reklam';
  @override String get appVersion => 'Wersja';
}
