import 'package:flutter/foundation.dart';

class LanguageService extends ChangeNotifier {
  String _locale = 'en';
  String get locale => _locale;

  void toggleLanguage() {
    _locale = _locale == 'en' ? 'tr' : 'en';
    notifyListeners();
  }

  void setLocale(String lang) {
    if (lang == 'en' || lang == 'tr') {
      _locale = lang;
      notifyListeners();
    }
  }

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'title': 'Antibiotic Resistance Monitor',
      'app_name': 'ANTIBIOTIC MONITOR',
      'app_subtitle': 'Resistance Detection System v1.0',
      'scan_for_devices': 'SCAN FOR DEVICES',
      'scanning_for_devices': 'SCANNING FOR DEVICES...',
      'connecting': 'CONNECTING...',
      'make_sure_power': 'Make sure HM-10 module is powered on',
      'no_devices_found': 'No devices found.\nPress SCAN to search.',
      'nearby_devices': 'NEARBY DEVICES',
      'hm10_label': 'HM-10',
      'connection_failed': 'Connection failed. Try again.',
      'temperature': 'TEMPERATURE',
      'turbidity': 'TURBIDITY (LDR)',
      'light_level': 'Light Level',
      'sufficient': 'SUFFICIENT',
      'low': 'LOW',
      'risk_detected': 'RISK DETECTED',
      'env_stable': 'ENVIRONMENT STABLE',
      'risk_message': 'Possible bacterial growth detected — check conditions immediately',
      'safe_message': 'All parameters within safe range — no bacterial threat detected',
      'awaiting_data': 'AWAITING ARDUINO DATA...',
      'connecting_sensors': 'CONNECTING TO SENSORS...',
      'disconnect': 'DISCONNECT',
      'connected': 'CONNECTED',
      'offline': 'OFFLINE',
      'bluetooth_disabled': 'Bluetooth Disabled',
      'enable_bluetooth': 'Please enable Bluetooth to scan for devices.',
      'live_monitor': 'LIVE MONITOR',
      'device_disconnected': 'Device disconnected.',
      'disconnect_tooltip': 'Disconnect',
      'risk_snackbar': '⚠ Risk conditions detected! Temp or LDR threshold breached.',
      'dht11_failed_error': 'Arduino Sensor Error: DHT11 failed to read.',
      'system_status': 'SYSTEM STATUS',
      'temp_threshold_label': 'Temperature threshold (30°C)',
      'ldr_threshold_label': 'LDR light threshold (≥500)',
      'arduino_status_flag': 'Arduino status flag',
      'temp_trend': 'TEMPERATURE TREND',
      'risk_threshold_ref': 'RISK THRESHOLD REFERENCE',
      'risk': 'Risk',
      'ldr_value': 'LDR Value',
      'both_in_range': 'Both within range',
      'safe_ref_message': 'Safe — no bacterial growth',
      'not_connected': 'NOT CONNECTED',
      'not_connected_sub': 'Return to scanner and reconnect',
      'awaiting_data_sub': 'Ensure Arduino is transmitting serial data',
      'last_updated': 'Last updated',
      'live': 'LIVE',
      'safe': 'SAFE',
      'risk_text': 'RISK',
      'device_name': 'Device Name',
      'mac_address': 'MAC Address',
      'unknown_device': 'Unknown Device',
    },
    'tr': {
      'title': 'Antibiyotik Direnç Monitörü',
      'app_name': 'ANTİBİYOTİK MONİTÖRÜ',
      'app_subtitle': 'Direnç Algılama Sistemi v1.0',
      'scan_for_devices': 'CİHAZLARI TARA',
      'scanning_for_devices': 'CİHAZLAR TARANIYOR...',
      'connecting': 'BAĞLANIYOR...',
      'make_sure_power': 'HM-10 modülünün açık olduğundan emin olun',
      'no_devices_found': 'Cihaz bulunamadı.\nAramak için TARA tuşuna basın.',
      'nearby_devices': 'YAKINDAKİ CİHAZLAR',
      'hm10_label': 'HM-10',
      'connection_failed': 'Bağlantı başarısız. Tekrar deneyin.',
      'temperature': 'SICAKLIK',
      'turbidity': 'BULANIKLIK (LDR)',
      'light_level': 'Işık Seviyesi',
      'sufficient': 'YETERLİ',
      'low': 'DÜŞÜK',
      'risk_detected': 'RİSK TESPİT EDİLDİ',
      'env_stable': 'ORTAM STABİL',
      'risk_message': 'Olası bakteriyel büyüme tespit edildi — koşulları hemen kontrol edin',
      'safe_message': 'Tüm parametreler güvenli aralıkta — bakteriyel tehdit tespit edilmedi',
      'awaiting_data': 'ARDUINO VERİSİ BEKLENİYOR...',
      'connecting_sensors': 'SENSÖRLERE BAĞLANILIYOR...',
      'disconnect': 'BAĞLANTIYI KES',
      'connected': 'BAĞLI',
      'offline': 'ÇEVRİMDIŞI',
      'bluetooth_disabled': 'Bluetooth Kapalı',
      'enable_bluetooth': 'Cihazları taramak için lütfen Bluetooth\'u etkinleştirin.',
      'live_monitor': 'CANLI TAKİP',
      'device_disconnected': 'Cihaz bağlantısı kesildi.',
      'disconnect_tooltip': 'Bağlantıyı Kes',
      'risk_snackbar': '⚠ Risk koşulları algılandı! Sıcaklık veya LDR eşiği aşıldı.',
      'dht11_failed_error': 'Arduino Sensör Hatası: DHT11 okunamadı.',
      'system_status': 'SİSTEM DURUMU',
      'temp_threshold_label': 'Sıcaklık eşiği (30°C)',
      'ldr_threshold_label': 'LDR ışık eşiği (≥500)',
      'arduino_status_flag': 'Arduino durum bayrağı',
      'temp_trend': 'SICAKLIK TRENDİ',
      'risk_threshold_ref': 'RİSK EŞİĞİ REFERANSI',
      'risk': 'Risk',
      'ldr_value': 'LDR Değeri',
      'both_in_range': 'Her iki değer normal',
      'safe_ref_message': 'Güvenli — bakteriyel büyüme yok',
      'not_connected': 'BAĞLI DEĞİL',
      'not_connected_sub': 'Tarayıcıya dönüp tekrar bağlanın',
      'awaiting_data_sub': 'Arduino\'nun veri gönderdiğinden emin olun',
      'last_updated': 'Son güncelleme',
      'live': 'CANLI',
      'safe': 'GÜVENLİ',
      'risk_text': 'RİSK',
      'device_name': 'Cihaz Adı',
      'mac_address': 'MAC Adresi',
      'unknown_device': 'Bilinmeyen Cihaz',
    }
  };

  String translate(String key) {
    return _translations[_locale]?[key] ?? key;
  }
}
