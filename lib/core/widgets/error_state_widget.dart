import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Shown whenever a [ServiceResult] carries an error.
/// Provides a retry callback so the user is never stuck.
class ErrorStateWidget extends StatelessWidget {
  final String? errorCode;
  final String? errorMessage;
  final VoidCallback onRetry;

  const ErrorStateWidget({
    super.key,
    this.errorCode,
    this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.urgencyRed.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: AppTheme.urgencyRed, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Couldn\'t retrieve content',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (errorCode != null) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.urgencyRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.urgencyRed.withAlpha(60)),
                ),
                child: Text(
                  errorCode!,
                  style: GoogleFonts.poppins(
                    color: AppTheme.urgencyRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: GoogleFonts.poppins(
                    color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.forestGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.refresh_rounded,
                      color: AppTheme.harvestAmber, size: 18),
                  const SizedBox(width: 8),
                  Text('Retry',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uniform loading state matching the dark theme.
class LoadingStateWidget extends StatelessWidget {
  final String? label;
  const LoadingStateWidget({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(
          color: AppTheme.harvestAmber,
          strokeWidth: 2.5,
        ),
        if (label != null) ...[
          const SizedBox(height: 16),
          Text(label!,
              style: GoogleFonts.poppins(
                  color: Colors.white38, fontSize: 13)),
        ],
      ]),
    );
  }
}
