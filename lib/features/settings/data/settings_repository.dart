import '../../../data/local/daos/routine_dao.dart';
import '../../../shared/models/app_settings_model.dart';

class SettingsRepository {
  SettingsRepository(this._dao);
  final RoutineDao _dao;

  Future<AppSettingsModel> load() async => AppSettingsModel.fromMap(await _dao.allSettings());

  Future<void> save(AppSettingsModel s) async {
    for (final e in s.toMap().entries) {
      await _dao.setSetting(e.key, e.value);
    }
  }
}
