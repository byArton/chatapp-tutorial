//ログイン画面を作成
import 'package:chat/chatroom_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _loginAndAddUser(BuildContext context) async {
    try {
      // Googleサインインを開始
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // ユーザーがサインインをキャンセルした場合
        return;
      }

      // Googleサインインから認証情報を取得
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // FirebaseでGoogleの認証情報を使用してサインイン
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Firestoreでユーザーが存在するか確認
        final userQuery = await _firestore
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .get();

        if (userQuery.docs.isEmpty) {
          // ユーザーが存在しない場合、新しいユーザーを追加
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'name': user.displayName ?? 'User',
            // 他の必要なフィールドを追加
          });

          // chatroom_list_screenに遷移

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ChatRoomListScreen()),
          );
        } else {
          print('ユーザーは既に存在します: ${user.uid}');
        }
      }
    } catch (e) {
      print('ログインエラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ログインに失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => _loginAndAddUser(context),
          child: Text('Googleでログイン'),
        ),
      ),
    );
  }
}
