import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:social_network_app/models/user.dart';
import 'package:social_network_app/screens/Notifications_page.dart';
import 'package:social_network_app/screens/Upload_page.dart';
import 'package:social_network_app/screens/chat_search_screen.dart';
import 'package:social_network_app/screens/create_account_page.dart';
import 'package:social_network_app/screens/profile_page.dart';
import 'package:social_network_app/screens/search_screen.dart';
import 'package:social_network_app/screens/time_line_screen.dart';

final GoogleSignIn gSignIn = GoogleSignIn();
final usersReference = Firestore.instance.collection("users");
final StorageReference storageReference = FirebaseStorage.instance.ref().child("Posts Pictures");
final postsReference = Firestore.instance.collection("posts");
final activityFeedReference = Firestore.instance.collection("feed");
final commentsReference = Firestore.instance.collection("comments");
final followersReference = Firestore.instance.collection("followers");
final followingReference = Firestore.instance.collection("following");
final timelineReference = Firestore.instance.collection("timeline");

final DateTime timestamp = DateTime.now();
User currentUser;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  bool isSignedIn = false;
  PageController pageController;
  int getPageIndex = 0;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // function for checking whether user is logged in or not
  void initState(){
    super.initState();

    pageController = PageController();

    gSignIn.onCurrentUserChanged.listen((gSignInAccount) {
      controlSignIn(gSignInAccount);
    }, onError: (gError){
      print("Error Message: " + gError);
    });

    gSignIn.signInSilently(suppressErrors: false).then((gSignInAccount){
      controlSignIn(gSignInAccount);
    }).catchError((gError){
      print("Error Message: " + gError);
    });
  }

  controlSignIn(GoogleSignInAccount signInAccount) async{
    if(signInAccount != null){

      await saveUserInfoToFireStore();

      setState(() {
        isSignedIn = true;
      });

      //configureRealTimePushNotifications();
    }
    else{
      setState(() {
        isSignedIn = false;
      });
    }
  }

  // configureRealTimePushNotifications(){
  //   final GoogleSignInAccount gUser = gSignIn.currentUser;
  //   if(Platform.isIOS){
  //     getIOSPermissions();
  //   }
  //
  //   _firebaseMessaging.getToken().then((token){
  //     usersReference.document(gUser.id).updateData({
  //       "androidNotificationToken": token,
  //     });
  //   });
  //
  //   _firebaseMessaging.configure(
  //     onMessage: (Map<String, dynamic> msg) async{
  //       final String recipientId = msg["data"]["recipient"];
  //       final String body = msg["notification"]["body"];
  //
  //       if(recipientId == gUser.id){
  //         SnackBar snackBar = SnackBar(
  //           backgroundColor: Colors.grey,
  //           content: Text(
  //             body,
  //             style: TextStyle(
  //               color: Colors.black,
  //             ),
  //             overflow: TextOverflow.ellipsis,
  //           ),
  //         );
  //         _scaffoldKey.currentState.showSnackBar(snackBar);
  //       }
  //     },
  //   );
  // }
  //
  // getIOSPermissions(){
  //   _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(alert: true, badge: true, sound: true));
  //
  //   _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
  //     print("Settings Registered: $settings");
  //   });
  // }

  saveUserInfoToFireStore() async{
    final GoogleSignInAccount gCurrentUser = gSignIn.currentUser;
    DocumentSnapshot documentSnapshot = await usersReference.document(gCurrentUser.id).get();

    if(!documentSnapshot.exists){
      final username = await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateAccountPage()));

      usersReference.document(gCurrentUser.id).setData({
        "id": gCurrentUser.id,
        "profileName": gCurrentUser.displayName,
        "username": username,
        "url": gCurrentUser.photoUrl,
        "email": gCurrentUser.email,
        "bio": "",
        "timestamp": timestamp,
        "chattingWith": null,
      });

      await followersReference.document(gCurrentUser.id).collection("userFollowers").document(gCurrentUser.id).setData({});

      documentSnapshot = await usersReference.document(gCurrentUser.id).get();
    }

    currentUser = User.fromDocument(documentSnapshot);
  }

  void dispose(){
    pageController.dispose();
    super.dispose();
  }

  loginUser(){
    gSignIn.signIn();
  }

  // logoutUser(){
  //   gSignIn.signOut();
  // }

  whenPageChanges(int pageIndex){
    setState(() {
      this.getPageIndex = pageIndex;
    });
  }

  onTapChangePage(int pageIndex){
    pageController.animateToPage(pageIndex, duration: Duration(milliseconds: 200), curve: Curves.bounceInOut);
  }

  Scaffold buildHomeScreen(){
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          TimeLinePage(gCurrentUser: currentUser,),
          // RaisedButton.icon(
          //   onPressed: logoutUser,
          //   icon: Icon(Icons.exit_to_app),
          //   label: Text("Sign Out"),
          // ),
          SearchScreen(),
          UploadPage(gCurrentUser: currentUser,),
          NotificationsPage(),
          ChatSearchScreen(gCurrentUser: currentUser?.id,),
          ProfilePage(userProfileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: whenPageChanges,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: getPageIndex,
        onTap: onTapChangePage,
        color: Colors.black45,
        backgroundColor: Colors.grey,
        buttonBackgroundColor: Colors.black,
        height: 55,
        items: <Widget>[
          Icon(Icons.home, size: 20, color: Colors.white,),
          Icon(Icons.search, size: 20, color: Colors.white,),
          Icon(Icons.photo_camera, size: 20, color: Colors.white,),
          Icon(Icons.favorite, size: 20, color: Colors.white,),
          Icon(Icons.offline_bolt, size: 20, color: Colors.white,),
          Icon(Icons.person, size: 20, color: Colors.white,),
        ],
      ),
    );
  }

  Scaffold buildSignInScreen(){
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Theme.of(context).accentColor, Theme.of(context).primaryColor],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Infinity",
              style: TextStyle(
                fontSize: 45.0,
                color: Colors.white,
                fontFamily: "Signatra"
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03,),
            Image.asset(
                "assets/images/login.png",
              height: MediaQuery.of(context).size.height * 0.4,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03,),
            GestureDetector(
              onTap: loginUser,
              child: Container(
                width: 270.0,
                height: 65.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/GoogleSignIn.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if(isSignedIn){
      return buildHomeScreen();
    }
    else{
      return buildSignInScreen();
    }
  }
}
