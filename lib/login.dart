import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dash/const.dart';
import 'package:dash/home.dart';
import 'package:dash/widget/loading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  LoginScreenState createState() => LoginScreenState();
}

class ListItem {
  String langCode;
  String langName;

  ListItem(this.langCode, this.langName);
}

class LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences prefs;

  bool isLoading = false;
  bool isLoggedIn = false;
  FirebaseUser currentUser;

  List<ListItem> _dropdownItems = [
    ListItem('en', "English"),
    ListItem('es', "Spanish"),
    ListItem('gu', "Gujarati"),
    ListItem('hi', "Hindi"),
    ListItem('mr', "Marathi"),
    ListItem('bn', "Bengali"),
    ListItem('kn', "Kannada"),
    ListItem('ms', "Malay"),
    ListItem('ml', "Malyalam"),
    ListItem('ta', "Tamil"),
    ListItem('te', "Telugu"),
    ListItem('ur', "Urdu"),
  ];

  List<DropdownMenuItem<ListItem>> _dropdownMenuItems;
  ListItem _selectedItem;

  @override
  void initState() {
    super.initState();
    isSignedIn();
  }

  void isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();

    isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(currentUserId: prefs.getString('id'))),
      );
    }

    _dropdownMenuItems = buildDropDownMenuItems(_dropdownItems);
    _selectedItem = _dropdownMenuItems[0].value;

    if (SELECTED_LANGUAGE_CODE.isEmpty) {
      SELECTED_LANGUAGE_CODE = _selectedItem.langCode;
      print("DEFAULT LANGUAGE " + SELECTED_LANGUAGE_CODE);
    }

    this.setState(() {
      isLoading = false;
    });
  }

  List<DropdownMenuItem<ListItem>> buildDropDownMenuItems(List listItems) {
    List<DropdownMenuItem<ListItem>> items = List();
    for (ListItem listItem in listItems) {
      items.add(
        DropdownMenuItem(
          child: Text(listItem.langName),
          value: listItem,
        ),
      );

      print("LIST OF LANGUAGES " + listItem.langName + " " + listItem.langCode);
    }
    return items;
  }

  Future<Null> handleSignIn() async {
    prefs = await SharedPreferences.getInstance();

    this.setState(() {
      isLoading = true;
    });

    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    FirebaseUser firebaseUser = (await firebaseAuth.signInWithCredential(credential)).user;

    if (firebaseUser != null) {
      // Check is already sign up
      final QuerySnapshot result =
          await Firestore.instance.collection('users').where('id', isEqualTo: firebaseUser.uid).getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if (documents.length == 0) {
        // Update data to server if new user
        Firestore.instance.collection('users').document(firebaseUser.uid).setData({
          'nickname': firebaseUser.displayName,
          'photoUrl': firebaseUser.photoUrl,
          'userLang' : SELECTED_LANGUAGE_CODE,
          'id': firebaseUser.uid,
          'createdAt': DateTime.now().microsecondsSinceEpoch.toString(),
          'chattingWith': null
        });

        // Write data to local
        currentUser = firebaseUser;
        await prefs.setString('id', currentUser.uid);
        await prefs.setString('nickname', currentUser.displayName);
        await prefs.setString('photoUrl', currentUser.photoUrl);
//        await prefs.setString('userLang', currentUser.userLang);
      } else {
        // Write data to local
        await prefs.setString('id', documents[0]['id']);
        await prefs.setString('nickname', documents[0]['nickname']);
        await prefs.setString('photoUrl', documents[0]['photoUrl']);
        await prefs.setString('aboutMe', documents[0]['aboutMe']);
        await prefs.setString('userLang', documents[0]['userLang']);
      }
      FlutterToast(context).showToast(child: Text("Sign in success"));
      this.setState(() {
        isLoading = false;
      });

      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(currentUserId: firebaseUser.uid)));
    } else {
      FlutterToast(context).showToast(child: Text("Sign in failed"));
      this.setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Stack(
              children: <Widget>[
                Center(
                  child: FlatButton(
                        onPressed: handleSignIn,
                        child: Text(
                          'SIGN IN WITH GOOGLE',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        color: Color(0xffdd4b39),
                        highlightColor: Color(0xffff7f7f),
                        splashColor: Colors.transparent,
                        textColor: Colors.white,
                        padding: EdgeInsets.fromLTRB(30.0, 15.0, 30.0, 15.0)),
                ),
                DropdownButton<ListItem>(
                  value: _selectedItem,
                  items: _dropdownMenuItems,
                  onChanged: (value) {
                    setState(() {
                    _selectedItem = value;
                    SELECTED_LANGUAGE_CODE = _selectedItem.langCode;
                    print('SELECTED LANGUAGE ' + SELECTED_LANGUAGE_CODE);
                    });
                  }),

                // Loading
                Positioned(
                  child: isLoading ? const Loading() : Container(),
                ),
              ],
            ),
          );
  }
}