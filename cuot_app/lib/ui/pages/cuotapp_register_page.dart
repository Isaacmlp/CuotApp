import 'package:cuot_app/core/supabase/supabase_service.dart';
import 'package:cuot_app/ui/pages/cuotapp_login_page.dart';
import 'package:cuot_app/widget/register/step_basic_info.dart';
import 'package:cuot_app/widget/register/step_documents.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class CuotAppRegisterPage extends StatefulWidget {
  const CuotAppRegisterPage({super.key});

  @override
  State<CuotAppRegisterPage> createState() => _CuotAppRegisterPageState();
}

class _CuotAppRegisterPageState extends State<CuotAppRegisterPage> {
  static const Color kLightGreen = Color(0xFFB9F6CA);
  static const Color kPrimaryGreen = Color(0xFF00C853);

  int _currentStep = 0;

  // Keys de formularios
  final formStep1Key = GlobalKey<FormState>();

  // Controllers compartidos
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController telefonoCtrl = TextEditingController();
  final TextEditingController cedulaCtrl = TextEditingController();
  final TextEditingController contrasenaCtrl = TextEditingController();
  final TextEditingController contrasenaVerificaCtrl = TextEditingController();

  File? cedulaFile;

  @override
  void dispose() {
    nombreCtrl.dispose();
    emailCtrl.dispose();
    telefonoCtrl.dispose();
    cedulaCtrl.dispose();
    contrasenaCtrl.dispose();
    contrasenaVerificaCtrl.dispose();
    super.dispose();
  }

  bool isEmpty () {
    return nombreCtrl.text.isEmpty || emailCtrl.text.isEmpty || telefonoCtrl.text.isEmpty || contrasenaCtrl.text.isEmpty;
  }

  bool isContrasenaValid () {
    return contrasenaCtrl.text == contrasenaVerificaCtrl.text;
  }

  Future<void> _continuar() async {
    final bool isLastStep = _currentStep == _steps.length - 1;

    if (_currentStep == 0) {
      if (formStep1Key.currentState?.validate() != true) return;
    }

    if (isContrasenaValid()) {
      if (!isEmpty()) {
        if (isLastStep) {
          // TODO: enviar datos al backend (ahora con soporte para imagen/pdf en Supabase Storage en el futuro)
          final supabaseService = SupabaseService();
        
          try {
            String? cedulaUrl;
            if (cedulaFile != null) {
              cedulaUrl = await supabaseService.uploadFile(
                folder: 'cedulas',
                fileName: 'cedula_${cedulaCtrl.text}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                file: cedulaFile!,
              );
            }

            await supabaseService.client.schema("Financiamientos").from("Usuarios").insert({
              "Nombre_Completo": nombreCtrl.text,
              "Correo_Electronico": emailCtrl.text,
              "Telefono": telefonoCtrl.text,
              "Cedula": cedulaCtrl.text,
              "Contrasena": contrasenaCtrl.text,
              "cedula_url": cedulaUrl,
            });

            if(mounted){
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Registro completado!'),
                  backgroundColor: Colors.green,
                ),
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CuotAppLoginPage()),
              );
            }
          } catch(e) {
             if(mounted){
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al registrar: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
             }
          }
          
        } else {
          setState(() => _currentStep += 1);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, rellena todos los campos.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _atras() {
    if (_currentStep == 0) return;
    setState(() => _currentStep -= 1);
  }

  List<Step> get _steps => [
        Step(
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          isActive: _currentStep >= 0,
          title: const Text('Información Básica', style: TextStyle(fontWeight: FontWeight.bold)),
          content: StepBasicInfo(
            formKey: formStep1Key,
            nombreCtrl: nombreCtrl,
            emailCtrl: emailCtrl,
            telefonoCtrl: telefonoCtrl,
            cedulaCtrl: cedulaCtrl,
            primaryGreen: kPrimaryGreen,
            contrasenaCtrl: contrasenaCtrl,
            contrasenaVerificaCtrl: contrasenaVerificaCtrl,
          ),
        ),
        Step(
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          isActive: _currentStep >= 1,
          title: const Text('Documentos de Identidad', style: TextStyle(fontWeight: FontWeight.bold)),
          content: StepDocuments(
            cedulaFile: cedulaFile,
            onCedulaPicked: (file) => setState(() => cedulaFile = file),
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        iconTheme: const IconThemeData(color: kPrimaryGreen),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kLightGreen.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_add, size: 20, color: kPrimaryGreen),
            ),
            const SizedBox(width: 10),
            const Text(
              'Crea tu Cuenta',
              style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F8E9), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: kPrimaryGreen),
          ),
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: _continuar,
            onStepCancel: _atras,
            onStepTapped: (step) => setState(() => _currentStep = step),
            elevation: 0,
            physics: const BouncingScrollPhysics(),
            controlsBuilder: (context, details) {
              final bool isLast = _currentStep == _steps.length - 1;
              return Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isLast ? 'FINALIZAR REGISTRO' : 'CONTINUAR',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    if (_currentStep != 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade300, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'VOLVER',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: _steps,
          ),
        ),
      ),
    );
  }
}
