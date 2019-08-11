import 'package:flutter/material.dart';
import 'package:media_picker/media_picker.dart';
import 'package:media_picker_example/medias_page.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              RaisedButton(
                  child: Text('IMAGE'),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MediasPage(assetType: AssetType.image),
                        ));
                  }),
              RaisedButton(
                  child: Text('VIDEO'),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MediasPage(assetType: AssetType.video),
                        ));
                  })
            ]),
      ),
    );
  }
}
