// ignore_for_file: require_trailing_commas
// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseInAppMessaging fiam = FirebaseInAppMessaging.instance;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('In-App Messaging example'),
        ),
        body: Builder(
          builder: (BuildContext context) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  InAppMessageEventDisplay(),
                  AnalyticsEventExample(),
                  ProgrammaticTriggersExample(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Widget that listens to in-app message display events and shows the latest event.
class InAppMessageEventDisplay extends StatefulWidget {
  @override
  State<InAppMessageEventDisplay> createState() =>
      _InAppMessageEventDisplayState();
}

class _InAppMessageEventDisplayState extends State<InAppMessageEventDisplay> {
  Map<String, dynamic>? _latestEvent;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = MyApp.fiam.onMessageDisplay.listen((event) {
      setState(() {
        _latestEvent = event;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.yellow[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Latest In-App Message Event',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _latestEvent != null
                  ? const JsonEncoder.withIndent('  ').convert(_latestEvent)
                  : 'No event received yet.',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgrammaticTriggersExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            const Text(
              'Programmatic Trigger',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Manually trigger events programmatically '),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await MyApp.fiam.triggerEvent('awesome_event');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Triggering event: awesome_event'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(
                'Programmatic Triggers'.toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class AnalyticsEventExample extends StatelessWidget {
  Future<void> _sendAnalyticsEvent() async {
    await MyApp.analytics.logEvent(
      name: 'awesome_event',
      parameters: <String, Object>{
        //'id': 1, // not required?
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            const Text(
              'Log an analytics event',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Trigger an analytics event'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _sendAnalyticsEvent();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Firing analytics event: awesome_event'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(
                'Log event'.toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
