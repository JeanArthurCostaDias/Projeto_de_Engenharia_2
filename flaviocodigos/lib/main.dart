import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Captura e Upload de Fotos',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: 'Captura e Upload de Fotos'),
    );
  }
}

class ImageData {
  //conjunto de dados da imagem
  File imageFile; //armazena o arquivo de imagem
  Position? position; //armazena a informação da latitude e longitude
  String? imageUrl; //armazena a URL da imagem apos o upload para o Firebase

  ImageData({required this.imageFile, this.position, this.imageUrl});
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // ignore: prefer_final_fields
  List<ImageData> _imageDataList = [];
  final ImagePicker _picker = ImagePicker();
  bool isUploading = false;

  Future<bool> _requestLocationPermission() async {
    //pede a permissão da localização do usuário
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> _getCurrentLocation() async {
    //pega a localização
    bool hasPermission = await _requestLocationPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de localização negada')),
        );
      }
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao obter localização: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _pickImageFromGallery() async {
    //selecionar imagem da galeria
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      Position? position = await _getCurrentLocation();
      if (mounted) {
        setState(() {
          _imageDataList.add(
            ImageData(imageFile: File(pickedFile.path), position: position),
          );
        });
      }
    }
  }

  Future<void> _getImageFromCamera() async {
    //tirar foto da camera
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      Position? position = await _getCurrentLocation();
      if (mounted) {
        setState(() {
          _imageDataList.add(
            ImageData(imageFile: File(pickedFile.path), position: position),
          );
        });
      }
    }
  }

  void _removeImage(int index) {
    //remoção de imagem
    if (mounted) {
      setState(() {
        _imageDataList.removeAt(index);
      });
    }
  }

  void _removeAllImages() {
    //remoção de todas as imagens
    if (mounted) {
      setState(() {
        _imageDataList.clear();
      });
    }
  }

  Future<void> _uploadAllImages() async {
    //fazer upload de todas as imagens
    if (_imageDataList.isEmpty) return;

    if (mounted) {
      setState(() {
        isUploading = true;
      });
    }

    for (var imageData in _imageDataList) {
      try {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = FirebaseStorage.instance.ref().child(
          'uploads/$fileName.jpg',
        );
        await ref.putFile(imageData.imageFile);

        final imageUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('images').add({
          'imageUrl': imageUrl,
          'latitude': imageData.position?.latitude,
          'longitude': imageData.position?.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() {
            imageData.imageUrl = imageUrl;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erro no upload: $e")));
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Upload concluído!")));

      setState(() {
        isUploading = false;
      });
    }
  }

  void _showImageDialog(BuildContext context, ImageData imageData) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(title: const Text('Visualizar Imagem')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.file(imageData.imageFile),
                  const SizedBox(height: 20),
                  if (imageData.position != null)
                    Text(
                      'Localização:\nLatitude: ${imageData.position!.latitude}, Longitude: ${imageData.position!.longitude}',
                      textAlign: TextAlign.center,
                    )
                  else
                    const Text('Localização não disponível.'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
        titleTextStyle: TextStyle(fontSize: 25),
        actions: <Widget>[
          if (_imageDataList.isNotEmpty) // caso houver imagens carregadas
            IconButton(
              // aparece esse icone que remove todas as imagens
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Remover Todas as Fotos',
              onPressed: _removeAllImages,
            ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    // botão para tirar foto
                    onPressed: _getImageFromCamera,
                    icon: Icon(Icons.camera_alt_outlined),
                    label: const Text('Tirar Foto'),
                    style: ButtonStyle(
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20), // espaçamento
                  ElevatedButton.icon(
                    // botão para scolher imagem da galeria
                    onPressed: _pickImageFromGallery,
                    icon: Icon(Icons.photo),
                    label: const Text('Escolher da Galeria'),
                    style: ButtonStyle(
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // espaçamento
              ElevatedButton.icon(
                // botão de upload de imagem e localização
                onPressed:
                    isUploading
                        ? null
                        : _uploadAllImages, //isUploading(true)=null; isUploading(false)=_uploadAllImages
                icon:
                    isUploading
                        ? const SizedBox(
                          //isUploading(true)
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : const Icon(Icons.cloud_upload), //isUploading(false)
                label: const Text('Upload Todas Imagens'),
              ),
              const SizedBox(height: 20), // espaçamento
              SizedBox(
                height: 300,
                child:
                    _imageDataList.isEmpty
                        ? const Text(
                          'Nenhuma foto tirada ainda.',
                        ) //_imageDataList.isEmpty(true)
                        : GridView.builder(
                          //_imageDataList.isEmpty(false)
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8.0,
                              ),
                          itemCount: _imageDataList.length,
                          itemBuilder: (BuildContext context, int index) {
                            final imageData = _imageDataList[index];
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap:
                                      () =>
                                          _showImageDialog(context, imageData),
                                  child: AspectRatio(
                                    aspectRatio: 1.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.zero,
                                        child: Image.file(
                                          imageData.imageFile,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeImage(index),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
