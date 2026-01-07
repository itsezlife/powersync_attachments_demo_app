// ignore_for_file: lines_longer_than_80_chars

import 'package:insta_assets_picker/insta_assets_picker.dart';

/// [AssetPickerTextDelegate] implements with Spanish.
/// Spanish Localization
class SpanishAssetPickerTextDelegate extends AssetPickerTextDelegate {
  const SpanishAssetPickerTextDelegate();

  @override
  String get languageCode => 'es';

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get edit => 'Editar';

  @override
  String get gifIndicator => 'GIF';

  @override
  String get livePhotoIndicator => 'EN VIVO';

  @override
  String get loadFailed => 'Error al cargar';

  @override
  String get original => 'Original';

  @override
  String get preview => 'Vista previa';

  @override
  String get select => 'Seleccionar';

  @override
  String get emptyList => 'Lista vacía';

  @override
  String get unSupportedAssetType => 'Tipo de archivo no soportado.';

  @override
  String get unableToAccessAll =>
      'No se puede acceder a todos los archivos en el dispositivo';

  @override
  String get viewingLimitedAssetsTip =>
      'Solo se pueden ver archivos y álbumes accesibles para la aplicación.';

  @override
  String get changeAccessibleLimitedAssets =>
      'Toca para actualizar archivos accesibles';

  @override
  String get accessAllTip =>
      'La aplicación solo puede acceder a algunos archivos en el dispositivo. '
      'Ve a la configuración del sistema y permite que la aplicación acceda a todos los archivos en el dispositivo.';

  @override
  String get goToSystemSettings => 'Ir a la configuración del sistema';

  @override
  String get accessLimitedAssets => 'Continuar con acceso limitado';

  @override
  String get accessiblePathName => 'Archivos accesibles';

  @override
  String get sTypeAudioLabel => 'Audio';

  @override
  String get sTypeImageLabel => 'Imagen';

  @override
  String get sTypeVideoLabel => 'Video';

  @override
  String get sTypeOtherLabel => 'Otro archivo';

  @override
  String get sActionPlayHint => 'reproducir';

  @override
  String get sActionPreviewHint => 'vista previa';

  @override
  String get sActionSelectHint => 'seleccionar';

  @override
  String get sActionSwitchPathLabel => 'cambiar carpeta';

  @override
  String get sActionUseCameraHint => 'usar cámara';

  @override
  String get sNameDurationLabel => 'duración';

  @override
  String get sUnitAssetCountLabel => 'cantidad';
}
