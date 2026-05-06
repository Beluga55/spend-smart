import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Tracker'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @budgetSettings.
  ///
  /// In en, this message translates to:
  /// **'Budget Settings'**
  String get budgetSettings;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @overall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overall;

  /// No description provided for @setBudget.
  ///
  /// In en, this message translates to:
  /// **'Set Budget'**
  String get setBudget;

  /// No description provided for @updateBudget.
  ///
  /// In en, this message translates to:
  /// **'Update Budget'**
  String get updateBudget;

  /// No description provided for @removeBudget.
  ///
  /// In en, this message translates to:
  /// **'Remove Budget'**
  String get removeBudget;

  /// No description provided for @noBudget.
  ///
  /// In en, this message translates to:
  /// **'No Budget'**
  String get noBudget;

  /// No description provided for @trackWithoutLimit.
  ///
  /// In en, this message translates to:
  /// **'Track without limit'**
  String get trackWithoutLimit;

  /// No description provided for @monthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget'**
  String get monthlyBudget;

  /// No description provided for @setTotalLimit.
  ///
  /// In en, this message translates to:
  /// **'Set a total spending limit for the month'**
  String get setTotalLimit;

  /// No description provided for @budgetAmount.
  ///
  /// In en, this message translates to:
  /// **'Budget Amount'**
  String get budgetAmount;

  /// No description provided for @youWillReceiveAlerts.
  ///
  /// In en, this message translates to:
  /// **'You\'ll receive alerts at 80% and 100% of your budget'**
  String get youWillReceiveAlerts;

  /// No description provided for @budgetExceeded.
  ///
  /// In en, this message translates to:
  /// **'Budget exceeded!'**
  String get budgetExceeded;

  /// No description provided for @approachingLimit.
  ///
  /// In en, this message translates to:
  /// **'Approaching budget limit'**
  String get approachingLimit;

  /// No description provided for @categoryBudgetExceeded.
  ///
  /// In en, this message translates to:
  /// **'Category budget exceeded!'**
  String get categoryBudgetExceeded;

  /// No description provided for @approachingCategoryLimit.
  ///
  /// In en, this message translates to:
  /// **'Approaching category limit'**
  String get approachingCategoryLimit;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remaining;

  /// No description provided for @overBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget!'**
  String get overBudget;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpense;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @addANote.
  ///
  /// In en, this message translates to:
  /// **'Add a note...'**
  String get addANote;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get deleteExpense;

  /// No description provided for @areYouSureDeleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this expense?'**
  String get areYouSureDeleteExpense;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @enterAName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterAName;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter valid amount'**
  String get enterValidAmount;

  /// No description provided for @noExpensesYet.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpensesYet;

  /// No description provided for @tapToAddFirstExpense.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first expense'**
  String get tapToAddFirstExpense;

  /// No description provided for @noSpendingDataYet.
  ///
  /// In en, this message translates to:
  /// **'No spending data yet'**
  String get noSpendingDataYet;

  /// No description provided for @dailySpending.
  ///
  /// In en, this message translates to:
  /// **'Daily Spending'**
  String get dailySpending;

  /// No description provided for @spendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get spendingByCategory;

  /// No description provided for @recentExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recent Expenses'**
  String get recentExpenses;

  /// No description provided for @budgetStatus.
  ///
  /// In en, this message translates to:
  /// **'Budget Status'**
  String get budgetStatus;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @monthlySpending.
  ///
  /// In en, this message translates to:
  /// **'Monthly Spending'**
  String get monthlySpending;

  /// No description provided for @ofBudget.
  ///
  /// In en, this message translates to:
  /// **'of {amount} budget'**
  String ofBudget(String amount);

  /// No description provided for @budgetWarningPercent.
  ///
  /// In en, this message translates to:
  /// **'Budget warning: You have used {percent}% of your monthly budget.'**
  String budgetWarningPercent(int percent);

  /// No description provided for @defaultCategory.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultCategory;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @catLight.
  ///
  /// In en, this message translates to:
  /// **'Cat Light 🐱'**
  String get catLight;

  /// No description provided for @catDark.
  ///
  /// In en, this message translates to:
  /// **'Cat Dark 🐱'**
  String get catDark;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by Justin'**
  String get developedBy;

  /// No description provided for @approachingMonthlyLimit.
  ///
  /// In en, this message translates to:
  /// **'Approaching monthly limit'**
  String get approachingMonthlyLimit;

  /// No description provided for @monthlyBudgetExceeded.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget exceeded!'**
  String get monthlyBudgetExceeded;

  /// No description provided for @approachingCategoryBudget.
  ///
  /// In en, this message translates to:
  /// **'Approaching {category} limit'**
  String approachingCategoryBudget(String category);

  /// No description provided for @categoryBudgetExceededMsg.
  ///
  /// In en, this message translates to:
  /// **'{category} budget exceeded!'**
  String categoryBudgetExceededMsg(String category);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @limit.
  ///
  /// In en, this message translates to:
  /// **'limit'**
  String get limit;

  /// No description provided for @searchExpenses.
  ///
  /// In en, this message translates to:
  /// **'Search expenses'**
  String get searchExpenses;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @amountRange.
  ///
  /// In en, this message translates to:
  /// **'Amount range'**
  String get amountRange;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFilters;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get tryAdjustingFilters;

  /// No description provided for @savingGoals.
  ///
  /// In en, this message translates to:
  /// **'Saving Goals'**
  String get savingGoals;

  /// No description provided for @noSavingGoalsYet.
  ///
  /// In en, this message translates to:
  /// **'No saving goals yet'**
  String get noSavingGoalsYet;

  /// No description provided for @tapToAddFirstGoal.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first goal'**
  String get tapToAddFirstGoal;

  /// No description provided for @editSavingGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Saving Goal'**
  String get editSavingGoal;

  /// No description provided for @addSavingGoal.
  ///
  /// In en, this message translates to:
  /// **'Add Saving Goal'**
  String get addSavingGoal;

  /// No description provided for @goalName.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get goalName;

  /// No description provided for @targetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get targetAmount;

  /// No description provided for @enterTargetAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter target amount'**
  String get enterTargetAmount;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @setDeadline.
  ///
  /// In en, this message translates to:
  /// **'Set deadline'**
  String get setDeadline;

  /// No description provided for @addMoney.
  ///
  /// In en, this message translates to:
  /// **'Add money'**
  String get addMoney;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{n} days remaining'**
  String daysRemaining(int n);

  /// No description provided for @deadlinePassed.
  ///
  /// In en, this message translates to:
  /// **'Deadline passed'**
  String get deadlinePassed;

  /// No description provided for @cannotWithdrawMoreThanCurrent.
  ///
  /// In en, this message translates to:
  /// **'Cannot withdraw more than current amount'**
  String get cannotWithdrawMoreThanCurrent;

  /// No description provided for @goalCompleted.
  ///
  /// In en, this message translates to:
  /// **'Goal completed!'**
  String get goalCompleted;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @exportingData.
  ///
  /// In en, this message translates to:
  /// **'Exporting data...'**
  String get exportingData;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully!'**
  String get exportSuccess;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Failed to export backup'**
  String get exportError;

  /// No description provided for @recurringExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recurring Expenses'**
  String get recurringExpenses;

  /// No description provided for @noRecurringExpensesYet.
  ///
  /// In en, this message translates to:
  /// **'No recurring expenses yet'**
  String get noRecurringExpensesYet;

  /// No description provided for @tapToAddFirstRecurring.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first recurring expense'**
  String get tapToAddFirstRecurring;

  /// No description provided for @addRecurringExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Recurring Expense'**
  String get addRecurringExpense;

  /// No description provided for @editRecurringExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Recurring Expense'**
  String get editRecurringExpense;

  /// No description provided for @dayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get dayOfMonth;

  /// No description provided for @everyMonthOn.
  ///
  /// In en, this message translates to:
  /// **'Every month on day {day}'**
  String everyMonthOn(int day);

  /// No description provided for @recurringAdded.
  ///
  /// In en, this message translates to:
  /// **'Recurring expense added for this month'**
  String get recurringAdded;

  /// No description provided for @monthlySummary.
  ///
  /// In en, this message translates to:
  /// **'Monthly Summary'**
  String get monthlySummary;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week {n}'**
  String week(int n);

  /// No description provided for @vsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'vs last month'**
  String get vsLastMonth;

  /// No description provided for @topCategories.
  ///
  /// In en, this message translates to:
  /// **'Top Categories'**
  String get topCategories;

  /// No description provided for @budgetSummary.
  ///
  /// In en, this message translates to:
  /// **'Budget Summary'**
  String get budgetSummary;

  /// No description provided for @onTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get onTrack;

  /// No description provided for @isOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get isOverBudget;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date (Optional)'**
  String get endDate;

  /// No description provided for @noEndDate.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get noEndDate;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @everyWeek.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get everyWeek;

  /// No description provided for @everyMonth.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get everyMonth;

  /// No description provided for @everyYear.
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get everyYear;

  /// No description provided for @recurringExpenseCreated.
  ///
  /// In en, this message translates to:
  /// **'Recurring expense created'**
  String get recurringExpenseCreated;

  /// No description provided for @deleteRecurringExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete Recurring Expense'**
  String get deleteRecurringExpense;

  /// No description provided for @areYouSureDeleteRecurring.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this recurring expense?'**
  String get areYouSureDeleteRecurring;

  /// No description provided for @currencyConverter.
  ///
  /// In en, this message translates to:
  /// **'Currency Converter'**
  String get currencyConverter;

  /// No description provided for @exchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate'**
  String get exchangeRate;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// No description provided for @quickAmounts.
  ///
  /// In en, this message translates to:
  /// **'Quick Amounts'**
  String get quickAmounts;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'min ago'**
  String get minutesAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'hr ago'**
  String get hoursAgo;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get daysAgo;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @linkEmail.
  ///
  /// In en, this message translates to:
  /// **'Link Email Account'**
  String get linkEmail;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Backup Now'**
  String get backupNow;

  /// No description provided for @autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get autoBackup;

  /// No description provided for @restoreFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Restore from Cloud'**
  String get restoreFromCloud;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will replace all your current data. Are you sure?'**
  String get restoreConfirm;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully!'**
  String get restoreSuccess;

  /// No description provided for @restoreError.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore'**
  String get restoreError;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup completed successfully!'**
  String get backupSuccess;

  /// No description provided for @backupError.
  ///
  /// In en, this message translates to:
  /// **'Failed to backup'**
  String get backupError;

  /// No description provided for @syncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync successful!'**
  String get syncSuccess;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync error'**
  String get syncError;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @unlinkGoogle.
  ///
  /// In en, this message translates to:
  /// **'Unlink Google Account'**
  String get unlinkGoogle;

  /// No description provided for @unlinkGoogleConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will disconnect your Google account. Cloud backups will no longer be accessible. Are you sure?'**
  String get unlinkGoogleConfirm;

  /// No description provided for @unlinkSuccess.
  ///
  /// In en, this message translates to:
  /// **'Google account unlinked successfully'**
  String get unlinkSuccess;

  /// No description provided for @unlinkError.
  ///
  /// In en, this message translates to:
  /// **'Failed to unlink account'**
  String get unlinkError;

  /// No description provided for @googleSignInError.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed'**
  String get googleSignInError;

  /// No description provided for @localData.
  ///
  /// In en, this message translates to:
  /// **'Local Data'**
  String get localData;

  /// No description provided for @cloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup'**
  String get cloudBackup;

  /// No description provided for @backedUpOn.
  ///
  /// In en, this message translates to:
  /// **'Backed up on {date}'**
  String backedUpOn(Object date);

  /// No description provided for @noBackupFound.
  ///
  /// In en, this message translates to:
  /// **'No cloud backup found'**
  String get noBackupFound;

  /// No description provided for @restoreCompareMessage.
  ///
  /// In en, this message translates to:
  /// **'Compare your local data with the cloud backup before restoring:'**
  String get restoreCompareMessage;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get addIncome;

  /// No description provided for @editIncome.
  ///
  /// In en, this message translates to:
  /// **'Edit Income'**
  String get editIncome;

  /// No description provided for @deleteIncome.
  ///
  /// In en, this message translates to:
  /// **'Delete Income'**
  String get deleteIncome;

  /// No description provided for @areYouSureDeleteIncome.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this income?'**
  String get areYouSureDeleteIncome;

  /// No description provided for @noIncomeYet.
  ///
  /// In en, this message translates to:
  /// **'No income yet'**
  String get noIncomeYet;

  /// No description provided for @tapToAddFirstIncome.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first income'**
  String get tapToAddFirstIncome;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @selectSource.
  ///
  /// In en, this message translates to:
  /// **'Select Source'**
  String get selectSource;

  /// No description provided for @incomeSource.
  ///
  /// In en, this message translates to:
  /// **'Income source'**
  String get incomeSource;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @freelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get freelance;

  /// No description provided for @investment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get investment;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// No description provided for @rental.
  ///
  /// In en, this message translates to:
  /// **'Rental'**
  String get rental;

  /// No description provided for @gift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get gift;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @otherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherIncome;

  /// No description provided for @incomeVsExpenses.
  ///
  /// In en, this message translates to:
  /// **'Income vs Expenses'**
  String get incomeVsExpenses;

  /// No description provided for @monthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly Income'**
  String get monthlyIncome;

  /// No description provided for @monthlyBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get monthlyBalance;

  /// No description provided for @recentIncomes.
  ///
  /// In en, this message translates to:
  /// **'Recent Income'**
  String get recentIncomes;

  /// No description provided for @surplus.
  ///
  /// In en, this message translates to:
  /// **'Surplus'**
  String get surplus;

  /// No description provided for @deficit.
  ///
  /// In en, this message translates to:
  /// **'Deficit'**
  String get deficit;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @expenseCategories.
  ///
  /// In en, this message translates to:
  /// **'Add Expense Category'**
  String get expenseCategories;

  /// No description provided for @incomeCategories.
  ///
  /// In en, this message translates to:
  /// **'Add Income Category'**
  String get incomeCategories;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get dailyReminder;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @reminderEveryDayAt.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String reminderEveryDayAt(String time);

  /// No description provided for @reminderDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get reminderDisabled;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// No description provided for @appLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require biometric authentication to open the app'**
  String get appLockSubtitle;

  /// No description provided for @appLocked.
  ///
  /// In en, this message translates to:
  /// **'App Locked'**
  String get appLocked;

  /// No description provided for @authenticateToContinue.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to continue'**
  String get authenticateToContinue;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @biometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock SpendSmart'**
  String get biometricReason;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not available on this device'**
  String get biometricNotAvailable;

  /// No description provided for @biometricSetupSuccess.
  ///
  /// In en, this message translates to:
  /// **'App lock enabled successfully'**
  String get biometricSetupSuccess;

  /// No description provided for @biometricSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to enable app lock'**
  String get biometricSetupFailed;

  /// No description provided for @wallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get wallets;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @addWallet.
  ///
  /// In en, this message translates to:
  /// **'Add Wallet'**
  String get addWallet;

  /// No description provided for @editWallet.
  ///
  /// In en, this message translates to:
  /// **'Edit Wallet'**
  String get editWallet;

  /// No description provided for @walletName.
  ///
  /// In en, this message translates to:
  /// **'Wallet Name'**
  String get walletName;

  /// No description provided for @enterWalletName.
  ///
  /// In en, this message translates to:
  /// **'Enter wallet name'**
  String get enterWalletName;

  /// No description provided for @walletType.
  ///
  /// In en, this message translates to:
  /// **'Wallet Type'**
  String get walletType;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @bankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get bankAccount;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get creditCard;

  /// No description provided for @eWallet.
  ///
  /// In en, this message translates to:
  /// **'E-Wallet'**
  String get eWallet;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// No description provided for @myWallets.
  ///
  /// In en, this message translates to:
  /// **'My Wallets'**
  String get myWallets;

  /// No description provided for @noWalletsYet.
  ///
  /// In en, this message translates to:
  /// **'No wallets yet'**
  String get noWalletsYet;

  /// No description provided for @tapToAddFirstWallet.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first wallet'**
  String get tapToAddFirstWallet;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as Default'**
  String get setAsDefault;

  /// No description provided for @deleteWallet.
  ///
  /// In en, this message translates to:
  /// **'Delete Wallet'**
  String get deleteWallet;

  /// No description provided for @areYouSureDeleteWallet.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this wallet?'**
  String get areYouSureDeleteWallet;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @editTransfer.
  ///
  /// In en, this message translates to:
  /// **'Edit Transfer'**
  String get editTransfer;

  /// No description provided for @deleteTransfer.
  ///
  /// In en, this message translates to:
  /// **'Delete Transfer'**
  String get deleteTransfer;

  /// No description provided for @areYouSureDeleteTransfer.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transfer?'**
  String get areYouSureDeleteTransfer;

  /// No description provided for @transferBetweenWallets.
  ///
  /// In en, this message translates to:
  /// **'Transfer Between Wallets'**
  String get transferBetweenWallets;

  /// No description provided for @fromWallet.
  ///
  /// In en, this message translates to:
  /// **'From Wallet'**
  String get fromWallet;

  /// No description provided for @toWallet.
  ///
  /// In en, this message translates to:
  /// **'To Wallet'**
  String get toWallet;

  /// No description provided for @recentTransfers.
  ///
  /// In en, this message translates to:
  /// **'Recent Transfers'**
  String get recentTransfers;

  /// No description provided for @selectWallet.
  ///
  /// In en, this message translates to:
  /// **'Select Wallet'**
  String get selectWallet;

  /// No description provided for @noWallet.
  ///
  /// In en, this message translates to:
  /// **'No Wallet'**
  String get noWallet;

  /// No description provided for @walletNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Wallet name is required'**
  String get walletNameRequired;

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance in the selected wallet'**
  String get insufficientBalance;

  /// No description provided for @showStreakBanner.
  ///
  /// In en, this message translates to:
  /// **'Show daily streak'**
  String get showStreakBanner;

  /// No description provided for @showStreakBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display streak banner on dashboard'**
  String get showStreakBannerSubtitle;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @expenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get expenseDeleted;

  /// No description provided for @incomeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Income deleted'**
  String get incomeDeleted;

  /// No description provided for @walletDeleted.
  ///
  /// In en, this message translates to:
  /// **'Wallet deleted'**
  String get walletDeleted;

  /// No description provided for @transferDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transfer deleted'**
  String get transferDeleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @installUpdate.
  ///
  /// In en, this message translates to:
  /// **'Install Update'**
  String get installUpdate;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @downloadingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Downloading update…'**
  String get downloadingUpdate;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkForUpdates;

  /// No description provided for @currentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current Version'**
  String get currentVersion;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get upToDate;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'New version {version} is available'**
  String newVersionAvailable(String version);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
