import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();
  
  // Brand colors - using more conservative financial colors
  // Primary: Deep blue for trust and stability
  static const Color primaryColor = Color(0xFF0D47A1); 
  // Secondary: Forest green for growth and prosperity
  static const Color secondaryColor = Color(0xFF2E7D32); 
  // Accent: Gold for wealth and success
  static const Color accentColor = Color(0xFFFFB300); 
  // Error: Subdued red that's less alarming
  static const Color errorColor = Color(0xFFD32F2F); 
  
  // Money colors
  static const Color positiveAmountColor = Color(0xFF2E7D32); // Green for positive balances
  static const Color negativeAmountColor = Color(0xFFD32F2F); // Red for negative balances
  static const Color savingsHighlightColor = Color(0xFF1565C0); // Blue for savings
  static const Color loanHighlightColor = Color(0xFF6A1B9A); // Purple for loans
  
  // Text colors
  static const Color textPrimaryDark = Color(0xFF263238); // Slightly softer than pure black
  static const Color textSecondaryDark = Color(0xFF546E7A);
  static const Color textPrimaryLight = Color(0xFFECEFF1);
  static const Color textSecondaryLight = Color(0xFFCFD8DC);
  
  // Background colors
  static const Color backgroundLight = Color(0xFFFAFAFA); // Slightly off-white for less eye strain
  static const Color backgroundDark = Color(0xFF102027);
  static const Color cardBackgroundLight = Color(0xFFFFFFFF);
  static const Color cardBackgroundDark = Color(0xFF1C313A);
  
  // Additional SACCO-specific colors
  static const Color dividerColor = Color(0xFFBDBDBD);
  static const Color inactiveColor = Color(0xFF78909C);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFFFA000);
  static const Color chartBlue = Color(0xFF1976D2);
  static const Color chartGreen = Color(0xFF388E3C);
  static const Color chartAmber = Color(0xFFFFA000);
  static const Color chartRed = Color(0xFFD32F2F);
  
  // Light theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      tertiary: accentColor,
    ),
    appBarTheme: const AppBarTheme(
      color: primaryColor,
      titleTextStyle: TextStyle(
        color: textPrimaryLight,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: textPrimaryLight),
      elevation: 2,
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.interTextTheme().copyWith(
      // Headings - using Roboto Slab for authority and trust
      displayLarge: GoogleFonts.robotoSlab(
        color: textPrimaryDark, 
        fontSize: 26, 
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.robotoSlab(
        color: textPrimaryDark, 
        fontSize: 22, 
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.robotoSlab(
        color: textPrimaryDark, 
        fontSize: 18, 
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.robotoSlab(
        color: textPrimaryDark, 
        fontSize: 20, 
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.robotoSlab(
        color: textPrimaryDark, 
        fontSize: 18, 
        fontWeight: FontWeight.w500,
      ),
      titleSmall: GoogleFonts.robotoSlab(
        color: textPrimaryDark, 
        fontSize: 16, 
        fontWeight: FontWeight.w500,
      ),
      // Body text - using Inter for readability
      bodyLarge: GoogleFonts.inter(
        color: textPrimaryDark, 
        fontSize: 16, 
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        color: textPrimaryDark, 
        fontSize: 14, 
        height: 1.4,
      ),
      bodySmall: GoogleFonts.inter(
        color: textSecondaryDark, 
        fontSize: 12, 
        height: 1.3,
      ),
      // Labels and buttons
      labelLarge: GoogleFonts.inter(
        color: primaryColor, 
        fontSize: 14, 
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: Colors.grey[700]),
      floatingLabelStyle: const TextStyle(color: primaryColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textPrimaryLight,
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 1,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    cardTheme: CardThemeData(
      color: cardBackgroundLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 24,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardBackgroundLight,
      selectedItemColor: primaryColor,
      unselectedItemColor: inactiveColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: inactiveColor,
      indicatorColor: primaryColor,
      labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[100]!,
      disabledColor: Colors.grey[200]!,
      selectedColor: primaryColor.withOpacity(0.1),
      secondarySelectedColor: secondaryColor.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(color: textPrimaryDark, fontSize: 14),
      secondaryLabelStyle: const TextStyle(color: textPrimaryDark, fontSize: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    ),
  );
  
  // Dark theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      tertiary: accentColor,
      surface: cardBackgroundDark,
      background: backgroundDark,
    ),
    appBarTheme: const AppBarTheme(
      color: Color(0xFF0A1929),
      titleTextStyle: TextStyle(
        color: textPrimaryLight,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: textPrimaryLight),
      elevation: 2,
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      // Headings - using Roboto Slab for authority and trust
      displayLarge: GoogleFonts.robotoSlab(
        color: textPrimaryLight, 
        fontSize: 26, 
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.robotoSlab(
        color: textPrimaryLight, 
        fontSize: 22, 
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.robotoSlab(
        color: textPrimaryLight, 
        fontSize: 18, 
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.robotoSlab(
        color: textPrimaryLight, 
        fontSize: 20, 
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.robotoSlab(
        color: textPrimaryLight, 
        fontSize: 18, 
        fontWeight: FontWeight.w500,
      ),
      titleSmall: GoogleFonts.robotoSlab(
        color: textPrimaryLight, 
        fontSize: 16, 
        fontWeight: FontWeight.w500,
      ),
      // Body text - using Inter for readability
      bodyLarge: GoogleFonts.inter(
        color: textPrimaryLight, 
        fontSize: 16, 
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        color: textPrimaryLight, 
        fontSize: 14, 
        height: 1.4,
      ),
      bodySmall: GoogleFonts.inter(
        color: textSecondaryLight, 
        fontSize: 12, 
        height: 1.3,
      ),
      // Labels and buttons
      labelLarge: GoogleFonts.inter(
        color: accentColor, 
        fontSize: 14, 
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
      ),
      filled: true,
      fillColor: const Color(0xFF263238),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: textSecondaryLight),
      floatingLabelStyle: const TextStyle(color: accentColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textPrimaryLight,
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 1,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentColor,
        side: const BorderSide(color: accentColor, width: 1.5),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    cardTheme: CardThemeData(
      color: cardBackgroundDark,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey[800]!,
      thickness: 1,
      space: 24,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: cardBackgroundDark,
      selectedItemColor: accentColor,
      unselectedItemColor: Colors.grey[500],
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: accentColor,
      unselectedLabelColor: textSecondaryLight,
      indicatorColor: accentColor,
      labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF263238),
      disabledColor: const Color(0xFF1C272B),
      selectedColor: primaryColor.withOpacity(0.3),
      secondarySelectedColor: secondaryColor.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(color: textPrimaryLight, fontSize: 14),
      secondaryLabelStyle: const TextStyle(color: textPrimaryLight, fontSize: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[700]!),
      ),
    ),
  );
  
  // Helper methods for financial formatting
  static TextStyle getAmountTextStyle(double amount, {bool bold = false, double fontSize = 16}) {
    Color textColor = amount >= 0 ? positiveAmountColor : negativeAmountColor;
    return TextStyle(
      color: textColor,
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.bold : FontWeight.w500,
    );
  }
  
  static TextStyle getSavingsTextStyle({bool bold = false, double fontSize = 14}) {
    return TextStyle(
      color: savingsHighlightColor,
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.bold : FontWeight.w500,
    );
  }
  
  static TextStyle getLoanTextStyle({bool bold = false, double fontSize = 14}) {
    return TextStyle(
      color: loanHighlightColor,
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.bold : FontWeight.w500,
    );
  }
}