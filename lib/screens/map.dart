import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:convert' as convert;

import '../widgets/map_widget.dart';

class MyMap extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Map"),
      ),
      body: MapWidget(),
    );
  }
}