import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../core/config/env.dart';

/// Service for sending branded HTML transactional emails and OTP codes via SMTP.
class EmailService {
  EmailService({EnvConfig? config}) : _config = config ?? EnvConfig.instance;

  final EnvConfig _config;

  static EmailService? _instance;
  static EmailService get instance => _instance ??= EmailService();

  String get _appName => _config.appName;
  String? get _emailUser => _config.emailUser;
  String? get _emailPass => _config.emailPass;

  /// Builds a responsive, branded HTML email template matching the Classicale design system.
  String buildPremiumTemplate({
    required String subject,
    required String contentHtml,
    String? otpCode,
    String? ctaText,
    String? ctaUrl,
  }) {
    final currentYear = DateTime.now().year;
    final fallbackEmail = 'support@${_appName.toLowerCase().replaceAll(RegExp(r'\s+'), '')}.com';
    final supportEmail = _emailUser ?? fallbackEmail;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$subject</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      background-color: #f8fafc;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
    }
    .wrapper {
      width: 100%;
      background-color: #f8fafc;
      padding: 40px 0;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      background-color: #ffffff;
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 4px 20px rgba(15, 23, 42, 0.05);
    }
    .header {
      background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
      padding: 36px 32px;
      text-align: center;
    }
    .header-logo {
      font-size: 28px;
      font-weight: 800;
      color: #ffffff;
      letter-spacing: -0.75px;
      margin: 0;
      text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }
    .header-tagline {
      font-size: 11px;
      color: #e9d5ff;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 1.5px;
      margin: 8px 0 0 0;
    }
    .content {
      padding: 40px 32px 32px 32px;
      color: #334155;
    }
    .content p {
      font-size: 15px;
      line-height: 1.625;
      margin: 0 0 16px 0;
      color: #475569;
    }
    .content h2 {
      font-size: 20px;
      font-weight: 700;
      color: #1e293b;
      margin: 0 0 20px 0;
      line-height: 1.3;
    }
    .otp-card {
      text-align: center;
      margin: 32px 0;
      padding: 24px;
      background-color: #f8fafc;
      border: 1px dashed #e2e8f0;
      border-radius: 12px;
    }
    .otp-code {
      font-size: 36px;
      font-weight: 800;
      color: #4f46e5;
      letter-spacing: 6px;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      margin: 0;
    }
    .otp-expiry {
      font-size: 12px;
      color: #64748b;
      margin: 12px 0 0 0;
    }
    .cta-container {
      text-align: center;
      margin: 36px 0;
    }
    .cta-button {
      background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
      color: #ffffff !important;
      text-decoration: none;
      padding: 14px 32px;
      font-size: 15px;
      font-weight: 600;
      border-radius: 10px;
      display: inline-block;
      box-shadow: 0 4px 12px rgba(79, 70, 229, 0.25);
    }
    .footer {
      background-color: #fafafa;
      padding: 28px 32px;
      text-align: center;
      border-top: 1px solid #f1f5f9;
    }
    .footer-text {
      font-size: 12px;
      color: #94a3b8;
      line-height: 1.5;
      margin: 0;
    }
    .footer-text a {
      color: #6366f1;
      text-decoration: none;
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="container">
      <div class="header">
        <h1 class="header-logo">$_appName</h1>
        <p class="header-tagline">Where Quality Meets Community</p>
      </div>
      <div class="content">
        $contentHtml
        
        ${otpCode != null && otpCode.isNotEmpty ? '''
        <div class="otp-card">
          <div class="otp-code">$otpCode</div>
          <p class="otp-expiry">This code is valid for 10 minutes. Please do not share it with anyone.</p>
        </div>
        ''' : ''}

        ${ctaText != null && ctaUrl != null ? '''
        <div class="cta-container">
          <a href="$ctaUrl" class="cta-button" target="_blank">$ctaText</a>
        </div>
        ''' : ''}
      </div>
      <div class="footer">
        <p class="footer-text">
          &copy; $currentYear $_appName. All rights reserved.<br>
          This is an automated message. Please do not reply directly to this email.<br>
          Need help? Contact our support team at <a href="mailto:$supportEmail">$supportEmail</a>
        </p>
      </div>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Sends an email via configured SMTP server with automatic HTML wrapping.
  Future<void> sendEmail({
    required String toEmail,
    required String subject,
    String? text,
    String? html,
    String? otpCode,
  }) async {
    if (_emailUser == null || _emailPass == null) {
      // In dev or test environments without SMTP credentials, log and continue
      return;
    }

    final finalSubject = subject.isNotEmpty ? subject : '$_appName Notification';
    var finalHtml = html ?? '';

    if (finalHtml.isEmpty && text != null) {
      // Auto-extract OTP code if not explicitly passed
      var detectedOtp = otpCode;
      if (detectedOtp == null) {
        final otpRegex = RegExp(
          r'(?:otp|code|pin)\b[^a-zA-Z0-9]*(?:is[^a-zA-Z0-9]*)?\b([a-zA-Z0-9-]{4,8})\b',
          caseSensitive: false,
        );
        final match = otpRegex.firstMatch(text);
        if (match != null && match.groupCount >= 1) {
          detectedOtp = match.group(1);
        }
      }

      final paragraphs = text
          .split(RegExp(r'\n+'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .map((p) {
            if (detectedOtp != null && p.contains(detectedOtp)) {
              return '<p style="font-weight: 600; color: #1e293b;">Verification Code:</p>';
            }
            return '<p>$p</p>';
          })
          .join();

      finalHtml = buildPremiumTemplate(
        subject: finalSubject,
        contentHtml: '<h2>$finalSubject</h2>$paragraphs',
        otpCode: detectedOtp,
      );
    } else if (finalHtml.isNotEmpty && !finalHtml.contains('<html')) {
      finalHtml = buildPremiumTemplate(
        subject: finalSubject,
        contentHtml: finalHtml,
        otpCode: otpCode,
      );
    }

    final smtpServer = gmail(_emailUser!, _emailPass!);

    final message = Message()
      ..from = Address(_emailUser!, '$_appName Support')
      ..recipients.add(toEmail)
      ..subject = finalSubject
      ..text = text ?? ''
      ..html = finalHtml;

    try {
      await send(message, smtpServer);
    } catch (e) {
      throw Exception('Failed to send email to $toEmail: $e');
    }
  }
}
