import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../logic/auth_providers.dart';
import '../../widgets/basics.dart';
import '../../widgets/form_fields.dart';
import 'splash_screen.dart';

/// Shared layout for every auth screen: logo, heading, scrollable form.
class _AuthLayout extends StatelessWidget {
  const _AuthLayout({
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: showBack ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(alignment: Alignment.centerLeft, child: AppLogo(size: 56)),
                  const SizedBox(height: AppSpace.xl),
                  Text(title, style: text.headlineSmall),
                  const SizedBox(height: AppSpace.xs),
                  Text(subtitle, style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: AppSpace.xl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows auth errors as a snackbar whenever the controller fails.
void _listenForErrors(WidgetRef ref, BuildContext context) {
  ref.listen(authControllerProvider, (_, next) {
    if (next is AsyncError) showSnack(context, errorMessage(next.error), error: true);
  });
}

// ---------------------------------------------------------------- login

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).signIn(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    _listenForErrors(ref, context);
    final loading = ref.watch(authControllerProvider).isLoading;
    return _AuthLayout(
      title: 'Welcome back',
      subtitle: 'Sign in to report and track campus issues.',
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              children: [
                AppTextField(
                  label: 'Campus email',
                  controller: _email,
                  hint: 'you@${AppConstants.allowedEmailDomains.first}',
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpace.l),
                AppTextField(
                  label: 'Password',
                  controller: _password,
                  hint: 'Your password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: (v) => Validators.required(v, 'Password'),
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
              onPressed: () => context.push(Routes.forgot),
              child: const Text('Forgot password?')),
        ),
        const SizedBox(height: AppSpace.s),
        PrimaryButton(label: 'Sign in', loading: loading, onPressed: _submit),
        const SizedBox(height: AppSpace.l),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('New to ${AppConstants.appName}?',
                style: Theme.of(context).textTheme.bodySmall),
            TextButton(
                onPressed: () => context.push(Routes.register),
                child: const Text('Create account')),
          ],
        ),
        if (kDebugMode && AppConfig.fakeBackend) ...[
          const SizedBox(height: AppSpace.l),
          Text('Demo accounts (debug only)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpace.s),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpace.s,
            children: [
              for (final (label, email) in [
                ('Student', 'amina@alustudent.com'),
                ('Staff', 'staff@alustudent.com'),
              ])
                ActionChip(
                  label: Text(label),
                  onPressed: () {
                    _email.text = email;
                    _password.text = 'password';
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- register

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _department = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _department, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          department: _department.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    _listenForErrors(ref, context);
    final loading = ref.watch(authControllerProvider).isLoading;
    const gap = SizedBox(height: AppSpace.l);
    return _AuthLayout(
      showBack: true,
      title: 'Create your account',
      subtitle: 'Only @${AppConstants.allowedEmailDomains.first} emails can join.',
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              children: [
                AppTextField(
                  label: 'Full name',
                  controller: _name,
                  hint: 'e.g. Amina Hassan',
                  prefixIcon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.name,
                ),
                gap,
                AppTextField(
                  label: 'Campus email',
                  controller: _email,
                  hint: 'you@${AppConstants.allowedEmailDomains.first}',
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                gap,
                AppTextField(
                  label: 'Programme / department',
                  controller: _department,
                  hint: 'e.g. Software Engineering',
                  prefixIcon: Icons.school_outlined,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, 'Department'),
                ),
                gap,
                AppTextField(
                  label: 'Password',
                  controller: _password,
                  hint: 'At least ${AppConstants.passwordMin} characters',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        PrimaryButton(label: 'Create account', loading: loading, onPressed: _submit),
        const SizedBox(height: AppSpace.m),
        Text(
          "We'll send a verification link to your campus email.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- forgot

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final ok = await ref.read(authControllerProvider.notifier).sendPasswordReset(_email.text);
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    _listenForErrors(ref, context);
    final loading = ref.watch(authControllerProvider).isLoading;
    return _AuthLayout(
      showBack: true,
      title: _sent ? 'Check your inbox' : 'Reset password',
      subtitle: _sent
          ? 'If an account exists for ${_email.text.trim()}, a reset link is on its way.'
          : "Enter your campus email and we'll send you a reset link.",
      children: _sent
          ? [
              PrimaryButton(label: 'Back to sign in', onPressed: () => context.pop()),
            ]
          : [
              Form(
                key: _form,
                child: AppTextField(
                  label: 'Campus email',
                  controller: _email,
                  hint: 'you@${AppConstants.allowedEmailDomains.first}',
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              PrimaryButton(label: 'Send reset link', loading: loading, onPressed: _submit),
            ],
    );
  }
}

// ---------------------------------------------------------------- verify

class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _listenForErrors(ref, context);
    final user = ref.watch(currentUserProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final loading = ref.watch(authControllerProvider).isLoading;
    return _AuthLayout(
      title: 'Verify your email',
      subtitle:
          'We sent a link to ${user?.email ?? 'your email'}. Open it, then come back here.',
      children: [
        const Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primarySoft,
            child: Icon(Icons.mark_email_unread_outlined, size: 44, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpace.xxl),
        PrimaryButton(
          label: "I've verified my email",
          loading: loading,
          onPressed: () async {
            await controller.reloadUser();
            final verified = ref.read(currentUserProvider)?.emailVerified ?? false;
            if (!verified && context.mounted) {
              showSnack(context, 'Not verified yet — check your inbox and spam folder.');
            }
          },
        ),
        const SizedBox(height: AppSpace.m),
        OutlinedButton(
          onPressed: loading
              ? null
              : () async {
                  if (await controller.resendVerification() && context.mounted) {
                    showSnack(context, 'Verification email sent.');
                  }
                },
          child: const Text('Resend email'),
        ),
        const SizedBox(height: AppSpace.s),
        TextButton(onPressed: controller.signOut, child: const Text('Use a different account')),
      ],
    );
  }
}
