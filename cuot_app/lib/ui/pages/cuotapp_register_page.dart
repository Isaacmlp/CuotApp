import 'package:cuot_app/core/supabase/supabase_service.dart';
import 'package:cuot_app/ui/pages/cuotapp_login_page.dart';
import 'package:cuot_app/widget/register/step_basic_info.dart';
import 'package:cuot_app/widget/register/step_documents.dart';
import 'package:cuot_app/widget/register/step_payment.dart';
import 'package:flutter/material.dart';

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
  final formStep3Key = GlobalKey<FormState>();

  // Controllers compartidos
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController telefonoCtrl = TextEditingController();
  final TextEditingController cedulaCtrl = TextEditingController();
  final TextEditingController contrasenaCtrl = TextEditingController();
  final TextEditingController contrasenaVerificaCtrl = TextEditingController();

  String? cedulaPath;
  String? facturaPath;
  String metodoPago = 'Transferencia';
  final TextEditingController detallesPagoCtrl = TextEditingController();

  @override
  void dispose() {
    nombreCtrl.dispose();
    emailCtrl.dispose();
    telefonoCtrl.dispose();
    detallesPagoCtrl.dispose();
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
    if (_currentStep == 2) {
      if (formStep3Key.currentState?.validate() != true) return;
    }

    if (isContrasenaValid()) {

      if (!isEmpty()) {

        if (isLastStep) {
          // TODO: enviar datos al backend
          final supabaseService = SupabaseService();
        

          await supabaseService.client.schema("Usuarios").from("Usuarios").insert({
            "Nombre_Completo": nombreCtrl.text,
            "Correo_Electronico": emailCtrl.text,
            "Telefono": telefonoCtrl.text,
            "Cedula": cedulaCtrl.text,
            "Contrasena": contrasenaCtrl.text,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Registro completado!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CuotAppLoginPage()),
          );
          
        } else {
          setState(() => _currentStep += 1);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, rellena todos los campos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
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
          title: const Text('Información básica'),
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
          title: const Text('Documentos'),
          content: StepDocuments(
            cedulaPath: cedulaPath,
            facturaPath: facturaPath,
            onCedulaPicked: (path) => setState(() => cedulaPath = path),
            onFacturaPicked: (path) => setState(() => facturaPath = path),
          ),
        ),
        Step(
          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          isActive: _currentStep >= 2,
          title: const Text('Forma de pago'),
          content: StepPayment(
            formKey: formStep3Key,
            metodoPago: metodoPago,
            onMetodoPagoChanged: (value) =>
                setState(() => metodoPago = value ?? 'Transferencia'),
            detallesPagoCtrl: detallesPagoCtrl,
            primaryGreen: kPrimaryGreen,
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: kPrimaryGreen),
        title: const Text(
          'Registro CuotApp',
          style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F5E9),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: _continuar,
          onStepCancel: _atras,
          onStepTapped: (step) => setState(() => _currentStep = step),
          controlsBuilder: (context, details) {
            final bool isLast = _currentStep == _steps.length - 1;
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: Text(isLast ? 'Finalizar' : 'Siguiente'),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep != 0)
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimaryGreen,
                        side: const BorderSide(color: kPrimaryGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text('Atrás'),
                    ),
                ],
              ),
            );
          },
          steps: _steps,
        ),
      ),
    );
  }
}
