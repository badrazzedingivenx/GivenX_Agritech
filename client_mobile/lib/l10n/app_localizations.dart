import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @registerFarmingType.
  ///
  /// In en, this message translates to:
  /// **'Type of Farming'**
  String get registerFarmingType;

  /// No description provided for @registerFarmingTypeAgriculture.
  ///
  /// In en, this message translates to:
  /// **'Agriculture'**
  String get registerFarmingTypeAgriculture;

  /// No description provided for @registerFarmingTypeLivestock.
  ///
  /// In en, this message translates to:
  /// **'Livestock'**
  String get registerFarmingTypeLivestock;

  /// No description provided for @registerFarmingTypeBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get registerFarmingTypeBoth;

  /// No description provided for @registerMainProducts.
  ///
  /// In en, this message translates to:
  /// **'Main Products'**
  String get registerMainProducts;

  /// No description provided for @registerProductMaize.
  ///
  /// In en, this message translates to:
  /// **'Maize'**
  String get registerProductMaize;

  /// No description provided for @registerProductWheat.
  ///
  /// In en, this message translates to:
  /// **'Wheat'**
  String get registerProductWheat;

  /// No description provided for @registerProductRice.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get registerProductRice;

  /// No description provided for @registerProductCattle.
  ///
  /// In en, this message translates to:
  /// **'Cattle'**
  String get registerProductCattle;

  /// No description provided for @registerProductGoats.
  ///
  /// In en, this message translates to:
  /// **'Goats'**
  String get registerProductGoats;

  /// No description provided for @registerProductSheep.
  ///
  /// In en, this message translates to:
  /// **'Sheep'**
  String get registerProductSheep;

  /// No description provided for @registerProductVegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get registerProductVegetables;

  /// No description provided for @registerProductFruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get registerProductFruits;

  /// No description provided for @registerProductOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get registerProductOther;

  /// No description provided for @registerProductCereals.
  ///
  /// In en, this message translates to:
  /// **'Cereals'**
  String get registerProductCereals;

  /// No description provided for @registerProductLegumes.
  ///
  /// In en, this message translates to:
  /// **'Legumes'**
  String get registerProductLegumes;

  /// No description provided for @registerProductDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy Products'**
  String get registerProductDairy;

  /// No description provided for @registerProductMeat.
  ///
  /// In en, this message translates to:
  /// **'Meat & Poultry'**
  String get registerProductMeat;

  /// No description provided for @registerProductProcessed.
  ///
  /// In en, this message translates to:
  /// **'Processed Food'**
  String get registerProductProcessed;

  /// No description provided for @registerProductOrganic.
  ///
  /// In en, this message translates to:
  /// **'Organic Products'**
  String get registerProductOrganic;

  /// No description provided for @registerProductFeed.
  ///
  /// In en, this message translates to:
  /// **'Animal Feed'**
  String get registerProductFeed;

  /// No description provided for @registerProductTypes.
  ///
  /// In en, this message translates to:
  /// **'Product Types'**
  String get registerProductTypes;

  /// No description provided for @registerCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get registerCompanyName;

  /// No description provided for @registerUsineTitle.
  ///
  /// In en, this message translates to:
  /// **'Register as Exporter/Factory'**
  String get registerUsineTitle;

  /// No description provided for @registerUsineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your exporter/factory account'**
  String get registerUsineSubtitle;

  /// No description provided for @registerTransporteurTitle.
  ///
  /// In en, this message translates to:
  /// **'Register as Transporter'**
  String get registerTransporteurTitle;

  /// No description provided for @registerTransporteurSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your transporter account'**
  String get registerTransporteurSubtitle;

  /// No description provided for @registerVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get registerVehicleType;

  /// No description provided for @registerVehicleTruck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get registerVehicleTruck;

  /// No description provided for @registerVehicleVan.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get registerVehicleVan;

  /// No description provided for @registerVehiclePickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get registerVehiclePickup;

  /// No description provided for @registerCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity (e.g., 2 tons)'**
  String get registerCapacity;

  /// No description provided for @registerBanqueTitle.
  ///
  /// In en, this message translates to:
  /// **'Register as Bank'**
  String get registerBanqueTitle;

  /// No description provided for @registerBanqueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your bank account'**
  String get registerBanqueSubtitle;

  /// No description provided for @registerBankName.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get registerBankName;

  /// No description provided for @registerOfficialId.
  ///
  /// In en, this message translates to:
  /// **'Official ID (ex: CAM-001)'**
  String get registerOfficialId;

  /// No description provided for @registerInstitutionalEmail.
  ///
  /// In en, this message translates to:
  /// **'Institutional Email'**
  String get registerInstitutionalEmail;

  /// No description provided for @registerUploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload Logo / Verification Documents'**
  String get registerUploadLogo;

  /// No description provided for @registerNoFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get registerNoFileSelected;

  /// No description provided for @registerUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get registerUpload;

  /// No description provided for @registerFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get registerFieldRequired;

  /// No description provided for @registerInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get registerInvalidEmail;

  /// No description provided for @registerPasswordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'Password too weak'**
  String get registerPasswordTooWeak;

  /// No description provided for @registerPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get registerPasswordsDoNotMatch;

  /// No description provided for @registerConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get registerConfirmPassword;

  /// No description provided for @registerSelectAtLeastOneProduct.
  ///
  /// In en, this message translates to:
  /// **'Select at least one product'**
  String get registerSelectAtLeastOneProduct;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AgriFlow'**
  String get appTitle;

  /// No description provided for @introFarmerTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get introFarmerTitle;

  /// No description provided for @introFarmerDesc.
  ///
  /// In en, this message translates to:
  /// **'Publish your harvests, receive orders, and request financing.'**
  String get introFarmerDesc;

  /// No description provided for @introFactoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Factory / Exporter'**
  String get introFactoryTitle;

  /// No description provided for @introFactoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Publish orders, track shipments, and manage your supply chain.'**
  String get introFactoryDesc;

  /// No description provided for @introTransporterTitle.
  ///
  /// In en, this message translates to:
  /// **'Transporter'**
  String get introTransporterTitle;

  /// No description provided for @introTransporterDesc.
  ///
  /// In en, this message translates to:
  /// **'View assigned deliveries, accept new missions, and optimize your routes.'**
  String get introTransporterDesc;

  /// No description provided for @introBankTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get introBankTitle;

  /// No description provided for @introBankDesc.
  ///
  /// In en, this message translates to:
  /// **'Finance agricultural projects, manage transactions, and support the ecosystem.'**
  String get introBankDesc;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back please login to your account'**
  String get loginSubtitle;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailHint;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPassword;

  /// No description provided for @loginForgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get loginForgotPasswordTitle;

  /// No description provided for @loginForgotPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a reset link.'**
  String get loginForgotPasswordDesc;

  /// No description provided for @loginEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get loginEmailRequired;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid Gmail address'**
  String get loginEmailInvalid;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get loginPasswordRequired;

  /// No description provided for @loginRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get loginRememberMe;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get loginNoAccount;

  /// No description provided for @loginSignup.
  ///
  /// In en, this message translates to:
  /// **'Signup'**
  String get loginSignup;

  /// No description provided for @loginUnknownRole.
  ///
  /// In en, this message translates to:
  /// **'Unknown role.'**
  String get loginUnknownRole;

  /// No description provided for @loginInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get loginInvalidCredentials;

  /// No description provided for @loginResetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'If this email exists, a reset link has been sent. (demo only)'**
  String get loginResetLinkSent;

  /// No description provided for @roleSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Your Role'**
  String get roleSelectTitle;

  /// No description provided for @registerUnknownRole.
  ///
  /// In en, this message translates to:
  /// **'Unknown role'**
  String get registerUnknownRole;

  /// No description provided for @registerFarmerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register as Farmer'**
  String get registerFarmerTitle;

  /// No description provided for @registerFarmerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your farmer account'**
  String get registerFarmerSubtitle;

  /// No description provided for @registerFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get registerFullName;

  /// No description provided for @registerPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get registerPhoneNumber;

  /// No description provided for @registerCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get registerCity;

  /// No description provided for @registerEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get registerEmail;

  /// No description provided for @roleFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get roleFarmer;

  /// No description provided for @roleFactory.
  ///
  /// In en, this message translates to:
  /// **'Factory/Exporter'**
  String get roleFactory;

  /// No description provided for @roleTransporter.
  ///
  /// In en, this message translates to:
  /// **'Transporter'**
  String get roleTransporter;

  /// No description provided for @roleBanque.
  ///
  /// In en, this message translates to:
  /// **'Banque'**
  String get roleBanque;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
