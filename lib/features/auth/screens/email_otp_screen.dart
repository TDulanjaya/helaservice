import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../services/otp_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/l10n_extension.dart';
import '../../../state/role_provider.dart';
import '../../../splash_screen.dart';
import '../../customer/screens/home_discovery_screen.dart';
import '../../../utils/responsive.dart';
import 'login_screen.dart';

class EmailOtpScreen extends StatefulWidget {
  final String email;
  // optional step after verify
  final Future<void> Function()? onVerified;
  final String? title;
  final String? subtitle;
  final String purpose;
  final bool allowSignOut;
  final bool sendOnOpen;
  final OtpService? otpService;

  const EmailOtpScreen({
    super.key,
    required this.email,
    this.onVerified,
    this.title,
    this.subtitle,
    this.purpose = 'signup',
    this.allowSignOut = true,
    this.sendOnOpen = false,
    this.otpService,
  });

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  static const int _codeLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_codeLength, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  OtpService get _effectiveOtpService => widget.otpService ?? OtpService();

  @override
  void initState() {
    super.initState();
    if (widget.sendOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendOnOpen();
      });
    } else {
      _startCountdown();
    }
  }

  Future<void> _sendOnOpen() async {
    final lang = context.l10n.localeName;
    try {
      await _effectiveOtpService.sendEmailOtp(
        widget.email,
        purpose: widget.purpose,
        language: lang,
      );
      if (mounted) {
        _startCountdown(60);
      }
    } on OtpCooldownException catch (e) {
      if (mounted) {
        _startCountdown(e.retryAfter);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.codeAlreadySent)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _startCountdown([int? initialSeconds]) {
    _timer?.cancel();
    final remaining = initialSeconds ?? _effectiveOtpService.remainingCooldownSeconds;
    setState(() {
      _secondsRemaining = remaining > 0 ? remaining : 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  void _clearCodeBoxes() {
    for (final c in _controllers) {
      c.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes.first.requestFocus();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentCode =>
      _controllers.map((c) => c.text.trim()).join();

  void _onDigitChanged(int index, String value) {
    setState(() => _errorMessage = null);

    // paste code
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) {
        for (int i = 0; i < _codeLength; i++) {
          if (i < digits.length) {
            _controllers[i].text = digits[i];
          }
        }
        final targetIndex = (digits.length < _codeLength) ? digits.length : _codeLength - 1;
        _focusNodes[targetIndex].requestFocus();
        if (digits.length >= _codeLength) {
          _handleVerify();
        }
        return;
      }
    }

    if (value.isNotEmpty) {
      // next box
      if (index < _codeLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_currentCode.length == _codeLength) {
          _handleVerify();
        }
      }
    }
  }

  Future<void> _handleVerify() async {
    if (_isVerifying) return;

    final code = _currentCode;
    if (code.length != _codeLength) {
      setState(() {
        _errorMessage = context.l10n.enterVerificationCode;
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final l10n = context.l10n;
    try {
      final result = await _effectiveOtpService.verifyOtp(
        widget.email,
        code,
        widget.purpose,
      );

      if (!result.isValid) {
        if (result.errorCode == 'OTP_NO_SESSION') {
          _clearCodeBoxes();
          _timer?.cancel();
          setState(() {
            _errorMessage = l10n.otpNoSession;
            _secondsRemaining = 0;
          });
          return;
        }

        if (result.errorCode == 'OTP_EXPIRED') {
          _clearCodeBoxes();
          _timer?.cancel();
          setState(() {
            _errorMessage = l10n.otpExpiredResend;
            _secondsRemaining = 0;
          });
          return;
        }

        if (result.errorCode == 'OTP_MAX_ATTEMPTS') {
          _clearCodeBoxes();
          _timer?.cancel();
          setState(() {
            _errorMessage = l10n.otpMaxAttemptsResend;
            _secondsRemaining = 0;
          });
          return;
        }

        if (result.errorCode == 'OTP_INCORRECT') {
          final remaining = result.attemptsRemaining;
          setState(() {
            _errorMessage = remaining != null
                ? l10n.otpIncorrectTriesLeft(remaining)
                : (result.errorMessage ?? l10n.codeIncorrect);
          });
          return;
        }

        String msg;
        switch (result.errorCode) {
          case 'OTP_CODE_INCOMPLETE':
            msg = l10n.enterOtp;
            break;
          case 'OTP_NETWORK_ERROR':
            msg = l10n.authErrNetwork;
            break;
          case 'SERVICE_UNAVAILABLE':
            msg = result.errorMessage ?? l10n.authErrNetwork;
            break;
          default:
            msg = result.errorMessage ?? l10n.codeIncorrect;
        }
        setState(() {
          _errorMessage = msg;
        });
        return;
      }

      // refresh token to pick up new claims
      try {
        final fbUser = AuthService().currentFirebaseUser;
        if (fbUser != null) {
          await fbUser.getIdToken(true);
        }
      } catch (_) {}

      // verified, reload profile and route from splash
      if (widget.onVerified != null) {
        await widget.onVerified!();
      }
      try {
        final refreshed = await AuthService().fetchCurrentUserProfile();
        if (refreshed != null && mounted) {
          pv.Provider.of<RoleProvider>(context, listen: false)
              .setUser(refreshed);
        }
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final lang = context.l10n.localeName;
      await _effectiveOtpService.sendEmailOtp(
        widget.email,
        purpose: widget.purpose,
        language: lang,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.purpose == 'admin_login'
                  ? context.l10n.admin2faSubtitle
                  : context.l10n.verifyEmailSubtitle(widget.email),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        _startCountdown(60);
      }
    } on OtpCooldownException catch (e) {
      if (mounted) {
        _startCountdown(e.retryAfter);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.codeAlreadySent)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg = context.themeBg;
    final cardBg = isDark ? context.themeSurfaceLow : Colors.white;
    final borderCol = context.themeBorder;
    final title = widget.title ??
        (widget.purpose == 'admin_login'
            ? context.l10n.admin2faTitle
            : context.l10n.verifyYourEmail);
    final subtitle = widget.subtitle ??
        (widget.purpose == 'admin_login'
            ? context.l10n.admin2faSubtitle
            : context.l10n.verifyEmailSubtitle(widget.email));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: IconSquareButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 480,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: Responsive.isPhoneLandscape(context) ? 12 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                // icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.themeInk,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.themeMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 32),

                // otp input boxes
                LayoutBuilder(
                  builder: (context, constraints) {
                    final gap = constraints.maxWidth < 340 ? 6.0 : 8.0;
                    final boxWidth = ((constraints.maxWidth - ((_codeLength - 1) * gap)) / _codeLength).clamp(36.0, 48.0);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_codeLength, (index) {
                        return SizedBox(
                          width: boxWidth,
                          height: 56,
                          child: KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: (event) {
                              if (event is KeyDownEvent &&
                                  event.logicalKey == LogicalKeyboardKey.backspace) {
                                if (_controllers[index].text.isEmpty && index > 0) {
                                  _controllers[index - 1].clear();
                                  _focusNodes[index - 1].requestFocus();
                                }
                              }
                            },
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: index == 0 ? _codeLength : 1,
                              style: TextStyle(
                                fontSize: boxWidth < 40 ? 18 : 22,
                                fontWeight: FontWeight.w700,
                                color: context.themeInk,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: cardBg,
                                contentPadding: EdgeInsets.zero,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _errorMessage != null
                                        ? AppColors.error
                                        : borderCol,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (val) => _onDigitChanged(index, val),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withValues(alpha: isDark ? 0.2 : 0.8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              PrimaryButton(
                label: context.l10n.verifyAndContinue,
                loading: _isVerifying,
                onPressed: _currentCode.length == _codeLength ? _handleVerify : null,
              ),

              const SizedBox(height: 24),

              // resend button
              if (_secondsRemaining > 0)
                Text(
                  context.l10n.resendCodeIn(_secondsRemaining),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.themeMuted,
                  ),
                )
              else
                TextButton(
                  onPressed: _isResending ? null : _handleResend,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  child: _isResending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Text(
                          context.l10n.resendCode,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              const SizedBox(height: 24),
              // spam folder notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.mark_email_unread_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.otpCheckSpamHintTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.otpCheckSpamHintDesc,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.themeMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.allowSignOut) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    await AuthService().signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    context.l10n.useDifferentAccount,
                    style: TextStyle(
                      color: context.themeMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (widget.purpose == 'admin_login') ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeDiscoveryScreen()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    context.l10n.continueAsCustomer,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
}
