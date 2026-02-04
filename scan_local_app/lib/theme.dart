import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff0f6b57),
      surfaceTint: Color(0xff0f6b57),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffa2f2d9),
      onPrimaryContainer: Color(0xff005141),
      secondary: Color(0xff4b635b),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffcde9de),
      onSecondaryContainer: Color(0xff344c44),
      tertiary: Color(0xff416277),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffc5e7ff),
      onTertiaryContainer: Color(0xff284b5e),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff5fbf6),
      onSurface: Color(0xff171d1b),
      onSurfaceVariant: Color(0xff3f4945),
      outline: Color(0xff6f7975),
      outlineVariant: Color(0xffbfc9c4),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2b322f),
      inversePrimary: Color(0xff86d6bd),
      primaryFixed: Color(0xffa2f2d9),
      onPrimaryFixed: Color(0xff002019),
      primaryFixedDim: Color(0xff86d6bd),
      onPrimaryFixedVariant: Color(0xff005141),
      secondaryFixed: Color(0xffcde9de),
      onSecondaryFixed: Color(0xff072019),
      secondaryFixedDim: Color(0xffb2ccc2),
      onSecondaryFixedVariant: Color(0xff344c44),
      tertiaryFixed: Color(0xffc5e7ff),
      onTertiaryFixed: Color(0xff001e2d),
      tertiaryFixedDim: Color(0xffa9cbe2),
      onTertiaryFixedVariant: Color(0xff284b5e),
      surfaceDim: Color(0xffd5dbd7),
      surfaceBright: Color(0xfff5fbf6),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff5f1),
      surfaceContainer: Color(0xffe9efeb),
      surfaceContainerHigh: Color(0xffe3eae5),
      surfaceContainerHighest: Color(0xffdee4e0),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003e31),
      surfaceTint: Color(0xff0f6b57),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff277a66),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff233b33),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff597269),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff163a4c),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff507186),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff5fbf6),
      onSurface: Color(0xff0c1210),
      onSurfaceVariant: Color(0xff2f3835),
      outline: Color(0xff4b5551),
      outlineVariant: Color(0xff656f6b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2b322f),
      inversePrimary: Color(0xff86d6bd),
      primaryFixed: Color(0xff277a66),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff00604e),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff597269),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff425a52),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff507186),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff37596d),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc2c8c4),
      surfaceBright: Color(0xfff5fbf6),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff5f1),
      surfaceContainer: Color(0xffe3eae5),
      surfaceContainerHigh: Color(0xffd8deda),
      surfaceContainerHighest: Color(0xffcdd3cf),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003328),
      surfaceTint: Color(0xff0f6b57),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff005343),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff193029),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff364e46),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff083042),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff2b4d60),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff5fbf6),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff252e2b),
      outlineVariant: Color(0xff424b47),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2b322f),
      inversePrimary: Color(0xff86d6bd),
      primaryFixed: Color(0xff005343),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff003a2e),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff364e46),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff203730),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff2b4d60),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff113649),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb4bab6),
      surfaceBright: Color(0xfff5fbf6),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffecf2ee),
      surfaceContainer: Color(0xffdee4e0),
      surfaceContainerHigh: Color(0xffd0d6d2),
      surfaceContainerHighest: Color(0xffc2c8c4),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff86d6bd),
      surfaceTint: Color(0xff86d6bd),
      onPrimary: Color(0xff00382c),
      primaryContainer: Color(0xff005141),
      onPrimaryContainer: Color(0xffa2f2d9),
      secondary: Color(0xffb2ccc2),
      onSecondary: Color(0xff1d352e),
      secondaryContainer: Color(0xff344c44),
      onSecondaryContainer: Color(0xffcde9de),
      tertiary: Color(0xffa9cbe2),
      onTertiary: Color(0xff0e3446),
      tertiaryContainer: Color(0xff284b5e),
      onTertiaryContainer: Color(0xffc5e7ff),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff0f1512),
      onSurface: Color(0xffdee4e0),
      onSurfaceVariant: Color(0xffbfc9c4),
      outline: Color(0xff89938e),
      outlineVariant: Color(0xff3f4945),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee4e0),
      inversePrimary: Color(0xff0f6b57),
      primaryFixed: Color(0xffa2f2d9),
      onPrimaryFixed: Color(0xff002019),
      primaryFixedDim: Color(0xff86d6bd),
      onPrimaryFixedVariant: Color(0xff005141),
      secondaryFixed: Color(0xffcde9de),
      onSecondaryFixed: Color(0xff072019),
      secondaryFixedDim: Color(0xffb2ccc2),
      onSecondaryFixedVariant: Color(0xff344c44),
      tertiaryFixed: Color(0xffc5e7ff),
      onTertiaryFixed: Color(0xff001e2d),
      tertiaryFixedDim: Color(0xffa9cbe2),
      onTertiaryFixedVariant: Color(0xff284b5e),
      surfaceDim: Color(0xff0f1512),
      surfaceBright: Color(0xff343b38),
      surfaceContainerLowest: Color(0xff090f0d),
      surfaceContainerLow: Color(0xff171d1b),
      surfaceContainer: Color(0xff1b211f),
      surfaceContainerHigh: Color(0xff252b29),
      surfaceContainerHighest: Color(0xff303633),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff9cecd3),
      surfaceTint: Color(0xff86d6bd),
      onPrimary: Color(0xff002c22),
      primaryContainer: Color(0xff509f89),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffc7e2d8),
      onSecondary: Color(0xff122a23),
      secondaryContainer: Color(0xff7d968d),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffbee1f9),
      onTertiary: Color(0xff00293b),
      tertiaryContainer: Color(0xff7395ab),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff0f1512),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffd5dfd9),
      outline: Color(0xffaab4af),
      outlineVariant: Color(0xff89938e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee4e0),
      inversePrimary: Color(0xff005242),
      primaryFixed: Color(0xffa2f2d9),
      onPrimaryFixed: Color(0xff00150f),
      primaryFixedDim: Color(0xff86d6bd),
      onPrimaryFixedVariant: Color(0xff003e31),
      secondaryFixed: Color(0xffcde9de),
      onSecondaryFixed: Color(0xff00150f),
      secondaryFixedDim: Color(0xffb2ccc2),
      onSecondaryFixedVariant: Color(0xff233b33),
      tertiaryFixed: Color(0xffc5e7ff),
      onTertiaryFixed: Color(0xff00131e),
      tertiaryFixedDim: Color(0xffa9cbe2),
      onTertiaryFixedVariant: Color(0xff163a4c),
      surfaceDim: Color(0xff0f1512),
      surfaceBright: Color(0xff3f4643),
      surfaceContainerLowest: Color(0xff040807),
      surfaceContainerLow: Color(0xff191f1d),
      surfaceContainer: Color(0xff232927),
      surfaceContainerHigh: Color(0xff2e3431),
      surfaceContainerHighest: Color(0xff393f3c),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffb4ffe7),
      surfaceTint: Color(0xff86d6bd),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xff83d2ba),
      onPrimaryContainer: Color(0xff000e09),
      secondary: Color(0xffdbf6eb),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffaec8be),
      onSecondaryContainer: Color(0xff000e09),
      tertiary: Color(0xffe2f2ff),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffa5c7de),
      onTertiaryContainer: Color(0xff000d16),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff0f1512),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffe8f2ed),
      outlineVariant: Color(0xffbbc5c0),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee4e0),
      inversePrimary: Color(0xff005242),
      primaryFixed: Color(0xffa2f2d9),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xff86d6bd),
      onPrimaryFixedVariant: Color(0xff00150f),
      secondaryFixed: Color(0xffcde9de),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffb2ccc2),
      onSecondaryFixedVariant: Color(0xff00150f),
      tertiaryFixed: Color(0xffc5e7ff),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffa9cbe2),
      onTertiaryFixedVariant: Color(0xff00131e),
      surfaceDim: Color(0xff0f1512),
      surfaceBright: Color(0xff4b514f),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1b211f),
      surfaceContainer: Color(0xff2b322f),
      surfaceContainerHigh: Color(0xff363d3a),
      surfaceContainerHighest: Color(0xff424845),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.background,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
