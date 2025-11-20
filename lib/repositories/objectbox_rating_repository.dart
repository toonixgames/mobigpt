import 'package:mobigpt/data/entities/rating_entity.dart';
import 'package:mobigpt/repositories/rating_repository.dart';
import 'package:mobigpt/objectbox.g.dart';
import 'package:rate_popup/src/db/entities.dart';

class ObjectBoxRatingRepository implements RatingRepository {
  ObjectBoxRatingRepository(this._ratingBox);

  final Box<RatingEntity> _ratingBox;

  @override
  void addRating(Rating rating) {
    RatingEntity ratingEntity = RatingEntity.fromRating(rating);
    try {
      _ratingBox.put(ratingEntity);
    } catch (e) {
      //
    }
  }

}