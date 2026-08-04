import 'package:flutter/material.dart';
import 'package:yjeek_driver/core/constants/app_sizes.dart';
import 'package:yjeek_driver/core/constants/app_strings.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/core/utils/validators.dart';
import 'package:yjeek_driver/core/widgets/app_loader.dart';
import 'package:yjeek_driver/core/widgets/custom_app_bar.dart';
import 'package:yjeek_driver/core/widgets/custom_button.dart';
import 'package:yjeek_driver/core/widgets/custom_text_field.dart';
import 'package:yjeek_driver/features/profile/model/personal_account_model.dart';
import 'package:yjeek_driver/features/profile/service/profile_service.dart';
import 'package:yjeek_driver/services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  bool _isLoadingPersonal = false;
  bool _isSaving = false;
  PersonalAccountModel? _personal;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPersonalAccount();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonalAccount() async {
    if (_isLoadingPersonal) return;
    setState(() => _isLoadingPersonal = true);

    try {
      final personal = await _profileService.getPersonalAccount();
      if (!mounted) return;

      setState(() {
        _personal = personal;
        _nameController.text = personal.fullName;
        _phoneController.text = personal.formattedPhone;
        _emailController.text = personal.email;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      AppHelpers.showSnackBar(
        context,
        'Failed to load personal account',
        isError: true,
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingPersonal = false);
    }
  }

  (String firstName, String lastName) _splitFullName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return ('', '');
    }
    if (parts.length == 1) {
      return (parts.first, '');
    }
    return (parts.first, parts.sublist(1).join(' '));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final (firstName, lastName) = _splitFullName(_nameController.text);
    if (firstName.isEmpty) {
      AppHelpers.showSnackBar(context, 'Name is required', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = await _profileService.updatePersonalAccount(
        firstName: firstName,
        lastName: lastName,
        email: _emailController.text.trim(),
        dateOfBirth: _personal?.dateOfBirth,
        gender: _personal?.gender,
      );
      if (!mounted) return;

      setState(() {
        _personal = updated;
        _nameController.text = updated.fullName;
        _phoneController.text = updated.formattedPhone;
        _emailController.text = updated.email;
      });

      AppHelpers.showSnackBar(context, 'Profile updated');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      AppHelpers.showSnackBar(
        context,
        'Failed to update personal info',
        isError: true,
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showLoader = _isLoadingPersonal && _personal == null;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Edit Profile'),
      body: showLoader
          ? const AppLoader()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (v) =>
                            Validators.required(v, fieldName: 'Name'),
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      CustomTextField(
                        controller: _phoneController,
                        labelText: 'Phone',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const Spacer(),
                      CustomButton(
                        title: AppStrings.save,
                        isLoading: _isSaving,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
