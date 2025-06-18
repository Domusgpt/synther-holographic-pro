import 'package:flutter/material.dart';

void main() {
  runApp(const SimpleTestApp());
}

class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synther Health Check',
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SYNTHER',
                style: TextStyle(
                  color: Colors.cyan,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'PROFESSIONAL HOLOGRAPHIC',
                style: TextStyle(
                  color: Colors.pink,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 40),
              Container(
                width: 200,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.2),
                  border: Border.all(color: Colors.cyan, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'HEALTH CHECK PASSED',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}