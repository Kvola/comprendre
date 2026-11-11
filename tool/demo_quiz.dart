// ignore_for_file: avoid_print
// Affiche le quiz hors ligne d'un fichier texte :  dart run tool/demo_quiz.dart texte.txt [graine]
import 'dart:io';

import 'package:comprendre/engine/offline_quiz.dart';
import 'package:comprendre/engine/text_tools.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage : dart run tool/demo_quiz.dart texte.txt [graine]');
    exit(64);
  }
  final text = cleanText(File(args[0]).readAsStringSync());
  final seed = args.length > 1 ? int.tryParse(args[1]) : null;
  print('Langue détectée : ${detectLanguage(text)}\n');
  try {
    final quiz = OfflineQuizGenerator(text, seed: seed).generate();
    for (final q in quiz.questions) {
      print('[${q.skill}] ${q.question}');
      if (q.isTrueFalse) print('  -> ${q.answer == 1 ? "VRAI" : "FAUX"}');
      for (var i = 0; i < q.choices.length; i++) {
        print('  ${i == q.answer ? "*" : " "} ${q.choices[i]}');
      }
      print('');
    }
  } on OfflineQuizException catch (e) {
    print(switch (e.reason) {
      'language' => 'Pas de quiz hors ligne dans cette langue (français et anglais seulement) : l’IA est nécessaire.',
      _ => 'Texte trop court ou trop pauvre pour un quiz.',
    });
    exit(1);
  }
}
