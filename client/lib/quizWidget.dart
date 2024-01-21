import 'package:flutter/material.dart';
import 'model.dart';

enum QuestionType { yesNo, singleSelect, multiSelect }

class QuizWidget extends StatefulWidget {
  @override
  _QuizWidgetState createState() => _QuizWidgetState();

  final Quiz quiz;

  QuizWidget({required this.quiz});
}

class _QuizWidgetState extends State<QuizWidget> {
  //List<Question> questions = [];
  final quizDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _addQuestion(QuestionType type) {
    Question newQuestion = Question('');
    newQuestion.type = type;
    switch (type) {
      case QuestionType.yesNo:
        newQuestion.answers = [Answer('Yes', true), Answer('No', false)];
        break;

      case QuestionType.singleSelect:
        newQuestion.answers = [Answer('', true), Answer('', false)];
        break;

      case QuestionType.multiSelect:
        newQuestion.answers = [Answer('', false), Answer('', false)];
        break;
    }
    setState(() {
      widget.quiz.questions.add(newQuestion);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. Editable Quiz Description
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: quizDescriptionController,
              onChanged: (value) => widget.quiz.description = value,
              decoration: InputDecoration(labelText: 'Quiz Description'),
            ),
          ),

          Column(
            children: List.generate(
              widget.quiz.questions.length,
              (questionIndex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Text
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller:
                                widget.quiz.questions[questionIndex].controller,
                            onChanged: (newText) {
                              widget.quiz.questions[questionIndex].text =
                                  newText;
                            },
                            decoration: InputDecoration(labelText: 'Question'),
                          ),
                        ),
                      ),

                      // Answers List
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var answer in widget
                                  .quiz.questions[questionIndex].answers)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: answer.controller,
                                          onChanged: (newText) {
                                            answer.text = newText;
                                          },
                                          decoration: InputDecoration(
                                              labelText: 'Answer'),
                                        ),
                                      ),
                                      if (widget.quiz.questions[questionIndex]
                                              .type ==
                                          QuestionType.singleSelect)
                                        Radio(
                                          value: answer,
                                          groupValue: widget.quiz
                                              .questions[questionIndex].answers
                                              .firstWhere((ans) => ans.correct,
                                                  orElse: () {
                                            widget.quiz.questions[questionIndex]
                                                .answers.first.correct = true;
                                            return widget
                                                .quiz
                                                .questions[questionIndex]
                                                .answers
                                                .first;
                                          }),
                                          onChanged: (newValue) {
                                            setState(() {
                                              widget
                                                  .quiz
                                                  .questions[questionIndex]
                                                  .answers
                                                  .forEach((ans) =>
                                                      ans.correct = false);
                                              (newValue as Answer).correct =
                                                  true;
                                            });
                                          },
                                        )
                                      else if (widget.quiz
                                              .questions[questionIndex].type ==
                                          QuestionType.multiSelect)
                                        Checkbox(
                                          value: answer.correct,
                                          onChanged: (bool? newValue) {
                                            setState(() {
                                              answer.correct = newValue!;
                                            });
                                          },
                                        )
                                      else if (widget.quiz
                                              .questions[questionIndex].type ==
                                          QuestionType.yesNo)
                                        Radio(
                                          value: answer,
                                          groupValue: widget.quiz
                                              .questions[questionIndex].answers
                                              .firstWhere((ans) => ans.correct,
                                                  orElse: () {
                                            widget.quiz.questions[questionIndex]
                                                .answers.first.correct = true;
                                            return widget
                                                .quiz
                                                .questions[questionIndex]
                                                .answers
                                                .first;
                                          }),
                                          onChanged: (newValue) {
                                            setState(() {
                                              widget
                                                  .quiz
                                                  .questions[questionIndex]
                                                  .answers
                                                  .forEach((ans) =>
                                                      ans.correct = false);
                                              (newValue as Answer).correct =
                                                  true;
                                            });
                                          },
                                        ),
                                      if (widget.quiz.questions[questionIndex]
                                              .answers.length >
                                          2)
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            setState(() {
                                              widget
                                                  .quiz
                                                  .questions[questionIndex]
                                                  .answers
                                                  .remove(answer);
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              if ((widget.quiz.questions[questionIndex].type ==
                                          QuestionType.singleSelect ||
                                      widget.quiz.questions[questionIndex]
                                              .type ==
                                          QuestionType.multiSelect) &&
                                  widget.quiz.questions[questionIndex].answers
                                          .length <
                                      5)
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      widget
                                          .quiz.questions[questionIndex].answers
                                          .add(Answer('', false));
                                    });
                                  },
                                  child: Text('Add Answer'),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Delete Question Button
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: widget.quiz.questions.length > 1
                              ? TextButton(
                                  onPressed: () {
                                    setState(() {
                                      widget.quiz.questions
                                          .removeAt(questionIndex);
                                    });
                                  },
                                  child: Text('Delete Question'),
                                )
                              : Container(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Add Question Button
          if (widget.quiz.questions.length < 10)
            DropdownButton<QuestionType>(
              hint: Text("Add question"),
              items: <DropdownMenuItem<QuestionType>>[
                DropdownMenuItem<QuestionType>(
                  value: QuestionType.yesNo,
                  child: Text('Yes/No'),
                ),
                DropdownMenuItem<QuestionType>(
                  value: QuestionType.singleSelect,
                  child: Text('Single Choice'),
                ),
                DropdownMenuItem<QuestionType>(
                  value: QuestionType.multiSelect,
                  child: Text('Multi Choice'),
                ),
              ],
              onChanged: (QuestionType? newValue) {
                if (newValue != null) {
                  _addQuestion(newValue);
                }
              },
            ),
        ],
      ),
    );
  }
}
