import 'package:classlift/utils/home_subtitle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getHomeSubtitle', () {
    test('shows setup message when there is no schedule', () {
      expect(
        getHomeSubtitle(
          hasSchedule: false,
          classesToday: 3,
          examsToday: 2,
          examsTomorrow: 1,
          tasksDueToday: 4,
          isMoodleConnected: true,
        ),
        'Empecemos a organizar tu semestre ✨',
      );
    });

    test('shows one task due today when Moodle is connected', () {
      expect(
        getHomeSubtitle(
          hasSchedule: true,
          classesToday: 3,
          examsToday: 1,
          examsTomorrow: 1,
          tasksDueToday: 1,
          isMoodleConnected: true,
        ),
        'Tenés una entrega para hoy.',
      );
    });

    test('shows multiple tasks due today when Moodle is connected', () {
      expect(
        getHomeSubtitle(
          hasSchedule: true,
          classesToday: 3,
          examsToday: 1,
          examsTomorrow: 1,
          tasksDueToday: 2,
          isMoodleConnected: true,
        ),
        'Tenés 2 entregas para hoy.',
      );
    });

    test('ignores Moodle tasks when Moodle is not connected', () {
      expect(
        getHomeSubtitle(
          hasSchedule: true,
          classesToday: 0,
          examsToday: 0,
          examsTomorrow: 0,
          tasksDueToday: 2,
          isMoodleConnected: false,
        ),
        'Hoy podés tomártelo con calma ☀️',
      );
    });

    test('shows one exam today', () {
      expect(
        getHomeSubtitle(
          hasSchedule: true,
          classesToday: 3,
          examsToday: 1,
          examsTomorrow: 1,
          tasksDueToday: 0,
          isMoodleConnected: true,
        ),
        'Tenés una evaluación hoy. ¡Éxitos! 💪',
      );
    });

    test('shows multiple exams today', () {
      expect(
        getHomeSubtitle(
          hasSchedule: true,
          classesToday: 3,
          examsToday: 2,
          examsTomorrow: 1,
          tasksDueToday: 0,
          isMoodleConnected: true,
        ),
        'Tenés 2 evaluaciones hoy. ¡Éxitos! 💪',
      );
    });

    test('shows exam tomorrow when there is no higher priority state', () {
      expect(
        getHomeSubtitle(
          hasSchedule: true,
          classesToday: 3,
          examsToday: 0,
          examsTomorrow: 1,
          tasksDueToday: 0,
          isMoodleConnected: true,
        ),
        'Tu próxima evaluación es mañana.',
      );
    });

    test('shows one class today', () {
      expect(
        getHomeSubtitle(
          hasSchedule: true,
          classesToday: 1,
          examsToday: 0,
          examsTomorrow: 0,
          tasksDueToday: 0,
          isMoodleConnected: true,
        ),
        'Tenés 1 clase por delante.',
      );
    });

    test('shows multiple classes today', () {
      expect(
        getHomeSubtitle(
          hasSchedule: true,
          classesToday: 3,
          examsToday: 0,
          examsTomorrow: 0,
          tasksDueToday: 0,
          isMoodleConnected: true,
        ),
        'Tenés 3 clases por delante.',
      );
    });

    test('shows calm day when there is a schedule but no classes today', () {
      expect(
        getHomeSubtitle(
          hasSchedule: true,
          classesToday: 0,
          examsToday: 0,
          examsTomorrow: 0,
          tasksDueToday: 0,
          isMoodleConnected: true,
        ),
        'Hoy podés tomártelo con calma ☀️',
      );
    });

    test('tasks due today have priority over exams today', () {
      expect(
        getHomeSubtitle(
          hasSchedule: true,
          classesToday: 3,
          examsToday: 2,
          examsTomorrow: 1,
          tasksDueToday: 1,
          isMoodleConnected: true,
        ),
        'Tenés una entrega para hoy.',
      );
    });

    test('exams today have priority over exams tomorrow and classes', () {
      expect(
        getHomeSubtitle(
          hasSchedule: true,
          classesToday: 3,
          examsToday: 1,
          examsTomorrow: 1,
          tasksDueToday: 0,
          isMoodleConnected: true,
        ),
        'Tenés una evaluación hoy. ¡Éxitos! 💪',
      );
    });

    test('exams tomorrow have priority over classes today', () {
      expect(
        getHomeSubtitle(
          hasSchedule: true,
          classesToday: 3,
          examsToday: 0,
          examsTomorrow: 1,
          tasksDueToday: 0,
          isMoodleConnected: true,
        ),
        'Tu próxima evaluación es mañana.',
      );
    });
  });
}
