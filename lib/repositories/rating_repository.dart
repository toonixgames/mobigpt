import 'package:rate_popup/src/db/entities.dart';

abstract class RatingRepository {
  void addRating(Rating rating);
}