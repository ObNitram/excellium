import 'package:excellium_core/excellium_core.dart';

/// Lève une erreur de formule ; le moteur la convertit en `FormulaFailure`.
final class FormulaException implements Exception {
  const FormulaException(this.error);

  final FormulaError error;
}

Never fail(FormulaErrorCode code, [String detail = '']) =>
    throw FormulaException(FormulaError(code, detail));

enum TokenKind {
  number,
  name,
  plus,
  minus,
  times,
  divide,
  open,
  close,
  separator,
}

final class Token {
  const Token(
    this.kind,
    this.start,
    this.end, {
    this.number = 0,
    this.text = '',
  });

  final TokenKind kind;

  /// Position dans le texte de la formule.
  final int start;
  final int end;
  final double number;

  /// Nom de colonne ou de fonction, sans ses crochets.
  final String text;
}

/// Arbre d'une formule.
sealed class Node {
  const Node(this.start, this.end);

  /// Portion du texte dont le nœud est issu, pour étiqueter un résultat.
  final int start;
  final int end;
}

final class NumberNode extends Node {
  const NumberNode(this.value, super.start, super.end);

  final double value;
}

/// Un nom de colonne.
final class NameNode extends Node {
  const NameNode(this.name, super.start, super.end);

  final String name;
}

final class NegateNode extends Node {
  const NegateNode(this.operand, super.start, super.end);

  final Node operand;
}

final class BinaryNode extends Node {
  const BinaryNode(
    this.operator,
    this.left,
    this.right,
    super.start,
    super.end,
  );

  final TokenKind operator;
  final Node left;
  final Node right;
}

final class CallNode extends Node {
  const CallNode(this.function, this.arguments, super.start, super.end);

  final String function;
  final List<Node> arguments;
}

final _number = RegExp(r'\d+(?:[.,]\d+)?');
final _name = RegExp(r'[\p{L}_][\p{L}\p{N}_]*', unicode: true);
final _space = RegExp(r'\s');

const _symbols = {
  '+': TokenKind.plus,
  '-': TokenKind.minus,
  '−': TokenKind.minus,
  '*': TokenKind.times,
  '×': TokenKind.times,
  '/': TokenKind.divide,
  '÷': TokenKind.divide,
  '(': TokenKind.open,
  ')': TokenKind.close,
  ';': TokenKind.separator,
};

/// Découpe le texte en éléments. La virgule est le séparateur décimal ; un
/// nom de colonne avec des espaces s'écrit entre crochets.
List<Token> tokenize(String source) {
  final tokens = <Token>[];
  var index = 0;
  while (index < source.length) {
    final char = source[index];
    if (_space.hasMatch(char)) {
      index++;
      continue;
    }
    final number = _number.matchAsPrefix(source, index);
    if (number != null) {
      tokens.add(
        Token(
          TokenKind.number,
          index,
          number.end,
          number: double.parse(number[0]!.replaceAll(',', '.')),
        ),
      );
      index = number.end;
      continue;
    }
    if (char == '[') {
      final close = source.indexOf(']', index);
      if (close < 0) fail(FormulaErrorCode.missingBracket);
      tokens.add(
        Token(
          TokenKind.name,
          index,
          close + 1,
          text: source.substring(index + 1, close).trim(),
        ),
      );
      index = close + 1;
      continue;
    }
    final symbol = _symbols[char];
    if (symbol != null) {
      tokens.add(Token(symbol, index, index + 1));
      index++;
      continue;
    }
    final name = _name.matchAsPrefix(source, index);
    if (name != null) {
      tokens.add(Token(TokenKind.name, index, name.end, text: name[0]!));
      index = name.end;
      continue;
    }
    fail(FormulaErrorCode.unexpectedCharacter, char);
  }
  return tokens;
}

/// Construit l'arbre d'une formule.
///
/// ```
/// expression := terme (('+' | '-') terme)*
/// terme      := facteur (('×' | '/') facteur)*
/// facteur    := '-' facteur | nombre | nom | nom '(' arguments ')' | '(' expression ')'
/// arguments  := expression (';' expression)*
/// ```
final class Parser {
  Parser(this._source, this._tokens);

  final String _source;
  final List<Token> _tokens;
  int _position = 0;

  Token? get _current => _position < _tokens.length ? _tokens[_position] : null;

  bool _at(TokenKind kind) => _current?.kind == kind;

  Node parse() {
    final node = _expression();
    final rest = _current;
    if (rest != null) {
      if (rest.kind == TokenKind.separator) {
        fail(FormulaErrorCode.strayArgumentSeparator);
      }
      fail(
        FormulaErrorCode.unexpectedToken,
        _source.substring(rest.start, rest.end),
      );
    }
    return node;
  }

  Node _expression() {
    var left = _term();
    while (_at(TokenKind.plus) || _at(TokenKind.minus)) {
      final operator = _tokens[_position++].kind;
      final right = _term();
      left = BinaryNode(operator, left, right, left.start, right.end);
    }
    return left;
  }

  Node _term() {
    var left = _factor();
    while (_at(TokenKind.times) || _at(TokenKind.divide)) {
      final operator = _tokens[_position++].kind;
      final right = _factor();
      left = BinaryNode(operator, left, right, left.start, right.end);
    }
    return left;
  }

  Node _factor() {
    final token = _current;
    if (token == null) fail(FormulaErrorCode.incomplete);
    switch (token.kind) {
      case TokenKind.minus:
        _position++;
        final operand = _factor();
        return NegateNode(operand, token.start, operand.end);

      case TokenKind.number:
        _position++;
        return NumberNode(token.number, token.start, token.end);

      case TokenKind.open:
        _position++;
        final inner = _expression();
        _closing();
        return inner;

      case TokenKind.name:
        _position++;
        if (!_at(TokenKind.open)) {
          return NameNode(token.text, token.start, token.end);
        }
        _position++;
        final arguments = <Node>[_expression()];
        while (_at(TokenKind.separator)) {
          _position++;
          arguments.add(_expression());
        }
        final end = _closing();
        return CallNode(token.text, arguments, token.start, end);

      case TokenKind.plus:
      case TokenKind.times:
      case TokenKind.divide:
      case TokenKind.close:
      case TokenKind.separator:
        fail(
          FormulaErrorCode.unexpectedToken,
          _source.substring(token.start, token.end),
        );
    }
  }

  /// Consomme la parenthèse fermante et rend sa position de fin.
  int _closing() {
    final token = _current;
    if (token == null || token.kind != TokenKind.close) {
      fail(FormulaErrorCode.missingParenthesis);
    }
    _position++;
    return token.end;
  }
}
