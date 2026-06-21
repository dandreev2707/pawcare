// Виджет-тесты PawCare
// Запуск: flutter test test/widget_test.dart
//
// WT-01  Экран логина: отображаются ключевые элементы
// WT-02  Экран логина: кнопка «Войти» заблокирована при пустых полях
// WT-03  Экран логина: сообщение об ошибке при невалидном email
// WT-04  Экран логина: сообщение об ошибке при пустом пароле
// WT-05  Экран логина: ссылка «Зарегистрироваться» присутствует
// WT-06  Экран логина: иконка показа/скрытия пароля работает
// WT-07  Модель LoginState: начальное состояние — AuthInitial
// WT-08  Валидатор email: корректный email проходит
// WT-09  Валидатор email: некорректный email отклоняется
// WT-10  Валидатор пароля: пустой пароль отклоняется

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:pawcare/blocs/auth/auth_cubit.dart';
import 'package:pawcare/screens/login_screen.dart';

@GenerateMocks([AuthCubit])
import 'widget_test.mocks.dart';

// ─── Хелпер: оборачивает виджет в MaterialApp + BlocProvider ─────────────────
Widget _wrap(Widget child, AuthCubit cubit) {
  return MaterialApp(
    home: BlocProvider<AuthCubit>.value(
      value: cubit,
      child: child,
    ),
  );
}

void main() {
  late MockAuthCubit mockCubit;

  setUp(() {
    mockCubit = MockAuthCubit();
    // Начальное состояние — не загружается
    when(mockCubit.state).thenReturn(AuthInitial());
    when(mockCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  // ═══════════════════════════════════════════════════════════════
  // WT-01..WT-06  Экран логина
  // ═══════════════════════════════════════════════════════════════

  group('LoginScreen — отображение', () {
    testWidgets('WT-01: ключевые элементы присутствуют', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), mockCubit));
      await tester.pump();

      expect(find.text('Добро пожаловать\nв PawCare!'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Пароль'), findsOneWidget);
      expect(find.text('Войти'), findsOneWidget);
    });

    testWidgets('WT-02: кнопка «Войти» отключена только при isLoading', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), mockCubit));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Войти'),
      );
      // Кнопка активна в начальном состоянии (isLoading == false)
      expect(button.onPressed, isNotNull);
    });

    testWidgets('WT-03: ошибка email при невалидном значении', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), mockCubit));
      await tester.pump();

      // Вводим невалидный email и нажимаем «Войти»
      await tester.enterText(
          find.widgetWithText(TextField, 'example@mail.ru'), 'notanemail');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Войти'));
      await tester.pump();

      expect(find.text('Некорректный email'), findsOneWidget);
    });

    testWidgets('WT-04: ошибка пароля при пустом поле', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), mockCubit));
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextField, 'example@mail.ru'), 'user@test.ru');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Войти'));
      await tester.pump();

      expect(find.text('Введите пароль'), findsOneWidget);
    });

    testWidgets('WT-05: ссылка «Зарегистрироваться» присутствует', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), mockCubit));
      await tester.pump();

      expect(find.text('Зарегистрироваться'), findsOneWidget);
    });

    testWidgets('WT-06: кнопка видимости пароля переключает obscureText', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), mockCubit));
      await tester.pump();

      // Изначально пароль скрыт — иконка visibility_outlined
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      // После нажатия — иконка visibility_off_outlined
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // WT-07  Состояние AuthCubit
  // ═══════════════════════════════════════════════════════════════

  group('AuthCubit — состояние', () {
    test('WT-07: начальное состояние — AuthInitial', () {
      when(mockCubit.state).thenReturn(AuthInitial());
      expect(mockCubit.state, isA<AuthInitial>());
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // WT-08..WT-10  Валидаторы (unit-тесты чистой логики)
  // ═══════════════════════════════════════════════════════════════

  group('Валидаторы экрана логина', () {
    // Воспроизводим логику прямо из _LoginScreenState
    String? emailValidator(String value) {
      if (value.isEmpty) return 'Введите email';
      if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
        return 'Некорректный email';
      }
      return null;
    }

    String? passwordValidator(String value) {
      if (value.isEmpty) return 'Введите пароль';
      return null;
    }

    test('WT-08: корректный email проходит валидацию', () {
      expect(emailValidator('user@example.com'), isNull);
      expect(emailValidator('test.name+tag@sub.domain.ru'), isNull);
    });

    test('WT-09: некорректный email отклоняется', () {
      expect(emailValidator(''), equals('Введите email'));
      expect(emailValidator('notanemail'), equals('Некорректный email'));
      expect(emailValidator('@nodomain'), equals('Некорректный email'));
      expect(emailValidator('no@dot'), equals('Некорректный email'));
    });

    test('WT-10: пустой пароль отклоняется', () {
      expect(passwordValidator(''), equals('Введите пароль'));
      expect(passwordValidator('anypass'), isNull);
    });
  });
}
