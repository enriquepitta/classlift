String getHomeSubtitle({
  required bool hasSchedule,
  required int classesToday,
  required int examsToday,
  required int examsTomorrow,
  required int tasksDueToday,
  required bool isMoodleConnected,
}) {
  if (!hasSchedule) {
    return 'Empecemos a organizar tu semestre ✨';
  }

  if (isMoodleConnected && tasksDueToday > 0) {
    return tasksDueToday == 1
        ? 'Tenés una entrega para hoy.'
        : 'Tenés $tasksDueToday entregas para hoy.';
  }

  if (examsToday > 0) {
    return examsToday == 1
        ? 'Tenés una evaluación hoy. ¡Éxitos! 💪'
        : 'Tenés $examsToday evaluaciones hoy. ¡Éxitos! 💪';
  }

  if (examsTomorrow > 0) {
    return 'Tu próxima evaluación es mañana.';
  }

  if (classesToday > 0) {
    return classesToday == 1
        ? 'Tenés 1 clase por delante.'
        : 'Tenés $classesToday clases por delante.';
  }

  if (hasSchedule) {
    return 'Hoy podés tomártelo con calma ☀️';
  }

  return 'Todo listo para hoy ✨';
}
