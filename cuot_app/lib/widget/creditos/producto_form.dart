import 'package:cuot_app/utils/formatters.dart';
import 'package:cuot_app/utils/validators.dart';
import 'package:cuot_app/widget/creditos/custom_button.dart';
import 'package:cuot_app/widget/creditos/custom_textfield.dart';
import 'package:flutter/material.dart';

class Producto {
  String nombre;
  String descripcion;
  double precioUnitario;
  int cantidad;

  Producto({
    required this.nombre,
    required this.descripcion,
    required this.precioUnitario,
    required this.cantidad,
  });

  double get total => precioUnitario * cantidad;
}

class ProductoForm extends StatefulWidget {
  final Function(List<Producto>) onProductosChanged;

  const ProductoForm({super.key, required this.onProductosChanged});

  @override
  State<ProductoForm> createState() => _ProductoFormState();
}

class _ProductoFormState extends State<ProductoForm> {
  final List<Producto> _productos = [];
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _cantidadController = TextEditingController();

  // 🔧 LÓGICA: Agregar producto a la lista
  void _agregarProducto() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _productos.add(Producto(
          nombre: _nombreController.text,
          descripcion: _descripcionController.text,
          precioUnitario: double.parse(_precioController.text),
          cantidad: int.parse(_cantidadController.text),
        ));
        
        // Limpiar campos
        _nombreController.clear();
        _descripcionController.clear();
        _precioController.clear();
        _cantidadController.clear();
        
        // Notificar cambio
        widget.onProductosChanged(_productos);
      });
    }
  }

  // 🔧 LÓGICA: Eliminar producto
  void _eliminarProducto(int index) {
    setState(() {
      _productos.removeAt(index);
      widget.onProductosChanged(_productos);
    });
  }

  // 🔧 LÓGICA: Calcular total
  double get _totalGeneral {
    return _productos.fold(0, (sum, item) => sum + item.total);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Productos Financiados',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),

        // Formulario para agregar productos
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: _nombreController,
                    label: 'Nombre del Producto *',
                    validator: Validators.required,
                  ),
                  SizedBox(height: 8),
                  CustomTextField(
                    controller: _descripcionController,
                    label: 'Descripción',
                    maxLines: 2,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _precioController,
                          label: 'Precio Unitario *',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.attach_money,
                          validator: Validators.required,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: CustomTextField(
                          controller: _cantidadController,
                          label: 'Cantidad *',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.production_quantity_limits,
                          validator: Validators.required,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  CustomButton(
                    text: 'Agregar Producto',
                    onPressed: _agregarProducto,
                    isExpanded: true,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Lista de productos agregados
        if (_productos.isNotEmpty) ...[
          SizedBox(height: 16),
          Text('Productos Agregados',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _productos.length,
            itemBuilder: (context, index) {
              final producto = _productos[index];
              return Card(
                child: ListTile(
                  title: Text(producto.nombre),
                  subtitle: Text(
                    '${producto.cantidad} x \$${Formatters.formatCurrency(producto.precioUnitario)} = '
                    '\$${Formatters.formatCurrency(producto.total)}'
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminarProducto(index),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL GENERAL:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text('\$${Formatters.formatCurrency(_totalGeneral)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }
}