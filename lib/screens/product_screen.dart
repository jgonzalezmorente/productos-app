import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/services.dart';
import 'package:productos_app/providers/product_form_provider.dart';
import 'package:productos_app/services/products_service.dart';
import 'package:productos_app/ui/input_decorations.dart';
import 'package:productos_app/widgets/widgets.dart';


class ProductScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    final productsService = Provider.of<ProductsService>( context );

    return ChangeNotifierProvider(
      create: ( _ ) => ProductFormProvider( productsService.selectedProduct ),
      child: _ProductScreenBody( productsService: productsService )
    );

  }

}


class _ProductScreenBody extends StatelessWidget {
  const _ProductScreenBody({
    Key? key,
    required this.productsService,
  }) : super(key: key);

  final ProductsService productsService;

  @override
  Widget build(BuildContext context) {

    final productForm = Provider.of<ProductFormProvider>( context );

    return Scaffold(
      body: SingleChildScrollView(
        // keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [

            Stack(
              children: [
                
                ProductImage( url: productsService.selectedProduct.picture ),
                
                Positioned(
                  top: 60,
                  left: 20,
                  child: IconButton(
                    onPressed: () => Navigator.of( context ).pop(),
                    icon: Icon( Icons.arrow_back_ios_new, size: 40, color: Colors.white )
                  )
                ),
                
                Positioned(
                  top: 60,
                  right: 20,
                  child: IconButton(
                    onPressed: () async {

                      final picker = new ImagePicker();
                      final XFile? pickedFile = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 75
                      );

                      if ( pickedFile == null ) {
                        print( 'No seleccionó nada' );
                        return;
                      }

                      print( 'Tenemos imagen ${ pickedFile.path }' );
                      productsService.updateSelectedProductImage( pickedFile.path );




                      

                    },
                    icon: Icon( Icons.camera_alt_outlined, size: 40, color: Colors.white )
                  )
                )
              ],
            ),

            _ProductForm(),

            SizedBox( height: 100 ),

          ],
        ),
     ),

     floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
     floatingActionButton: Padding(
       padding: EdgeInsets.only( bottom: 5 ),
       child: FloatingActionButton(       
         child: productsService.isSaving
          ? CircularProgressIndicator( color: Colors.white ) 
          : Icon( Icons.save_outlined ),
         onPressed: productsService.isSaving
          ? null
          : () async {

           if ( !productForm.isValidForm() ) return;

           final String? imageUrl = await productsService.uploadImage();
           
           if ( imageUrl != null ) productForm.product.picture = imageUrl;
           
           await productsService.saveOrCreateProduct( productForm.product );

         }),
     ),
   );
  }
}


class _ProductForm extends StatelessWidget {


  @override
  Widget build(BuildContext context) {

    final productForm = Provider.of<ProductFormProvider>( context );
    final product = productForm.product;  
    
    return Padding(
      padding: EdgeInsets.symmetric( horizontal: 10 ),
      child: Container(
        padding: EdgeInsets.symmetric( horizontal: 20 ),
        width: double.infinity,        
        decoration: _buildBoxDecoration(),

        child: Form(
          
          key: productForm.formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,

          child: Column(
            children: [

              SizedBox( height: 10 ),

              TextFormField(

                initialValue: product.name,
                onChanged: ( value ) => product.name = value,
                validator: ( value ) {
                  if ( value == null || value.length < 1 ) {
                    return 'El nombre es obligatorio';
                  }
                },

                decoration: InputDecorations.authInputDecoration(
                  hintText: 'Nombre del producto', 
                  labelText: 'Nombre:'
                )

              ),

              SizedBox( height: 30 ),

              TextFormField(

                initialValue: '${product.price}',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}'))
                ],
                onChanged: ( value ) {
                  if ( double.tryParse( value ) == null ) {
                    product.price = 0;
                  } else {
                    product.price = double.parse( value );
                  }                  
                },
                keyboardType: TextInputType.number,
                decoration: InputDecorations.authInputDecoration(
                  hintText: '\$150', 
                  labelText: 'Precio:'
                )

              ),

              SizedBox( height: 30 ),

              SwitchListTile.adaptive(
                value: product.available,
                title: Text( 'Disponible' ),
                activeColor: Colors.indigo,
                onChanged: productForm.updateAvailability
              )
            ],
          )
        )
      ),
    );
  }

  BoxDecoration _buildBoxDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.only( bottomRight: Radius.circular( 25 ), bottomLeft: Radius.circular( 25 ) ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity( 0.05 ),
        offset: Offset( 0, 5 ),
        blurRadius: 5
      )
    ]
  );
}