import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;
  final bool fullScreen;
  final bool useCupertino; // Para estilo iOS

  const LoadingWidget({
    super.key,
    this.message,
    this.size = 40,
    this.color,
    this.fullScreen = false,
    this.useCupertino = false,
  });

  // 🔧 LÓGICA: Constructor para pantalla completa
  const LoadingWidget.fullScreen({
    super.key,
    this.message,
    this.size = 40,
    this.color,
    this.useCupertino = false,
  })  : fullScreen = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingColor = color ?? theme.primaryColor;

    if (fullScreen) {
      return _buildFullScreen(context, loadingColor);
    }

    return _buildInline(loadingColor);
  }

  // 🔧 LÓGICA: Loading en pantalla completa (fondo semitransparente)
  Widget _buildFullScreen(BuildContext context, Color loadingColor) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLoader(loadingColor),
              if (message != null) ...[
                SizedBox(height: 16),
                Text(
                  message!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 🔧 LÓGICA: Loading inline (para botones o áreas pequeñas)
  Widget _buildInline(Color loadingColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLoader(loadingColor),
        if (message != null) ...[
          SizedBox(height: 8),
          Text(
            message!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  // 🔧 LÓGICA: Seleccionar tipo de loader según plataforma o preferencia
  Widget _buildLoader(Color loadingColor) {
    if (useCupertino) {
      return CupertinoActivityIndicator(
        radius: size / 2,
        color: loadingColor,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size / 8,
        valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
      ),
    );
  }
}

// 🔧 LÓGICA: Widget para loading en botones
class ButtonLoadingWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const ButtonLoadingWidget({
    super.key,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.white,
        ),
      ),
    );
  }
}

// 🔧 LÓGICA: Widget para loading en listas (infinite scroll)
class ListLoadingWidget extends StatelessWidget {
  final bool hasMore;
  final VoidCallback? onRetry;

  const ListLoadingWidget({
    super.key,
    required this.hasMore,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No hay más elementos',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: onRetry != null
            ? _buildErrorRetry()
            : CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorRetry() {
    return Column(
      children: [
        Text('Error al cargar más elementos'),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(100, 36),
          ),
          child: Text('Reintentar'),
        ),
      ],
    );
  }
}

// 🔧 LÓGICA: Widget para loading en tarjetas (skeleton)
class SkeletonLoadingWidget extends StatelessWidget {
  final int itemCount;
  final double height;
  final double? width;
  final double borderRadius;

  const SkeletonLoadingWidget({
    super.key,
    this.itemCount = 5,
    this.height = 80,
    this.width,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          width: width ?? double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: _buildShimmer(),
        );
      },
    );
  }

  Widget _buildShimmer() {
    // 🔧 LÓGICA: Efecto de shimmer (brillo animado)
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// 🔧 LÓGICA: Mixin para manejar estados de carga en StatefulWidget
mixin LoadingMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void showLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  void hideLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  Future<T?> runWithLoading<T>(Future<T?> Function() function) async {
    showLoading();
    try {
      final result = await function();
      return result;
    } catch (e) {
      rethrow;
    } finally {
      hideLoading();
    }
  }
}