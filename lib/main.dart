import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nfc_in_flutter/nfc_in_flutter.dart';

import './read.dart';

void main() => runApp(ExampleApp());

class ExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("NFC in Flutter"),
          backgroundColor: Colors.blueGrey,
        ),
        body: Builder(builder: (context) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ElevatedButton(onPressed: (){
                Navigator.pushNamed(context, "/read_example");
                }, child:
              Text('Read NFC'),)
            ],
          );
        }),
      ),
      routes: {
        "/read_example": (context) => ReadScreen(),
      },
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<NDEFMessage> _stream;

  List<NDEFMessage> _tags = [];

  bool _supportsNFC = false;

  void _readNFC(BuildContext context) {
    try {
      // ignore: cancel_subscriptions
      StreamSubscription<NDEFMessage> subscription = NFC.readNDEF().listen(
              (tag) {
            // On new tag, add it to state
            setState(() {
              _tags.insert(0, tag);
            });
          },
          // When the stream is done, remove the subscription from state
          onDone: () {
            setState(() {
              _stream = null;
            });
          },

          onError: (e) {
            setState(() {
              _stream = null;
            });

            if (!(e is NFCUserCanceledSessionException)) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Error!"),
                  content: Text(e.toString()),
                ),
              );
            }
          });

      setState(() {
        _stream = subscription;
      });
    } catch (err) {
      print("error: $err");
    }
  }

  // _stopReading() cancels the current reading stream
  void _stopReading() {
    _stream?.cancel();
    setState(() {
      _stream = null;
    });
  }

  @override
  void initState() {
    super.initState();
    NFC.isNDEFSupported.then((supported) {
      setState(() {
        _supportsNFC = true;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _stream?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('NFC in Flutter'),
          actions: <Widget>[
            Builder(
              builder: (context) {
                if (!_supportsNFC) {
                  return FlatButton(
                    child: Text("NFC unsupported"),
                    onPressed: null,
                  );
                }
                return FlatButton(
                  child:
                  Text(_stream == null ? "Start reading" : "Stop reading"),
                  onPressed: () {
                    if (_stream == null) {
                      _readNFC(context);
                    } else {
                      _stopReading();
                    }
                  },
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: () {
                setState(() {
                  _tags.clear();
                });
              },
              tooltip: "Clear",
            ),
          ],
        ),
        // Render list of scanned tags
        body: ListView.builder(
          itemCount: _tags.length,
          itemBuilder: (context, index) {
            const TextStyle payloadTextStyle = const TextStyle(
              fontSize: 15,
              color: const Color(0xFF454545),
            );

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text("NDEF Tag",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Builder(
                    builder: (context) {
                      // Build list of records
                      List<Widget> records = [];
                      for (int i = 0; i < _tags[index].records.length; i++) {
                        records.add(Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "Record ${i + 1} - ${_tags[index].records[i].type}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF666666),
                              ),
                            ),
                            Text(
                              _tags[index].records[i].payload,
                              style: payloadTextStyle,
                            ),
                            Text(
                              _tags[index].records[i].data,
                              style: payloadTextStyle,
                            ),
                          ],
                        ));
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: records,
                      );
                    },
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}