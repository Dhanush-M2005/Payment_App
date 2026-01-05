import 'package:floor/floor.dart';
import '../entities/user_behavior.dart';

@dao
abstract class UserBehaviorDao {
  @Query('SELECT * FROM user_behavior WHERE id = 1')
  Future<UserBehavior?> getUserBehavior();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrUpdateBehavior(UserBehavior behavior);
}
