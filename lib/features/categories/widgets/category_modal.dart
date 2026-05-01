import 'package:flutter/material.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/core/constants/icon_constants.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class CategoryModal extends StatefulWidget {
  final Category? category;
  final Function(String name, String iconName, int color) onSave;
  final VoidCallback? onDelete;
  final String? customTitle;

  const CategoryModal({
    super.key,
    this.category,
    required this.onSave,
    this.onDelete,
    this.customTitle,
  });

  @override
  State<CategoryModal> createState() => _CategoryModalState();
}

class _CategoryModalState extends State<CategoryModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedIconName;
  late int _selectedColor;

  static const List<int> _availableColors = [
    0xFFFF6B6B,
    0xFF4ECDC4,
    0xFFFFE66D,
    0xFF95E1D3,
    0xFFA8E6CF,
    0xFFDDA0DD,
    0xFFFFB6C1,
    0xFFADD8E6,
    0xFFFFA500,
    0xFF90EE90,
    0xFFB8B8B8,
    0xFF708090,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIconName =
        widget.category?.iconName ?? IconConstants.iconNames.first;
    _selectedColor = widget.category?.color ?? _availableColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.category != null;

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = Theme.of(context).colorScheme.outline;
    final errorColor = isDark ? Colors.white : AppTheme.errorColor;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.customTitle ??
                        (isEditing ? l10n.editCategory : l10n.addCategory),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  if (isEditing && widget.onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: errorColor),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onDelete!();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Color(_selectedColor).withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    IconConstants.getIcon(_selectedIconName),
                    color: Color(_selectedColor),
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.categoryName,
                  filled: true,
                  fillColor: backgroundColor,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.enterAName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                l10n.icon,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: IconConstants.iconNames.map((iconName) {
                  final isSelected = iconName == _selectedIconName;
                  final icon = IconConstants.getIcon(iconName);
                  return InkWell(
                    onTap: () => setState(() => _selectedIconName = iconName),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_selectedColor).withAlpha(51)
                            : backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Color(_selectedColor)
                              : dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? Color(_selectedColor)
                            : textSecondary,
                        size: 24,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.color,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableColors.map((color) {
                  final isSelected = color == _selectedColor;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = color),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(color),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? textPrimary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCategory,
                  child: Text(
                    isEditing
                        ? l10n.save
                        : (widget.customTitle ?? l10n.addCategory),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        _nameController.text.trim(),
        _selectedIconName,
        _selectedColor,
      );
      Navigator.pop(context);
    }
  }
}

