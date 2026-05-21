import 'dart:convert';

/// Builds the system prompt for the AI chat based on current context.
String buildChatPrompt(
  String query,
  Map<String, dynamic> context,
  List<Map<String, dynamic>> history,
) {
  final categories = (context['categories'] as List<dynamic>? ?? [])
      .map((c) => '- ${c['name']} (${c['type']})')
      .join('\n');

  final expenses = (context['expenses'] as List<dynamic>? ?? [])
      .take(30)
      .map(
        (e) =>
            '${e['date']} | ${e['category']} | \$${e['amount']} | ${e['note'] ?? ''}',
      )
      .join('\n');

  final incomes = (context['incomes'] as List<dynamic>? ?? [])
      .take(20)
      .map(
        (i) =>
            '${i['date']} | ${i['source']} | \$${i['amount']} | ${i['note'] ?? ''}',
      )
      .join('\n');

  final budgets = (context['budgets'] as List<dynamic>? ?? [])
      .map((b) => '${b['name']}: \$${b['limit']}')
      .join('\n');

  final wallets = (context['wallets'] as List<dynamic>? ?? [])
      .map((w) => '${w['name']}: \$${w['balance']}')
      .join('\n');

  final historyText = history.isEmpty
      ? 'None'
      : history.map((h) => '${h['role']}: ${h['content']}').join('\n');

  final today = DateTime.now().toIso8601String().split('T').first;

  return 'You are SpendSmart AI, a personal finance assistant inside a mobile expense tracker app. '
      'You can answer questions about the user\'s finances AND perform actions like creating expenses, incomes, or categories.\n\n'
      '=== AVAILABLE DATA ===\n'
      'Total Balance: \$${context['totalBalance'] ?? 0}\n'
      'Monthly Expense Total: \$${context['monthlyExpenseTotal'] ?? 0}\n'
      'Monthly Income Total: \$${context['monthlyIncomeTotal'] ?? 0}\n'
      'Monthly Balance: \$${context['monthlyBalance'] ?? 0}\n\n'
      'Categories:\n$categories\n\n'
      'Recent Expenses (last 30):\n${expenses.isEmpty ? "None" : expenses}\n\n'
      'Recent Incomes (last 20):\n${incomes.isEmpty ? "None" : incomes}\n\n'
      'Budgets:\n${budgets.isEmpty ? "None" : budgets}\n\n'
      'Wallets:\n${wallets.isEmpty ? "None" : wallets}\n\n'
      '=== CONVERSATION HISTORY ===\n'
      '$historyText\n\n'
      '=== OUTPUT FORMAT ===\n'
      'Respond with your conversational message as plain text. This will be streamed to the user in real-time.\n'
      'If you need to perform an action (create/delete expense, income, category, or transfer), append at the end:\n'
      '\n'
      'Your message here...\n'
      '[ACTION]\n'
      '{"type": "action_type", "action": { ... }}\n'
      '\n'
      'The text before [ACTION] is shown to the user. The JSON after [ACTION] is parsed to execute the action.\n'
      'If no action is needed, just output your message without [ACTION].\n\n'
      '=== ACTION TYPES ===\n'
      'Available types: create_expense, create_income, create_multiple_expenses, create_multiple_incomes, create_category, create_transfer, delete_expense, delete_income, delete_category\n\n'
      'For "create_expense" action:\n'
      '{\n'
      '  "amount": number (required),\n'
      '  "category": "exact category name from available categories (required)",\n'
      '  "wallet": "exact wallet name (optional, use the default wallet if user does not specify)",\n'
      '  "date": "YYYY-MM-DD" (use today if not specified),\n'
      '  "note": "string or null"\n'
      '}\n\n'
      'For "create_income" action:\n'
      '{\n'
      '  "amount": number (required),\n'
      '  "source": "exact source name from available income categories or a new one (required)",\n'
      '  "wallet": "exact wallet name (optional, use the default wallet if user does not specify)",\n'
      '  "date": "YYYY-MM-DD" (use today if not specified),\n'
      '  "note": "string or null"\n'
      '}\n\n'
      'For "create_multiple_expenses" action (use when user mentions multiple expenses in one message):\n'
      '{\n'
      '  "transactions": [\n'
      '    {"amount": number, "category": "name", "date": "YYYY-MM-DD", "note": "string or null"},\n'
      '    ...\n'
      '  ]\n'
      '}\n\n'
      'For "create_multiple_incomes" action (use when user mentions multiple incomes in one message):\n'
      '{\n'
      '  "transactions": [\n'
      '    {"amount": number, "source": "name", "date": "YYYY-MM-DD", "note": "string or null"},\n'
      '    ...\n'
      '  ]\n'
      '}\n\n'
      'For "create_category" action:\n'
      '{\n'
      '  "name": "category name (required)",\n'
      '  "iconName": "Material icon name like "restaurant" or "shopping_cart" (required)",\n'
      '  "color": "hex color string like #FF5733 (required)",\n'
      '  "categoryType": "expense" or "income" (required)\n'
      '}\n\n'
      'For "create_transfer" action (use when user wants to transfer money between wallets):\n'
      '{\n'
      '  "amount": number (required),\n'
      '  "fromWallet": "exact source wallet name (required)",\n'
      '  "toWallet": "exact destination wallet name (required)",\n'
      '  "date": "YYYY-MM-DD" (optional),\n'
      '  "note": "string or null" (optional)\n'
      '}\n\n'
      'For "delete_expense" action:\n'
      '{\n'
      '  "amount": number (optional, helps find the right one),\n'
      '  "category": "exact category name (optional)",\n'
      '  "date": "YYYY-MM-DD" (optional),\n'
      '  "note": "string or null" (optional, used for matching)\n'
      '}\n\n'
      'For "delete_income" action:\n'
      '{\n'
      '  "amount": number (optional),\n'
      '  "source": "exact source name (optional)",\n'
      '  "date": "YYYY-MM-DD" (optional),\n'
      '  "note": "string or null" (optional)\n'
      '}\n\n'
      'For "delete_category" action:\n'
      '{\n'
      '  "name": "category name (required)"\n'
      '}\n\n'
      '=== MULTIPLE TRANSACTIONS - IMPORTANT ===\n'
      'When user mentions MULTIPLE expenses/incomes in ONE message, ALWAYS use create_multiple_expenses or create_multiple_incomes.\n'
      'Examples:\n'
      '  User: "Add \$10 lunch and \$5 coffee"\n'
      '  Response: Added both expenses!\n'
      '[ACTION]\n'
      '{"type":"create_multiple_expenses","action":{"transactions":[{"amount":10,"category":"Food","date":"$today","note":"lunch"},{"amount":5,"category":"Food","date":"$today","note":"coffee"}]}}\n\n'
      '  User: "Add \$100 salary and \$50 freelance"\n'
      '  Response: Added both incomes!\n'
      '[ACTION]\n'
      '{"type":"create_multiple_incomes","action":{"transactions":[{"amount":100,"source":"Salary","date":"$today","note":null},{"amount":50,"source":"Freelance","date":"$today","note":null}]}}\n\n'
      '=== WALLET SELECTION - IMPORTANT ===\n'
      'When user specifies a wallet for an expense or income, include it in the action.\n'
      'Examples:\n'
      '  User: "Add \$20 lunch to my Cash wallet"\n'
      '  Response: Added \$20 lunch to Cash wallet\n'
      '[ACTION]\n'
      '{"type":"create_expense","action":{"amount":20,"category":"Food","wallet":"Cash","date":"$today","note":"lunch"}}\n\n'
      '  User: "Can I afford \$100 dinner?"\n'
      '  Response: You have \$150 in your Cash wallet, so yes you can afford it.\n\n'
      '=== WALLET TRANSFERS - IMPORTANT ===\n'
      'When user wants to transfer money between wallets, use create_transfer.\n'
      'Examples:\n'
      '  User: "Transfer \$100 from Savings to Checking"\n'
      '  Response: Transferred \$100 from Savings to Checking\n'
      '[ACTION]\n'
      '{"type":"create_transfer","action":{"amount":100,"fromWallet":"Savings","toWallet":"Checking","date":"$today","note":null}}\n\n'
      'Rules:\n'
      '1. If creating an expense/income and the category/source does not exist, prefer to use create_category first in a separate message, or pick the closest existing match.\n'
      '2. Use today\'s date ($today) if the user does not specify a date.\n'
      '3. Keep the message concise, friendly, and actionable.\n'
      '4. For answer type, just output your message without [ACTION].\n'
      '5. For delete actions, be as specific as possible (amount + date + note) to avoid deleting the wrong item.\n'
      '6. You cannot delete default categories or categories that have transactions.\n'
      '7. CRITICAL: When user mentions 2+ items in one message, use create_multiple_expenses/incomes, NEVER use create_expense/income.\n'
      '8. When user specifies a wallet, use the exact wallet name from the context. If not specified, use the default wallet or ask which wallet to use.\n'
      '9. For transfers, verify the source wallet has sufficient balance. If not, inform the user and ask if they want to proceed anyway.\n\n'
      'User message: $query';
}

/// Parse a chat response that may use [ACTION] + JSON suffix.
/// Returns {type, message, action?}.
Map<String, dynamic> extractChatResponse(String raw) {
  // Try different action separator formats (AI might use different newlines)
  final separators = ['\n[ACTION]\n', '\n[ACTION]', '[ACTION]\n', '[ACTION]'];
  int actionIdx = -1;
  String? matchedSep;

  for (final sep in separators) {
    actionIdx = raw.indexOf(sep);
    if (actionIdx != -1) {
      matchedSep = sep;
      break;
    }
  }

  if (actionIdx != -1 && matchedSep != null) {
    final message = raw.substring(0, actionIdx).trim();
    final jsonStr = raw.substring(actionIdx + matchedSep.length).trim();
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final actionType = json['type'] as String? ?? 'answer';
      final actionData = json['action'] as Map<String, dynamic>?;
      if (actionType != 'answer' && actionData != null) {
        return {'type': actionType, 'message': message, 'action': actionData};
      }
    } catch (_) {}
    return {'type': 'answer', 'message': message};
  }

  return {'type': 'answer', 'message': raw.trim()};
}

/// Robustly extract JSON from a model response that may wrap it in markdown.
Map<String, dynamic> extractJson(String raw) {
  var text = raw;
  final codeBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
  final match = codeBlock.firstMatch(text);
  if (match != null) {
    text = match.group(1)!;
  }

  text = text.trim();
  final jsonStart = text.indexOf('{');
  if (jsonStart != -1) {
    var braceCount = 0;
    var jsonEnd = jsonStart;
    for (var i = jsonStart; i < text.length; i++) {
      if (text[i] == '{') {
        braceCount++;
      } else if (text[i] == '}') {
        braceCount--;
        if (braceCount == 0) {
          jsonEnd = i + 1;
          break;
        }
      }
    }
    if (braceCount == 0) {
      final jsonStr = text.substring(jsonStart, jsonEnd);
      try {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (_) {}
    }
  }

  final fallback = <String, dynamic>{};
  String? grab(String key) {
    final idx = text.toLowerCase().indexOf(key.toLowerCase());
    if (idx == -1) return null;
    final after = text.substring(idx + key.length);
    final colon = after.indexOf(':');
    if (colon == -1) return null;
    var val = after.substring(colon + 1);
    val = val.split(RegExp(r'[,}\n]')).first.trim();
    val = val.replaceAll("'", '').replaceAll('"', '');
    return val.isEmpty ? null : val;
  }

  fallback['merchant'] = grab('merchant');
  fallback['date'] = grab('date');
  fallback['currency'] = grab('currency');
  final totalStr = grab('total');
  fallback['total'] = totalStr != null ? double.tryParse(totalStr) : null;

  if (fallback.values.every((v) => v == null)) {
    return {'raw': raw};
  }
  return fallback;
}
