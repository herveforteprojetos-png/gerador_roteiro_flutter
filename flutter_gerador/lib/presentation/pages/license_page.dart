import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/license_service.dart';

class LicensePage extends StatefulWidget {
  final bool canContinueWithDemo;
  
  const LicensePage({
    super.key,
    this.canContinueWithDemo = true,
  });

  @override
  State<LicensePage> createState() => _LicensePageState();
}

class _LicensePageState extends State<LicensePage> {
  final _licenseKeyController = TextEditingController();
  final _licenseService = LicenseService();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _licenseInfo;

  @override
  void initState() {
    super.initState();
    _loadLicenseInfo();
  }

  Future<void> _loadLicenseInfo() async {
    final info = await _licenseService.getLicenseInfo();
    setState(() {
      _licenseInfo = info;
    });
  }

  Future<void> _activateLicense() async {
    if (_licenseKeyController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Digite uma chave de licença válida';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _licenseService.activateLifetimeLicense(
      _licenseKeyController.text.trim().toUpperCase(),
    );

    if (success) {
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Licença ativada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Chave de licença inválida. Verifique o formato XXXX-XXXX-XXXX-XXXX';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _formatDeviceId(String deviceId) {
    // Formatar o Device ID para melhor legibilidade
    if (deviceId.length >= 16) {
      return '${deviceId.substring(0, 8)}-${deviceId.substring(8, 16)}...';
    }
    return deviceId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: const Text('Licença do Software'),
        backgroundColor: const Color(0xFF2d2d2d),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status da Licença Atual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2d2d2d),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF404040)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Atual',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_licenseInfo != null) ...[
                    Row(
                      children: [
                        Icon(
                          _licenseInfo!['type'] == 'lifetime' 
                            ? Icons.check_circle 
                            : Icons.schedule,
                          color: _licenseInfo!['type'] == 'lifetime' 
                            ? Colors.green 
                            : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _licenseInfo!['type'] == 'lifetime' 
                            ? 'Licença Vitalícia Ativa' 
                            : 'Modo Demonstração',
                          style: TextStyle(
                            color: _licenseInfo!['type'] == 'lifetime' 
                              ? Colors.green 
                              : Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_licenseInfo!['type'] == 'demo') ...[
                      Text(
                        'Gerações restantes: ${_licenseInfo!['remainingUses']}/10',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      'Device ID: ${_formatDeviceId(_licenseInfo!['deviceId'])}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Ativação de Licença
            if (_licenseInfo?['type'] != 'lifetime') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2d2d2d),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF404040)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ativar Licença Vitalícia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Digite sua chave de licença para desbloquear o acesso completo:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _licenseKeyController,
                      decoration: InputDecoration(
                        labelText: 'Chave de Licença (XXXX-XXXX-XXXX-XXXX)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Digite a chave aqui...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF404040)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF404040)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFFF6B35)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF3d3d3d),
                        errorText: _errorMessage,
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                      style: const TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-]')),
                        LengthLimitingTextInputFormatter(19),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _activateLicense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Ativar Licença',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],

            // Informações sobre Licenças
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2d2d2d),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF404040)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sobre as Licenças',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Modo Demo: 10 gerações gratuitas para teste',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Licença Vitalícia: Uso ilimitado neste computador',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Cada licença é válida para apenas um PC',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Para adquirir uma licença, entre em contato',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botões de Ação
            Row(
              children: [
                if (widget.canContinueWithDemo && 
                    _licenseInfo?['isActive'] == true) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF404040),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _licenseInfo?['type'] == 'lifetime' 
                          ? 'Continuar' 
                          : 'Continuar no Demo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF666666),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Fechar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _licenseKeyController.dispose();
    super.dispose();
  }
}
