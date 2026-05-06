// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Expense Tracker';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get expenses => 'Expenses';

  @override
  String get categories => 'Categories';

  @override
  String get settings => 'Settings';

  @override
  String get budgetSettings => 'Budget Settings';

  @override
  String get monthly => 'Monthly';

  @override
  String get category => 'Category';

  @override
  String get overall => 'Overall';

  @override
  String get setBudget => 'Set Budget';

  @override
  String get updateBudget => 'Update Budget';

  @override
  String get removeBudget => 'Remove Budget';

  @override
  String get noBudget => 'No Budget';

  @override
  String get trackWithoutLimit => 'Track without limit';

  @override
  String get monthlyBudget => 'Monthly Budget';

  @override
  String get setTotalLimit => 'Set a total spending limit for the month';

  @override
  String get budgetAmount => 'Budget Amount';

  @override
  String get youWillReceiveAlerts =>
      'You\'ll receive alerts at 80% and 100% of your budget';

  @override
  String get budgetExceeded => 'Budget exceeded!';

  @override
  String get approachingLimit => 'Approaching budget limit';

  @override
  String get categoryBudgetExceeded => 'Category budget exceeded!';

  @override
  String get approachingCategoryLimit => 'Approaching category limit';

  @override
  String get remaining => 'remaining';

  @override
  String get overBudget => 'Over budget!';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get editExpense => 'Edit Expense';

  @override
  String get amount => 'Amount';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get date => 'Date';

  @override
  String get note => 'Note';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get addANote => 'Add a note...';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteExpense => 'Delete Expense';

  @override
  String get areYouSureDeleteExpense =>
      'Are you sure you want to delete this expense?';

  @override
  String get addCategory => 'Add Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get name => 'Name';

  @override
  String get categoryName => 'Category name';

  @override
  String get enterAName => 'Enter a name';

  @override
  String get icon => 'Icon';

  @override
  String get color => 'Color';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get enterValidAmount => 'Enter valid amount';

  @override
  String get noExpensesYet => 'No expenses yet';

  @override
  String get tapToAddFirstExpense => 'Tap + to add your first expense';

  @override
  String get noSpendingDataYet => 'No spending data yet';

  @override
  String get dailySpending => 'Daily Spending';

  @override
  String get spendingByCategory => 'Spending by Category';

  @override
  String get recentExpenses => 'Recent Expenses';

  @override
  String get budgetStatus => 'Budget Status';

  @override
  String get max => 'Max';

  @override
  String get allCategories => 'All Categories';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get chinese => 'Chinese';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get monthlySpending => 'Monthly Spending';

  @override
  String ofBudget(String amount) {
    return 'of $amount budget';
  }

  @override
  String budgetWarningPercent(int percent) {
    return 'Budget warning: You have used $percent% of your monthly budget.';
  }

  @override
  String get defaultCategory => 'Default';

  @override
  String get currency => 'Currency';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get catLight => 'Cat Light 🐱';

  @override
  String get catDark => 'Cat Dark 🐱';

  @override
  String get about => 'About';

  @override
  String get developedBy => 'Developed by Justin';

  @override
  String get approachingMonthlyLimit => 'Approaching monthly limit';

  @override
  String get monthlyBudgetExceeded => 'Monthly budget exceeded!';

  @override
  String approachingCategoryBudget(String category) {
    return 'Approaching $category limit';
  }

  @override
  String categoryBudgetExceededMsg(String category) {
    return '$category budget exceeded!';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String get limit => 'limit';

  @override
  String get searchExpenses => 'Search expenses';

  @override
  String get filters => 'Filters';

  @override
  String get clearAll => 'Clear all';

  @override
  String get amountRange => 'Amount range';

  @override
  String get min => 'Min';

  @override
  String get dateRange => 'Date range';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get applyFilters => 'Apply filters';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get tryAdjustingFilters => 'Try adjusting your filters';

  @override
  String get savingGoals => 'Saving Goals';

  @override
  String get noSavingGoalsYet => 'No saving goals yet';

  @override
  String get tapToAddFirstGoal => 'Tap + to add your first goal';

  @override
  String get editSavingGoal => 'Edit Saving Goal';

  @override
  String get addSavingGoal => 'Add Saving Goal';

  @override
  String get goalName => 'Goal name';

  @override
  String get targetAmount => 'Target amount';

  @override
  String get enterTargetAmount => 'Enter target amount';

  @override
  String get deadline => 'Deadline';

  @override
  String get setDeadline => 'Set deadline';

  @override
  String get addMoney => 'Add money';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get completed => 'Completed';

  @override
  String daysRemaining(int n) {
    return '$n days remaining';
  }

  @override
  String get deadlinePassed => 'Deadline passed';

  @override
  String get cannotWithdrawMoreThanCurrent =>
      'Cannot withdraw more than current amount';

  @override
  String get goalCompleted => 'Goal completed!';

  @override
  String get backup => 'Backup';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportingData => 'Exporting data...';

  @override
  String get exportSuccess => 'Backup exported successfully!';

  @override
  String get exportError => 'Failed to export backup';

  @override
  String get recurringExpenses => 'Recurring Expenses';

  @override
  String get noRecurringExpensesYet => 'No recurring expenses yet';

  @override
  String get tapToAddFirstRecurring =>
      'Tap + to add your first recurring expense';

  @override
  String get addRecurringExpense => 'Add Recurring Expense';

  @override
  String get editRecurringExpense => 'Edit Recurring Expense';

  @override
  String get dayOfMonth => 'Day of month';

  @override
  String everyMonthOn(int day) {
    return 'Every month on day $day';
  }

  @override
  String get recurringAdded => 'Recurring expense added for this month';

  @override
  String get monthlySummary => 'Monthly Summary';

  @override
  String week(int n) {
    return 'Week $n';
  }

  @override
  String get vsLastMonth => 'vs last month';

  @override
  String get topCategories => 'Top Categories';

  @override
  String get budgetSummary => 'Budget Summary';

  @override
  String get onTrack => 'On track';

  @override
  String get isOverBudget => 'Over budget';

  @override
  String get frequency => 'Frequency';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get yearly => 'Yearly';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date (Optional)';

  @override
  String get noEndDate => 'No end date';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get everyDay => 'Every day';

  @override
  String get everyWeek => 'Every week';

  @override
  String get everyMonth => 'Every month';

  @override
  String get everyYear => 'Every year';

  @override
  String get recurringExpenseCreated => 'Recurring expense created';

  @override
  String get deleteRecurringExpense => 'Delete Recurring Expense';

  @override
  String get areYouSureDeleteRecurring =>
      'Are you sure you want to delete this recurring expense?';

  @override
  String get currencyConverter => 'Currency Converter';

  @override
  String get exchangeRate => 'Exchange Rate';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get quickAmounts => 'Quick Amounts';

  @override
  String get minutesAgo => 'min ago';

  @override
  String get hoursAgo => 'hr ago';

  @override
  String get daysAgo => 'days ago';

  @override
  String get account => 'Account';

  @override
  String get linkEmail => 'Link Email Account';

  @override
  String get email => 'Email';

  @override
  String get send => 'Send';

  @override
  String get preferences => 'Preferences';

  @override
  String get backupNow => 'Backup Now';

  @override
  String get autoBackup => 'Auto Backup';

  @override
  String get restoreFromCloud => 'Restore from Cloud';

  @override
  String get restore => 'Restore';

  @override
  String get restoreConfirm =>
      'This will replace all your current data. Are you sure?';

  @override
  String get restoreSuccess => 'Data restored successfully!';

  @override
  String get restoreError => 'Failed to restore';

  @override
  String get backupSuccess => 'Backup completed successfully!';

  @override
  String get backupError => 'Failed to backup';

  @override
  String get syncSuccess => 'Cloud sync successful!';

  @override
  String get syncError => 'Sync error';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get unlinkGoogle => 'Unlink Google Account';

  @override
  String get unlinkGoogleConfirm =>
      'This will disconnect your Google account. Cloud backups will no longer be accessible. Are you sure?';

  @override
  String get unlinkSuccess => 'Google account unlinked successfully';

  @override
  String get unlinkError => 'Failed to unlink account';

  @override
  String get googleSignInError => 'Google sign-in failed';

  @override
  String get localData => 'Local Data';

  @override
  String get cloudBackup => 'Cloud Backup';

  @override
  String backedUpOn(Object date) {
    return 'Backed up on $date';
  }

  @override
  String get noBackupFound => 'No cloud backup found';

  @override
  String get restoreCompareMessage =>
      'Compare your local data with the cloud backup before restoring:';

  @override
  String get income => 'Income';

  @override
  String get addIncome => 'Add Income';

  @override
  String get editIncome => 'Edit Income';

  @override
  String get deleteIncome => 'Delete Income';

  @override
  String get areYouSureDeleteIncome =>
      'Are you sure you want to delete this income?';

  @override
  String get noIncomeYet => 'No income yet';

  @override
  String get tapToAddFirstIncome => 'Tap + to add your first income';

  @override
  String get source => 'Source';

  @override
  String get selectSource => 'Select Source';

  @override
  String get incomeSource => 'Income source';

  @override
  String get salary => 'Salary';

  @override
  String get freelance => 'Freelance';

  @override
  String get investment => 'Investment';

  @override
  String get business => 'Business';

  @override
  String get rental => 'Rental';

  @override
  String get gift => 'Gift';

  @override
  String get refund => 'Refund';

  @override
  String get otherIncome => 'Other';

  @override
  String get incomeVsExpenses => 'Income vs Expenses';

  @override
  String get monthlyIncome => 'Monthly Income';

  @override
  String get monthlyBalance => 'Balance';

  @override
  String get recentIncomes => 'Recent Income';

  @override
  String get surplus => 'Surplus';

  @override
  String get deficit => 'Deficit';

  @override
  String get transactions => 'Transactions';

  @override
  String get expenseCategories => 'Add Expense Category';

  @override
  String get incomeCategories => 'Add Income Category';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get notifications => 'Notifications';

  @override
  String get dailyReminder => 'Daily Reminder';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String reminderEveryDayAt(String time) {
    return 'Every day at $time';
  }

  @override
  String get reminderDisabled => 'Disabled';

  @override
  String get security => 'Security';

  @override
  String get appLock => 'App Lock';

  @override
  String get appLockSubtitle =>
      'Require biometric authentication to open the app';

  @override
  String get appLocked => 'App Locked';

  @override
  String get authenticateToContinue => 'Authenticate to continue';

  @override
  String get unlock => 'Unlock';

  @override
  String get biometricReason => 'Unlock SpendSmart';

  @override
  String get biometricNotAvailable =>
      'Biometric authentication is not available on this device';

  @override
  String get biometricSetupSuccess => 'App lock enabled successfully';

  @override
  String get biometricSetupFailed => 'Failed to enable app lock';

  @override
  String get wallets => 'Wallets';

  @override
  String get wallet => 'Wallet';

  @override
  String get addWallet => 'Add Wallet';

  @override
  String get editWallet => 'Edit Wallet';

  @override
  String get walletName => 'Wallet Name';

  @override
  String get enterWalletName => 'Enter wallet name';

  @override
  String get walletType => 'Wallet Type';

  @override
  String get cash => 'Cash';

  @override
  String get bankAccount => 'Bank Account';

  @override
  String get creditCard => 'Credit Card';

  @override
  String get eWallet => 'E-Wallet';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get myWallets => 'My Wallets';

  @override
  String get noWalletsYet => 'No wallets yet';

  @override
  String get tapToAddFirstWallet => 'Tap + to add your first wallet';

  @override
  String get balance => 'Balance';

  @override
  String get defaultLabel => 'Default';

  @override
  String get setAsDefault => 'Set as Default';

  @override
  String get deleteWallet => 'Delete Wallet';

  @override
  String get areYouSureDeleteWallet =>
      'Are you sure you want to delete this wallet?';

  @override
  String get transfer => 'Transfer';

  @override
  String get editTransfer => 'Edit Transfer';

  @override
  String get deleteTransfer => 'Delete Transfer';

  @override
  String get areYouSureDeleteTransfer =>
      'Are you sure you want to delete this transfer?';

  @override
  String get transferBetweenWallets => 'Transfer Between Wallets';

  @override
  String get fromWallet => 'From Wallet';

  @override
  String get toWallet => 'To Wallet';

  @override
  String get recentTransfers => 'Recent Transfers';

  @override
  String get selectWallet => 'Select Wallet';

  @override
  String get noWallet => 'No Wallet';

  @override
  String get walletNameRequired => 'Wallet name is required';

  @override
  String get insufficientBalance =>
      'Insufficient balance in the selected wallet';

  @override
  String get showStreakBanner => 'Show daily streak';

  @override
  String get showStreakBannerSubtitle => 'Display streak banner on dashboard';

  @override
  String get edit => 'Edit';

  @override
  String get update => 'Update';

  @override
  String get expenseDeleted => 'Expense deleted';

  @override
  String get incomeDeleted => 'Income deleted';

  @override
  String get walletDeleted => 'Wallet deleted';

  @override
  String get transferDeleted => 'Transfer deleted';

  @override
  String get undo => 'Undo';

  @override
  String get updateAvailable => 'Update available';

  @override
  String get installUpdate => 'Install Update';

  @override
  String get updateLater => 'Later';

  @override
  String get downloadingUpdate => 'Downloading update…';

  @override
  String get checkForUpdates => 'Check for Updates';

  @override
  String get currentVersion => 'Current Version';

  @override
  String get upToDate => 'Up to date';

  @override
  String newVersionAvailable(String version) {
    return 'New version $version is available';
  }
}
