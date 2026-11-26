import 'package:excellium_core/excellium_core.dart';
import 'package:excellium_formula/excellium_formula.dart';

/// Crée le moteur de formules de l'application.
///
/// Avec `storage.dart`, c'est le seul endroit qui connaît un moteur concret.
/// Pour en changer, ou pour lui donner d'autres fonctions, on modifie cette
/// fonction ; le reste de l'application ne voit que l'interface
/// [FormulaEngine].
FormulaEngine createFormulaEngine() => ExcelliumFormulaEngine();
