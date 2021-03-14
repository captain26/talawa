import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talawa/controllers/auth_controller.dart';
import 'dart:io';
import 'package:talawa/services/Queries.dart';
import 'package:talawa/utils/GQLClient.dart';
import 'package:talawa/utils/uidata.dart';
import 'package:talawa/utils/validator.dart';
import 'package:talawa/view_models/vm_register.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:talawa/services/preferences.dart';
import 'package:talawa/model/token.dart';
import 'package:talawa/views/pages/organization/join_organization.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:graphql/utilities.dart' show multipartFileFrom;
import 'package:file_picker/file_picker.dart';

import 'package:image_picker/image_picker.dart';
import 'package:flutter_password_strength/flutter_password_strength.dart';

class RegisterForm extends StatefulWidget {
  @override
  RegisterFormState createState() {
    return RegisterFormState();
  }
}

class RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = new TextEditingController();
  TextEditingController originalPassword = new TextEditingController();
  RegisterViewModel model = new RegisterViewModel();
  bool _progressBarState = false;
  Queries _signupQuery = Queries();
  bool _validate = false;
  Preferences _pref = Preferences();
  FToast fToast;
  GraphQLConfiguration graphQLConfiguration = GraphQLConfiguration();
  File _image;
  AuthController _authController = AuthController();
  bool _obscureText = true;

  void toggleProgressBarState() {
    _progressBarState = !_progressBarState;
  }

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    fToast.init(context);
    Provider.of<GraphQLConfiguration>(context, listen: false).getOrgUrl();
  }

  //function for registering user which gets called when sign up is press
  registerUser() async {
    GraphQLClient _client = graphQLConfiguration.clientToQuery();
    final img = await multipartFileFrom(_image);
    print(_image);
    QueryResult result = await _client.mutate(MutationOptions(

      documentNode: gql(_signupQuery.registerUser(
          model.firstName, model.lastName, model.email, model.password)),
      variables: {
        'file': img,
      },
    ));
    if (result.hasException) {
      print(result.exception);
      setState(() {
        _progressBarState = false;
      });
      _exceptionToast(result.exception.toString().substring(16));
    } else if (!result.hasException && !result.loading) {
      setState(() {
        _progressBarState = true;
      });

      final String userFName = result.data['signUp']['user']['firstName'];
      await _pref.saveUserFName(userFName);
      final String userLName = result.data['signUp']['user']['lastName'];
      await _pref.saveUserLName(userLName);

      final Token accessToken =
          new Token(tokenString: result.data['signUp']['accessToken']);
      await _pref.saveToken(accessToken);
      final Token refreshToken =
          new Token(tokenString: result.data['signUp']['refreshToken']);
      await _pref.saveRefreshToken(refreshToken);
      final String currentUserId = result.data['signUp']['user']['_id'];
      await _pref.saveUserId(currentUserId);
      //Navigate user to join organization screen
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => new JoinOrganization()));
    }
  }

  registerUserWithoutImg() async {
    GraphQLClient _client = graphQLConfiguration.clientToQuery();
    QueryResult result = await _client.mutate(MutationOptions(
      documentNode: gql(_signupQuery.registerUserWithoutImg(
          model.firstName, model.lastName, model.email, model.password)),
    ));
    if (result.hasException) {
      print(result.exception);
      setState(() {
        _progressBarState = false;
      });
      _exceptionToast(result.exception.toString().substring(16));
    } else if (!result.hasException && !result.loading) {
      setState(() {
        _progressBarState = true;
      });

      final String userFName = result.data['signUp']['user']['firstName'];
      await _pref.saveUserFName(userFName);
      final String userLName = result.data['signUp']['user']['lastName'];
      await _pref.saveUserLName(userLName);
      final Token accessToken =
          new Token(tokenString: result.data['signUp']['accessToken']);
      await _pref.saveToken(accessToken);
      final Token refreshToken =
          new Token(tokenString: result.data['signUp']['refreshToken']);
      await _pref.saveRefreshToken(refreshToken);
      final String currentUserId = result.data['signUp']['user']['_id'];
      await _pref.saveUserId(currentUserId);

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => new JoinOrganization()));
    }
  }

  //get image using camera
  _imgFromCamera() async {
    File image = await ImagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 50
    );

    setState(() {
      _image = image;
    });
  }

  //get image using gallery
  _imgFromGallery() async {
    File image = File((await FilePicker.platform.pickFiles(type: FileType.image)).files.first.path);
    setState(() {
      _image = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        autovalidate: _validate,
        child: Column(
          children: <Widget>[
            addImage(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Add Profile Image',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            SizedBox(
              height: 25,
            ),
            AutofillGroup(
              child : Column(
    children :  <Widget>[
                TextFormField(
                  autofillHints: <String>[AutofillHints.name] ,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => Validator.validateFirstName(value),
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                    border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(20.0)),
                prefixIcon: Icon(Icons.person),
                labelText: "First Name",
                labelStyle: TextStyle(color: Colors.white),
                alignLabelWithHint: true,
                hintText: 'Earl',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onSaved: (value) {
                model.firstName = value;
              },
            ),
            SizedBox(
              height: 20,
            ),
            TextFormField(
              autofillHints: <String>[AutofillHints.name] ,
              textCapitalization: TextCapitalization.words,
              validator: (value) => Validator.validateLastName(value),
              textAlign: TextAlign.left,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(20.0)),
                prefixIcon: Icon(Icons.person),
                labelText: "Last Name",
                labelStyle: TextStyle(color: Colors.white),
                alignLabelWithHint: true,
                hintText: 'John',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onSaved: (value) {
                model.lastName = value;
              },
            ),
            SizedBox(
              height: 20,
            ),
            TextFormField(
              autofillHints: <String>[AutofillHints.email] ,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => Validator.validateEmail(value),
              controller: emailController,
              textAlign: TextAlign.left,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(20.0)),
                prefixIcon: Icon(Icons.email),
                labelText: "Email",
                labelStyle: TextStyle(color: Colors.white),
                alignLabelWithHint: true,
                hintText: 'foo@bar.com',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onSaved: (value) {
                model.email = value;
              },
            ),
            SizedBox(
              height: 20,
            ),
            TextFormField(
              autofillHints: <String>[AutofillHints.password],
              obscureText: _obscureText,
              controller: originalPassword,
              validator: (value) => Validator.validatePassword(value),
              textAlign: TextAlign.left,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(20.0)),
                prefixIcon: Icon(Icons.lock),
                suffixIcon: FlatButton(
                  onPressed: _toggle,
                  child: Icon(_obscureText
                      ? Icons.visibility_off
                      : Icons.visibility),
                ),
                labelText: "Password",
                labelStyle: TextStyle(color: Colors.white),
                focusColor: UIData.primaryColor,
                alignLabelWithHint: true,
                hintText: 'password',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onSaved: (value) {
                model.password = value;
              },
            ),
                SizedBox(
                  height: 20,
                ),
                FlutterPasswordStrength(
                password: originalPassword.text,
                height: 10,
                radius: 10,
                strengthCallback: (strength){
                debugPrint(strength.toString());
              }
                ),
                  SizedBox(
              height: 20,
            ),
            TextFormField(
              autofillHints: <String>[AutofillHints.password] ,
              obscureText: true,
              validator: (value) => Validator.validatePasswordConfirm(
                  originalPassword.text, value),
              textAlign: TextAlign.left,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(20.0)),
                prefixIcon: Icon(Icons.lock),
                labelText: "Confirm Password",
                labelStyle: TextStyle(color: Colors.white),
                focusColor: UIData.primaryColor,
              ),
            ),
            SizedBox(
              height: 20,
            ),
              ],
            ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
              width: double.infinity,
              child: RaisedButton(
                padding: EdgeInsets.all(12.0),
                shape: StadiumBorder(),
                child: _progressBarState
                    ? const CircularProgressIndicator()
                    : Text(
                        "SIGN UP",
                      ),
                color: Colors.white,
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  _validate = true;
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();
                    _image != null
                        ? registerUser()
                        : registerUserWithoutImg();

                    setState(() {
                      toggleProgressBarState();
                    });
                  }
                },
              ),
            ),
          ],
        )));
  }

  Widget addImage() {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 32,
        ),
        Center(
          child: GestureDetector(
            onTap: () {
              _showPicker(context);
            },
            child: CircleAvatar(
              radius: 55,
              backgroundColor: UIData.secondaryColor,
              child: _image != null
                  ? CircleAvatar(
                      radius: 52,
                      backgroundImage: FileImage(
                        _image,
                      ),
                    )
                  : CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.lightBlue[50],
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.grey[800],
                      ),
                    ),
            ),
          ),
        )
      ],
    );
  }

  void _showPicker(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Container(
              child: Wrap(
                children: <Widget>[
                  ListTile(

                    leading: Icon(Icons.camera_alt_outlined),
                    title: Text('Camera'),
                    onTap: () {
                      _imgFromCamera();
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                      leading: Icon(Icons.photo_library),
                      title: Text('Photo Library'),
                      onTap: () {
                        _imgFromGallery();
                        Navigator.of(context).pop();
                      }),
                ],
              ),
            ),
          );
        });
  }

  _successToast(String msg) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.green,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(msg),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(seconds: 3),
    );
  }

  _exceptionToast(String msg) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.red,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(msg),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(seconds: 5),
    );
  }

  //function toggles _obscureText value
  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }
}
