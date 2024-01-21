import 'package:client/quizWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

final _auth = FirebaseAuth.instance;

String generateRandomCode(int length) {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  Random rnd = Random();
  return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
}

class Answer {
  String text;
  bool correct;
  TextEditingController controller;

  Answer(this.text, this.correct)
      : controller = TextEditingController(text: text);

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'correct': correct,
    };
  }

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(json['text'], json['correct']);
  }
}

class Question {
  QuestionType type = QuestionType.yesNo;
  String text;
  TextEditingController controller;
  List<Answer> answers = <Answer>[];

  Question(this.text) : controller = TextEditingController(text: text);

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'text': text,
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    Question q = Question(json['text']);
    if ("QuestionType.multiSelect" == json['type'])
      q.type = QuestionType.multiSelect;
    else if ("QuestionType.singleSelect" == json['type'])
      q.type = QuestionType.singleSelect;
    else
      q.type = QuestionType.yesNo;

    q.answers = (json['answers'] as List)
        .map((answer) => Answer.fromJson(answer))
        .toList();
    return q;
  }
}

class Quiz {
  String description = "";
  List<Question> questions = <Question>[];
  String permaUrl = "";

  Quiz() {
    // Sample Data
    description = "";
    permaUrl = generateRandomCode(6);
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': _auth.currentUser!.uid,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'permaUrl': permaUrl,
    };
  }

  factory Quiz.fromJson(Map<String, dynamic> json) {
    Quiz q = Quiz();
    q.description = json['description'];
    q.questions = (json['questions'] as List)
        .map((question) => Question.fromJson(question))
        .toList();
    q.permaUrl = json['permaUrl'];
    return q;
  }

  String? validateQuiz() {
    if (description.trim().isEmpty) {
      return 'Quiz description is not filled.';
    }

    if (0 == questions.length) {
      return 'Quiz must have at least 1 question.';
    }

    int questionIndex = 1; // To display question number in the error message

    for (var question in questions) {
      if (question.text.trim().isEmpty) {
        return 'The text for Question $questionIndex is not filled.';
      }

      bool hasCorrectAnswer = false;
      int answerIndex = 1; // To display answer number in the error message

      for (var answer in question.answers) {
        if (answer.text.trim().isEmpty) {
          return 'The text for Answer $answerIndex of Question $questionIndex is not filled.';
        }

        if (answer.correct) {
          hasCorrectAnswer = true;
        }
        answerIndex++;
      }

      if (!hasCorrectAnswer && (question.type != QuestionType.multiSelect)) {
        return 'No correct answer is marked for Question $questionIndex.';
      }

      questionIndex++;
    }

    return null; // No errors found
  }
}
