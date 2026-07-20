import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../config/environment.dart';
import '../network/api_client.dart';
import '../presentation/models/notification_model.dart';
import 'logger_service.dart';
import 'secure_storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  WebSocket? _webSocket;
  final StreamController<NotificationModel> _notificationStreamController =
      StreamController<NotificationModel>.broadcast();
  final StreamController<Map<String, dynamic>> _wsEventStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<NotificationModel> get notifications => _notificationStreamController.stream;
  Stream<Map<String, dynamic>> get wsEvents => _wsEventStreamController.stream;

  bool _isConnecting = false;
  Timer? _reconnectTimer;

  Future<void> connect() async {
    if (_isConnecting || _webSocket != null) return;
    _isConnecting = true;

    final storage = SecureStorageService();
    final userId = await storage.getUserId();

    if (userId == null) {
      _isConnecting = false;
      return;
    }

    final apiUrl = Environment.apiBaseUrl;
    final wsBase = '${apiUrl.replaceFirst(RegExp(r'^http'), 'ws').replaceFirst('/api', '')}/ws';
    final wsUrl = '$wsBase?userId=$userId';

    Log.i('🔌 Conectando a WebSocket: $wsUrl');

    try {
      _webSocket = await WebSocket.connect(wsUrl);
      _isConnecting = false;
      Log.i('✅ Conectado al servidor WebSocket');

      _webSocket!.listen(
        (data) {
          _handleIncomingData(data);
        },
        onError: (error) {
          Log.e('❌ Error en WebSocket', error);
          _handleDisconnect();
        },
        onDone: () {
          Log.w('🔌 Conexión WebSocket cerrada');
          _handleDisconnect();
        },
      );
    } catch (e) {
      _isConnecting = false;
      Log.e('❌ Error al conectar a WebSocket', e);
      _handleDisconnect();
    }
  }

  void _handleIncomingData(dynamic data) {
    try {
      final Map<String, dynamic> message = jsonDecode(data.toString());
      _wsEventStreamController.add(message);

      final type = message['type'];
      final payload = message['payload'];

      if (type == 'notification') {
        Log.i('🔔 Nueva notificación por WS: $payload');
        final notification = NotificationModel.fromJson(payload);
        _notificationStreamController.add(notification);
      }
    } catch (e) {
      Log.e('❌ Error al parsear mensaje de WebSocket', e);
    }
  }

  void _handleDisconnect() {
    _webSocket = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _webSocket?.close();
    _webSocket = null;
    Log.i('🔌 Desconectado de WebSocket manualmente');
  }

  // REST API Methods
  final ApiClient _apiClient = ApiClient();

  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final response = await _apiClient.dio.get('/notificaciones');
      final List<dynamic> list = response.data as List<dynamic>;
      return list.map((j) => NotificationModel.fromJson(j)).toList();
    } catch (e) {
      Log.e('❌ Error al obtener historial de notificaciones', e);
      return [];
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _apiClient.dio.patch('/notificaciones/$id/leido');
      Log.i('✅ Notificación $id marcada como leída');
    } catch (e) {
      Log.e('❌ Error al marcar notificación como leída', e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.dio.patch('/notificaciones/marcar-todas/leidas');
      Log.i('✅ Todas las notificaciones marcadas como leídas');
    } catch (e) {
      Log.e('❌ Error al marcar todas las notificaciones como leídas', e);
    }
  }
}
