import 'package:camera/camera.dart';
import 'package:document_scanner_app/pages/scan/scan_page.dart';
import 'package:document_scanner_app/pages/settings/settings_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {

final CameraDescription camera;

  const HomePage({super.key, required this.camera});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Document Scanner App"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return SettingsPage();
                  }
                )
              );
            }, 
            icon: const Icon(Icons.settings_rounded)
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) {
                return ScanPage(camera: widget.camera,);
              }
            )
          );
        },
        child: const Icon(Icons.camera_enhance_rounded),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
        bottomNavigationBar: BottomAppBar(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          notchMargin: 5,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {}, 
                icon: const Icon(
                  Icons.folder_rounded,
                )
              ),
              IconButton(
                onPressed: () {}, 
                icon: const Icon(
                  Icons.photo_rounded,
                )
              )
            ],
          ),
        ),
    );
  }
}