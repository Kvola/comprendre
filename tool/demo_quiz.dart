// ignore_for_file: avoid_print
import 'dart:io';
import 'package:comprendre/engine/offline_quiz.dart';
import 'package:comprendre/engine/text_tools.dart';

void main(List<String> args) {
  final text = cleanText(File(args[0]).readAsStringSync());
  final quiz = OfflineQuizGenerator(text).generate();
  for (final q in quiz.questions) {
    print('[${q.skill}] ${q.question}');
    if (q.isTrueFalse) { print('  -> ${q.answer == 1 ? "VRAI" : "FAUX"}'); }
    for (var i = 0; i < q.choices.length; i++) { print('  ${i == q.answer ? "*" : " "} ${q.choices[i]}'); }
    print('');
  }
}
