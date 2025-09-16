import '../services/connectivity_service.dart';
import '../services/cache_service.dart';
import '../services/offline_sync_service.dart';
import '../services/irrigation_scheduler.dart';
import '../services/alert_service.dart';
import '../services/auth_service.dart';
import '../services/bluetooth_service.dart';
import '../services/sms_service.dart';
import '../services/weather_service.dart';
import '../services/mock_data_service.dart';
import '../state/app_state.dart';

class ServiceLocator {
  static final _instances = <Type, dynamic>{};

  static Future<void> init() async {
    _register<ConnectivityService>(ConnectivityService());
    _register<CacheService>(CacheService());
    _register<AuthService>(AuthService());
    _register<SmsService>(SmsService());
    _register<BluetoothService>(BluetoothService());
    _register<WeatherService>(WeatherService());
    _register<AlertService>(AlertService());
    _register<OfflineSyncService>(
      OfflineSyncService(
        cache: get<CacheService>(),
        connectivity: get<ConnectivityService>(),
      ),
    );
    _register<IrrigationScheduler>(
      IrrigationScheduler(
        weatherService: get<WeatherService>(),
        cacheService: get<CacheService>(),
      ),
    );
    _register<AppState>(AppState());
    _register<MockDataService>(
      MockDataService(cache: get<CacheService>())..seed(),
    );
    // TODO: Load persisted settings / language / role profiles
  }

  static T get<T extends Object>() => _instances[T] as T;

  static void _register<T>(T instance) => _instances[T] = instance;
}
