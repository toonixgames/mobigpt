import 'package:flutter/material.dart';
import 'package:mobigpt/repositories/rating_repository.dart';
import 'package:rate_popup/rate_popup.dart';
import '../theme/appColors.dart';

/// Service to manage ratings
class RatingService {
  RatingService({required RatingRepository ratingRepository})
      : _ratingRepository = ratingRepository;

  final RatingRepository _ratingRepository;

  void showRatingDialog(BuildContext context) async {
    // the Rating object returned from the RatingDialog widget
    final rating = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: RatingDialog(
            appName: 'MobiGPT',
            primaryColor: AppColors.lightPrimary,
            textColor: Theme.of(context).colorScheme.onSurface,
            textFieldColor: _getTextFieldColor(context),
            popupBackgroudColor: Theme.of(context).colorScheme.background,
            buttonTextColor: Colors.white,
          ),
        );
      },
    );

    if(rating != null) {
      _ratingRepository.addRating(rating);
    }
  }

  // override theme colors for text field, depending on light or dark mode
  Color _getTextFieldColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark; // check if dark mode

    final surfaceColor = isDark
        ? AppColors.ratingDarkTextField     // dark mode color, dark grey
        : AppColors.ratingLightTextField;  // light mode color, light grey

    return surfaceColor;
  }
}