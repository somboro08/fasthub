import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CamaradeScreen extends StatelessWidget {
  const CamaradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camarades', style: GoogleFonts.poppins()),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Liste des camarades ici',
          style: GoogleFonts.poppins(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }
}