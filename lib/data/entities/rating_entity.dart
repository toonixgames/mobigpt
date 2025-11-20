import 'package:objectbox/objectbox.dart';
import 'package:rate_popup/src/db/entities.dart';

@Entity()
class RatingEntity {
  @Id(assignable: true)
  int id = 0;

  double score;
  String comment;
  String rater;
  DateTime date = DateTime.now();

  RatingEntity({
    required this.score,
    required this.comment,
    required this.rater
  });

  // Factory constructor to create from rate_popup Rating object
  factory RatingEntity.fromRating(Rating rating) {
    return RatingEntity(
        score: rating.score,
        comment: rating.comment,
        rater: rating.rater
    );
  }
}