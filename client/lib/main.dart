import 'dart:convert';

import 'package:client/model.dart';
import 'package:client/quizTaker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'quizWidget.dart';
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await loadConfig();
  runApp(MyApp(serverUrl: config['serverUrl']));
}

Future<Map<String, dynamic>> loadConfig() async {
  final configString = await rootBundle.loadString('assets/config.json');
  return jsonDecode(configString);
}

class MyApp extends StatelessWidget {
  final String serverUrl;
  final Future<FirebaseApp> _initialization;

  MyApp({required this.serverUrl})
      : _initialization = Firebase.initializeApp(
            options: FirebaseOptions(
          apiKey: config['apiKey'],
          authDomain: config['authDomain'],
          projectId: config['projectId'],
          storageBucket: config['storageBucket'],
          messagingSenderId: config['messagingSenderId'],
          appId: config['appId'],
        ));

  @override
  Widget build(BuildContext context) {
    final Uri uri = Uri.parse(html.window.location.href);
    return MaterialApp(
      initialRoute: '/',
      title: 'Quiz Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/': (context) => FutureBuilder(
              future: _initialization,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Scaffold(
                    body: Center(child: Text('Error initializing Firebase')),
                  );
                }
                if (snapshot.connectionState == ConnectionState.done) {
                  return QuizPage(
                      parameters: uri.queryParameters, serverUrl: serverUrl);
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
      },
    );
  }
}

class QuizPage extends StatefulWidget {
  @override
  final Map<String, String>? parameters;
  final String serverUrl;

  QuizPage({required this.serverUrl, this.parameters});

  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final _auth = FirebaseAuth.instance;
  String email = '';
  String password = '';
  bool isUserSignedIn = false;
  bool isCreatingQuiz = false;
  bool isLoading = true;
  bool isQuizTakerMode = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  Quiz? _quiz = null;
  List<dynamic> quizzes = [];

  @override
  void initState() {
    super.initState();
    if (widget.parameters?.containsKey('quiz') ?? false) {
      isQuizTakerMode = true;
      _fetchQuiz(widget.parameters!['quiz'] ?? '');
    } else {
      _fetchQuizzes();
    }
  }

  Future<void> _signUp() async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      setState(() {
        isUserSignedIn = true;
      });
    } catch (e) {
      print(e);
      _showSnackBar(e.toString());
    }
  }

  Future<void> _signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      setState(() {
        isUserSignedIn = true;
        _fetchQuizzes();
      });
    } catch (e) {
      print(e);
      _showSnackBar(e.toString());
    }
  }

  Future<void> _logOff() async {
    try {
      await _auth.signOut();
      setState(() {
        isUserSignedIn = false;
        isCreatingQuiz = false;
        _quiz = null;
        email = "";
        password = "";
        quizzes = [];
      });
    } catch (e) {
      print(e);
      _showSnackBar(e.toString());
    }
  }

  Future<void> _accessProtectedResource() async {
    try {
      var idToken = await _auth.currentUser!.getIdToken();
      var response = await http.post(
        Uri.parse(widget.serverUrl + 'create_quiz'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'uid': _auth.currentUser!.uid,
        }),
      );
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  void _showSnackBar(String text) {
    _scaffoldMessengerKey.currentState!.showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _handlePublish() async {
    String? _error = _quiz!.validateQuiz();
    if (null == _error) {
      var idToken = await _auth.currentUser!.getIdToken();
      var response = await http.post(
        Uri.parse(widget.serverUrl + 'create_quiz'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(_quiz!.toJson()),
      );
      if (response.statusCode == 200) {
        setState(() {
          // reload quizes
          isCreatingQuiz = false;
          _fetchQuizzes();
        });
      } else {
        _showSnackBar(response.body);
      }
    } else {
      _showSnackBar(_error);
    }
  }

  Future<void> _fetchQuiz(String permaUrl) async {
    if (permaUrl.isEmpty) return;
    try {
      var response = await http.get(
        Uri.parse(widget.serverUrl + 'get_quiz/' + permaUrl),
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _quiz = Quiz.fromJson(data['quiz']);
          isLoading = false;
        });
      } else {
        isLoading = false;
        _showSnackBar("Error fetching quizzes: ${response.body}");
      }
    } catch (e) {
      isLoading = false;
      _showSnackBar("Exception fetching quizzes: $e");
    }
  }

  Future<void> _fetchQuizzes() async {
    isUserSignedIn = _auth.currentUser != null;
    if (!isUserSignedIn) return;
    var idToken = await _auth.currentUser!.getIdToken();
    try {
      var response = await http.get(
        Uri.parse(widget.serverUrl + 'get_quizzes'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          quizzes = data['quizzes'];
        });
      } else {
        _showSnackBar("Error fetching quizzes: ${response.body}");
      }
    } catch (e) {
      _showSnackBar("Exception fetching quizzes: $e");
    }
  }

  void _deleteQuiz(String id) async {
    isUserSignedIn = _auth.currentUser != null;
    if (!isUserSignedIn) return;
    var idToken = await _auth.currentUser!.getIdToken();
    try {
      var response = await http.delete(
        Uri.parse(widget.serverUrl + 'delete_quiz/' + id),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _fetchQuizzes();
        });
      } else {
        _showSnackBar("Error deleting quiz: ${response.body}");
      }
    } catch (e) {
      _showSnackBar("Exception deleting quiz: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isQuizTakerMode) {
      isUserSignedIn = _auth.currentUser != null;
      return ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!isUserSignedIn)
                    // First Row: Input fields
                    if (!isUserSignedIn)
                      Row(
                        children: [
                          Flexible(
                            child: TextField(
                              onChanged: (value) => email = value,
                              decoration: InputDecoration(labelText: 'Email'),
                            ),
                          ),
                          SizedBox(width: 16),
                          Flexible(
                            child: TextField(
                              onChanged: (value) => password = value,
                              obscureText: true,
                              decoration:
                                  InputDecoration(labelText: 'Password'),
                            ),
                          ),
                          SizedBox(width: 16),
                        ],
                      ),

                  SizedBox(height: 20), // Adds space between the rows

                  // Second Row: Buttons and signed user email
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    // Centers the children horizontally
                    children: [
                      if (isUserSignedIn) ...[
                        Text(
                          email,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 16),
                      ],
                      if (!isUserSignedIn) ...[
                        ElevatedButton(
                            onPressed: _signIn, child: Text('Sign In')),
                        SizedBox(width: 16),
                        ElevatedButton(
                            onPressed: _signUp, child: Text('Sign Up')),
                        SizedBox(width: 16),
                      ],
                      if (isUserSignedIn) ...[
                        ElevatedButton(
                            onPressed: _logOff, child: Text('Log Off')),
                      ],
                    ],
                  ),

                  SizedBox(height: 16),

                  // user's quizzes
                  if (isUserSignedIn) ...[
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My quizzes',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10), // optional spacing
                          ...List.generate(
                            quizzes.length,
                            (index) => ListTile(
                              title: Text(quizzes[index]['description']),
                              onTap: () {
                                final String paramValue =
                                    quizzes[index]['permaUrl'];
                                final currentUrl =
                                    html.window.location.href.split('?').first;
                                html.window.location
                                    .assign('$currentUrl?quiz=$paramValue');
                              },
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.content_copy),
                                    // This icon represents "copy" action in Material design
                                    onPressed: () {
                                      final String paramValue =
                                          quizzes[index]['permaUrl'];
                                      final currentUrl = html
                                          .window.location.href
                                          .split('?')
                                          .first;
                                      final linkToCopy =
                                          '$currentUrl?quiz=$paramValue';

                                      Clipboard.setData(
                                          ClipboardData(text: linkToCopy));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Link Copied to Clipboard!')),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      _deleteQuiz(quizzes[index]['id']);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // user's quizzes

                  if (isCreatingQuiz) ...[
                    Expanded(
                      child: QuizWidget(quiz: _quiz!),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isCreatingQuiz = false;
                              _quiz = new Quiz();
                            });
                          },
                          child: Text('Discard quiz'),
                        ),
                        ElevatedButton(
                          onPressed: _handlePublish,
                          child: Text('Publish Quiz'),
                        ),
                      ],
                    ),
                  ],
                  if (isUserSignedIn && !isCreatingQuiz) ...[
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _quiz = new Quiz();
                            isCreatingQuiz = true;
                          });
                        },
                        child: Text('Create new quiz'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // here comes quiz taking
      if (isLoading) {
        return Center(child: CircularProgressIndicator());
      } else if (null != _quiz) {
        return TakeQuizWidget(quiz: _quiz!);
      } else {
        return Center(child: Text('Quiz not found'));
      }
    }
  }
}
