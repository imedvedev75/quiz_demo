import 'package:flutter/material.dart';
import 'model.dart';
import 'dart:html' as html;


class TakeQuizWidget extends StatefulWidget {
  final Quiz quiz;

  TakeQuizWidget({required this.quiz});

  @override
  _TakeQuizState createState() => _TakeQuizState();
}

class _TakeQuizState extends State<TakeQuizWidget> {
  int currentQuestionIndex = 0;
  int score = 0;
  bool quizComplete = false;

  List<bool> selectedAnswers = [];

  @override
  void initState() {
    super.initState();
    selectedAnswers = List.generate(
      widget.quiz.questions[currentQuestionIndex].answers.length,
      (index) => false,
    );
  }

  void submitAnswer() {
    var currentQuestion = widget.quiz.questions[currentQuestionIndex];
    bool correct = true;

    for (int i = 0; i < currentQuestion.answers.length; i++) {
      if (selectedAnswers[i] != currentQuestion.answers[i].correct) {
        correct = false;
        break;
      }
    }

    if (correct) {
      score++;
    }

    if (currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswers = List.generate(
          widget.quiz.questions[currentQuestionIndex].answers.length,
          (index) => false,
        );
      });
    } else {
      setState(() {
        quizComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var currentQuestion = widget.quiz.questions[currentQuestionIndex];

    bool isMultiAnswer =
        currentQuestion.answers.where((answer) => answer.correct).length > 1;

    if (quizComplete) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz Completed!'),
          actions: [
            ElevatedButton(
              child: Text('Home'),
              onPressed: () {
                final currentUrl = html.window.location.href.split('?').first;
                html.window.location.assign(currentUrl); // Navigates to the main page without any query parameters
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.white, // This is the background color
                onPrimary: Colors.black, // This is the text color
              ),
            ),
          ],
        ),
        body: Center(
          child: Text('You scored $score/${widget.quiz.questions.length}!',
              style: TextStyle(fontSize: 24)),
        ),
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: Text('Take Quiz'),
        actions: [
          ElevatedButton(
            child: Text('Home'),
            onPressed: () {
              final currentUrl = html.window.location.href.split('?').first;
              html.window.location.assign(currentUrl); // Navigates to the main page without any query parameters
            },
            style: ElevatedButton.styleFrom(
              primary: Colors.white, // This is the background color
              onPrimary: Colors.black, // This is the text color
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(currentQuestion.text, style: TextStyle(fontSize: 24)),
            Expanded(
              child: ListView.builder(
                itemCount: currentQuestion.answers.length,
                itemBuilder: (context, index) {
                  if (isMultiAnswer) {
                    return CheckboxListTile(
                      title: Text(currentQuestion.answers[index].text),
                      value: selectedAnswers[index],
                      onChanged: (value) {
                        setState(() {
                          selectedAnswers[index] = value!;
                        });
                      },
                    );
                  } else {
                    return RadioListTile<bool>(
                      title: Text(currentQuestion.answers[index].text),
                      value: true,
                      groupValue: selectedAnswers[index],
                      onChanged: (value) {
                        setState(() {
                          selectedAnswers = List.generate(
                              selectedAnswers.length, (index) => false);
                          selectedAnswers[index] = true;
                        });
                      },
                    );
                  }
                },
              ),
            ),
            ElevatedButton(
                onPressed: submitAnswer, child: Text('Submit Answer')),
          ],
        ),
      ),
    );
  }
}
