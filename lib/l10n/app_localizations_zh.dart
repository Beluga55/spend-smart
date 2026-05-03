// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '支出追踪';

  @override
  String get dashboard => '仪表盘';

  @override
  String get expenses => '支出';

  @override
  String get categories => '分类';

  @override
  String get settings => '设置';

  @override
  String get budgetSettings => '预算设置';

  @override
  String get monthly => '每月';

  @override
  String get category => '分类';

  @override
  String get overall => '总体';

  @override
  String get setBudget => '设置预算';

  @override
  String get updateBudget => '更新预算';

  @override
  String get removeBudget => '删除预算';

  @override
  String get noBudget => '无预算';

  @override
  String get trackWithoutLimit => '无限制追踪';

  @override
  String get monthlyBudget => '月度预算';

  @override
  String get setTotalLimit => '设置月度支出上限';

  @override
  String get budgetAmount => '预算金额';

  @override
  String get youWillReceiveAlerts => '您将在达到预算的80%和100%时收到提醒';

  @override
  String get budgetExceeded => '预算已超支！';

  @override
  String get approachingLimit => '接近预算上限';

  @override
  String get categoryBudgetExceeded => '分类预算已超支！';

  @override
  String get approachingCategoryLimit => '接近分类预算上限';

  @override
  String get remaining => '剩余';

  @override
  String get overBudget => '已超支！';

  @override
  String get addExpense => '添加支出';

  @override
  String get editExpense => '编辑支出';

  @override
  String get amount => '金额';

  @override
  String get selectCategory => '选择分类';

  @override
  String get date => '日期';

  @override
  String get note => '备注';

  @override
  String get noteOptional => '备注（可选）';

  @override
  String get addANote => '添加备注...';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get deleteExpense => '删除支出';

  @override
  String get areYouSureDeleteExpense => '确定要删除此支出吗？';

  @override
  String get addCategory => '添加分类';

  @override
  String get editCategory => '编辑分类';

  @override
  String get name => '名称';

  @override
  String get categoryName => '分类名称';

  @override
  String get enterAName => '请输入名称';

  @override
  String get icon => '图标';

  @override
  String get color => '颜色';

  @override
  String get enterAmount => '请输入金额';

  @override
  String get enterValidAmount => '请输入有效金额';

  @override
  String get noExpensesYet => '暂无支出';

  @override
  String get tapToAddFirstExpense => '点击 + 添加您的第一笔支出';

  @override
  String get noSpendingDataYet => '暂无消费数据';

  @override
  String get dailySpending => '每日支出';

  @override
  String get spendingByCategory => '分类支出';

  @override
  String get recentExpenses => '最近支出';

  @override
  String get budgetStatus => '预算状态';

  @override
  String get max => '最大';

  @override
  String get allCategories => '所有分类';

  @override
  String get language => '语言';

  @override
  String get english => '英语';

  @override
  String get chinese => '中文';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get monthlySpending => '月度支出';

  @override
  String ofBudget(String amount) {
    return '预算 $amount';
  }

  @override
  String budgetWarningPercent(int percent) {
    return '预算提醒：您已使用本月预算的$percent%';
  }

  @override
  String get defaultCategory => '默认';

  @override
  String get currency => '货币';

  @override
  String get theme => '主题';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get catLight => '猫咪浅色 🐱';

  @override
  String get catDark => '猫咪深色 🐱';

  @override
  String get about => '关于';

  @override
  String get developedBy => '开发者：Justin';

  @override
  String get approachingMonthlyLimit => '接近月度上限';

  @override
  String get monthlyBudgetExceeded => '月度预算已超支！';

  @override
  String approachingCategoryBudget(String category) {
    return '接近$category上限';
  }

  @override
  String categoryBudgetExceededMsg(String category) {
    return '$category预算已超支！';
  }

  @override
  String get unknown => '未知';

  @override
  String get limit => '上限';

  @override
  String get searchExpenses => '搜索支出';

  @override
  String get filters => '筛选';

  @override
  String get clearAll => '清除全部';

  @override
  String get amountRange => '金额范围';

  @override
  String get min => '最小';

  @override
  String get dateRange => '日期范围';

  @override
  String get from => '从';

  @override
  String get to => '到';

  @override
  String get applyFilters => '应用筛选';

  @override
  String get noResultsFound => '未找到结果';

  @override
  String get tryAdjustingFilters => '尝试调整筛选条件';

  @override
  String get savingGoals => '储蓄目标';

  @override
  String get noSavingGoalsYet => '暂无储蓄目标';

  @override
  String get tapToAddFirstGoal => '点击 + 添加您的第一个目标';

  @override
  String get editSavingGoal => '编辑储蓄目标';

  @override
  String get addSavingGoal => '添加储蓄目标';

  @override
  String get goalName => '目标名称';

  @override
  String get targetAmount => '目标金额';

  @override
  String get enterTargetAmount => '输入目标金额';

  @override
  String get deadline => '截止日期';

  @override
  String get setDeadline => '设置截止日期';

  @override
  String get addMoney => '存入';

  @override
  String get withdraw => '取出';

  @override
  String get completed => '已完成';

  @override
  String daysRemaining(int n) {
    return '还剩$n天';
  }

  @override
  String get deadlinePassed => '已过截止日期';

  @override
  String get cannotWithdrawMoreThanCurrent => '取出金额不能超过当前金额';

  @override
  String get goalCompleted => '目标已完成！';

  @override
  String get backup => '备份';

  @override
  String get exportData => '导出数据';

  @override
  String get exportingData => '正在导出数据...';

  @override
  String get exportSuccess => '备份导出成功！';

  @override
  String get exportError => '备份导出失败';

  @override
  String get recurringExpenses => '定期支出';

  @override
  String get noRecurringExpensesYet => '暂无定期支出';

  @override
  String get tapToAddFirstRecurring => '点击 + 添加您的第一个定期支出';

  @override
  String get addRecurringExpense => '添加定期支出';

  @override
  String get editRecurringExpense => '编辑定期支出';

  @override
  String get dayOfMonth => '每月几号';

  @override
  String everyMonthOn(int day) {
    return '每月$day号';
  }

  @override
  String get recurringAdded => '已为此月添加定期支出';

  @override
  String get monthlySummary => '月度总结';

  @override
  String week(int n) {
    return '第$n周';
  }

  @override
  String get vsLastMonth => '与上月相比';

  @override
  String get topCategories => '主要分类';

  @override
  String get budgetSummary => '预算摘要';

  @override
  String get onTrack => '正常';

  @override
  String get isOverBudget => '超支';

  @override
  String get frequency => '频率';

  @override
  String get daily => '每天';

  @override
  String get weekly => '每周';

  @override
  String get yearly => '每年';

  @override
  String get startDate => '开始日期';

  @override
  String get endDate => '结束日期（可选）';

  @override
  String get noEndDate => '无结束日期';

  @override
  String get active => '启用';

  @override
  String get inactive => '停用';

  @override
  String get everyDay => '每天';

  @override
  String get everyWeek => '每周';

  @override
  String get everyMonth => '每月';

  @override
  String get everyYear => '每年';

  @override
  String get recurringExpenseCreated => '已创建定期支出';

  @override
  String get deleteRecurringExpense => '删除定期支出';

  @override
  String get areYouSureDeleteRecurring => '确定要删除此定期支出吗？';

  @override
  String get currencyConverter => '货币转换器';

  @override
  String get exchangeRate => '汇率';

  @override
  String get lastUpdated => '最后更新';

  @override
  String get quickAmounts => '快捷金额';

  @override
  String get minutesAgo => '分钟前';

  @override
  String get hoursAgo => '小时前';

  @override
  String get daysAgo => '天前';

  @override
  String get account => '账户';

  @override
  String get linkEmail => '绑定邮箱账户';

  @override
  String get email => '邮箱';

  @override
  String get send => '发送';

  @override
  String get preferences => '偏好设置';

  @override
  String get backupNow => '立即备份';

  @override
  String get autoBackup => '自动备份';

  @override
  String get restoreFromCloud => '从云端恢复';

  @override
  String get restore => '恢复';

  @override
  String get restoreConfirm => '这将替换您当前的所有数据。确定吗？';

  @override
  String get restoreSuccess => '数据恢复成功！';

  @override
  String get restoreError => '恢复失败';

  @override
  String get backupSuccess => '备份成功！';

  @override
  String get backupError => '备份失败';

  @override
  String get syncSuccess => '云同步成功！';

  @override
  String get syncError => '同步错误';

  @override
  String get signInWithGoogle => '使用 Google 登录';

  @override
  String get unlinkGoogle => '解绑 Google 账户';

  @override
  String get unlinkGoogleConfirm => '这将断开您的 Google 账户连接。云备份将无法访问。确定吗？';

  @override
  String get unlinkSuccess => 'Google 账户已成功解绑';

  @override
  String get unlinkError => '解绑账户失败';

  @override
  String get googleSignInError => 'Google 登录失败';

  @override
  String get localData => '本地数据';

  @override
  String get cloudBackup => '云端备份';

  @override
  String backedUpOn(Object date) {
    return '备份于 $date';
  }

  @override
  String get noBackupFound => '未找到云端备份';

  @override
  String get restoreCompareMessage => '恢复前请对比本地数据与云端备份：';

  @override
  String get income => '收入';

  @override
  String get addIncome => '添加收入';

  @override
  String get editIncome => '编辑收入';

  @override
  String get deleteIncome => '删除收入';

  @override
  String get areYouSureDeleteIncome => '确定要删除此收入吗？';

  @override
  String get noIncomeYet => '暂无收入';

  @override
  String get tapToAddFirstIncome => '点击 + 添加您的第一笔收入';

  @override
  String get source => '来源';

  @override
  String get selectSource => '选择来源';

  @override
  String get incomeSource => '收入来源';

  @override
  String get salary => '工资';

  @override
  String get freelance => '自由职业';

  @override
  String get investment => '投资';

  @override
  String get business => '经营';

  @override
  String get rental => '租金';

  @override
  String get gift => '礼金';

  @override
  String get refund => '退款';

  @override
  String get otherIncome => '其他';

  @override
  String get incomeVsExpenses => '收入与支出';

  @override
  String get monthlyIncome => '月度收入';

  @override
  String get monthlyBalance => '结余';

  @override
  String get recentIncomes => '最近收入';

  @override
  String get surplus => '盈余';

  @override
  String get deficit => '赤字';

  @override
  String get transactions => '交易记录';

  @override
  String get expenseCategories => '添加支出分类';

  @override
  String get incomeCategories => '添加收入分类';

  @override
  String get recentTransactions => '最近交易';

  @override
  String get notifications => '通知';

  @override
  String get dailyReminder => '每日提醒';

  @override
  String get reminderTime => '提醒时间';

  @override
  String reminderEveryDayAt(String time) {
    return '每天 $time';
  }

  @override
  String get reminderDisabled => '已禁用';

  @override
  String get security => '安全';

  @override
  String get appLock => '应用锁';

  @override
  String get appLockSubtitle => '打开应用时需要生物识别认证';

  @override
  String get appLocked => '应用已锁定';

  @override
  String get authenticateToContinue => '请验证身份以继续';

  @override
  String get unlock => '解锁';

  @override
  String get biometricReason => '解锁 SpendSmart';

  @override
  String get biometricNotAvailable => '此设备不支持生物识别认证';

  @override
  String get biometricSetupSuccess => '应用锁已成功启用';

  @override
  String get biometricSetupFailed => '启用应用锁失败';

  @override
  String get wallets => '钱包';

  @override
  String get wallet => '钱包';

  @override
  String get addWallet => '添加钱包';

  @override
  String get editWallet => '编辑钱包';

  @override
  String get walletName => '钱包名称';

  @override
  String get enterWalletName => '输入钱包名称';

  @override
  String get walletType => '钱包类型';

  @override
  String get cash => '现金';

  @override
  String get bankAccount => '银行账户';

  @override
  String get creditCard => '信用卡';

  @override
  String get eWallet => '电子钱包';

  @override
  String get totalBalance => '总余额';

  @override
  String get myWallets => '我的钱包';

  @override
  String get noWalletsYet => '暂无钱包';

  @override
  String get tapToAddFirstWallet => '点击 + 添加您的第一个钱包';

  @override
  String get balance => '余额';

  @override
  String get defaultLabel => '默认';

  @override
  String get setAsDefault => '设为默认';

  @override
  String get deleteWallet => '删除钱包';

  @override
  String get areYouSureDeleteWallet => '确定要删除此钱包吗？';

  @override
  String get transfer => '转账';

  @override
  String get editTransfer => '编辑转账';

  @override
  String get deleteTransfer => '删除转账';

  @override
  String get areYouSureDeleteTransfer => '确定要删除此转账吗？';

  @override
  String get transferBetweenWallets => '钱包间转账';

  @override
  String get fromWallet => '转出钱包';

  @override
  String get toWallet => '转入钱包';

  @override
  String get recentTransfers => '最近转账';

  @override
  String get selectWallet => '选择钱包';

  @override
  String get noWallet => '无钱包';

  @override
  String get walletNameRequired => '钱包名称不能为空';

  @override
  String get insufficientBalance => '所选钱包余额不足';

  @override
  String get edit => '编辑';

  @override
  String get update => '更新';
}
