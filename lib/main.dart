import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Калькулятор',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _result = '';
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Автоматически фокусируемся при загрузке, чтобы принимать ввод с клавиатуры
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      
      // Обработка цифр
      if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
        _appendToExpression('0');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
        _appendToExpression('1');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
        _appendToExpression('2');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
        _appendToExpression('3');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
        _appendToExpression('4');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
        _appendToExpression('5');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
        _appendToExpression('6');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
        _appendToExpression('7');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
        _appendToExpression('8');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
        _appendToExpression('9');
        return KeyEventResult.handled;
      }
      // Обработка операторов
      else if (key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.numpadAdd) {
        _appendToExpression('+');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract) {
        _appendToExpression('-');
        return KeyEventResult.handled;
      }
      // Обработка точки
      else if (key == LogicalKeyboardKey.period || key == LogicalKeyboardKey.numpadDecimal) {
        _appendToExpression('.');
        return KeyEventResult.handled;
      }
      // Обработка скобок
      else if (key == LogicalKeyboardKey.parenthesisLeft) {
        _appendToExpression('(');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.parenthesisRight) {
        _appendToExpression(')');
        return KeyEventResult.handled;
      }
      // Обработка специальных клавиш
      else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter || 
               key == LogicalKeyboardKey.equal) {
        _calculateResult();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
        _deleteSymbol();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.clear) {
        _clearExpression();
        return KeyEventResult.handled;
      }
      // Обработка символов напрямую (для операторов *, /, ^ и других случаев)
      else if (event.character != null) {
        final char = event.character!;
        if (['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
             '+', '-', '*', '/', '^', '.', '(', ')', '='].contains(char)) {
          if (char == '=') {
            _calculateResult();
          } else {
            _appendToExpression(char);
          }
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  bool _isFirstDivisionByZero(String expr) {
    if (expr.isEmpty) return false;
    final s = expr.replaceAll(' ', '');

    // Find the first top-level operator (+, -, *, /) not inside parentheses
    int depth = 0;
    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch == '(') {
        depth++;
      } else if (ch == ')') {
        depth--;
      } else if (depth == 0 && (ch == '+' || ch == '-' || ch == '*' || ch == '/')) {
        // If the first top-level operator is not division, we're fine
        if (ch != '/') return false;

        // Get denominator (right side)
        String denom = s.substring(i + 1);
        // Try to unwrap numeric parentheses like (0) or ((0.0))
        String unwrapParensIfNumeric(String t) {
          while (t.length >= 2 && t.startsWith('(') && t.endsWith(')')) {
            final inner = t.substring(1, t.length - 1);
            if (RegExp(r'^[+\-]?\d+(\.\d+)?$').hasMatch(inner)) {
              t = inner;
            } else {
              break;
            }
          }
          return t;
        }

        denom = unwrapParensIfNumeric(denom);

        // Keep only the numeric prefix of the denominator
        final match = RegExp(r'^[+\-]?\d+(\.\d+)?').matchAsPrefix(denom);
        if (match == null) return false;
        final denomStr = denom.substring(0, match.end);
        final denomVal = double.tryParse(denomStr);
        if (denomVal == null) return false;
        return denomVal == 0.0;
      }
    }
    return false;
  }

  String eval(String result) {
    try {
      final parser = Parser();
      final normalizedExpression = result.replaceAll('√', 'sqrt');
      final expression = parser.parse(normalizedExpression);
      final context = ContextModel();

      try {
        double evaluatedResult = expression.evaluate(EvaluationType.REAL, context);
        
        // Округляем результат до 10 знаков после запятой, чтобы убрать ошибки округления
        // Например, 0.600000000001 станет 0.6000000000, а затем мы удалим лишние нули
        evaluatedResult = double.parse(evaluatedResult.toStringAsFixed(10));
        
        // Проверяем, есть ли в исходном выражении точка (десятичное число)
        final hasDecimalPoint = result.contains('.');
        
        // Если есть точка в исходном выражении, всегда показываем результат с десятичной частью
        if (hasDecimalPoint) {
          // Используем toStringAsFixed для избежания ошибок округления, затем удалим лишние нули
          String resultStr = evaluatedResult.toStringAsFixed(10);
          // Если результат целый, но в исходном выражении была точка, добавляем .0
          if (!resultStr.contains('.')) {
            return resultStr + '.0';
          }
          // Убираем завершающие нули после точки, но оставляем .0 если результат целый
          if (evaluatedResult % 1 == 0) {
            return evaluatedResult.toInt().toString() + '.0';
          }
          // Убираем завершающие нули только после десятичной точки
          if (resultStr.contains('.')) {
            // Разделяем на целую и дробную части
            final parts = resultStr.split('.');
            if (parts.length == 2) {
              // Удаляем завершающие нули из дробной части
              String fractionalPart = parts[1].replaceAll(RegExp(r'0+$'), '');
              // Если дробная часть стала пустой, возвращаем только целую часть
              if (fractionalPart.isEmpty) {
                return parts[0];
              }
              // Иначе возвращаем целую часть и дробную часть без завершающих нулей
              return '${parts[0]}.$fractionalPart';
            }
          }
          return resultStr;
        } else {
          // Если нет точки в исходном выражении
          // Если результат десятичный, показываем его с десятичной частью
          if (evaluatedResult % 1 != 0) {
            // Используем toStringAsFixed для избежания ошибок округления, затем удалим лишние нули
            String resultStr = evaluatedResult.toStringAsFixed(10);
            // Убираем завершающие нули только после десятичной точки
            if (resultStr.contains('.')) {
              // Разделяем на целую и дробную части
              final parts = resultStr.split('.');
              if (parts.length == 2) {
                // Удаляем завершающие нули из дробной части
                String fractionalPart = parts[1].replaceAll(RegExp(r'0+$'), '');
                // Если дробная часть стала пустой, возвращаем только целую часть
                if (fractionalPart.isEmpty) {
                  return parts[0];
                }
                // Иначе возвращаем целую часть и дробную часть без завершающих нулей
                return '${parts[0]}.$fractionalPart';
              }
            }
            return resultStr;
          } else {
            // Если результат целый, возвращаем целое число
            final intValue = evaluatedResult.toInt();
            return intValue.toString();
          }
        }
      } catch (e) {
        return expression.evaluate(EvaluationType.REAL, context).toString();
      }
    } catch (e) {
      return result;
    }
  }

  void _appendToExpression(String value) {
    setState(() {
      if (value == '√') {
        if (_canInsertFunction()) {
          _result += '√(';
        }
        return;
      }
      if (_isValidInput(value)) {
        _result += value;
      }
    });
  }

  bool _canInsertFunction() {
    if (_result.isEmpty) return true;
    final previous = _result[_result.length - 1];
    return ['+', '-', '*', '/', '^', '('].contains(previous);
  }

  bool _isValidInput(String value) {
    // Check if input is a digit, dot, or one of the operators (+, -, *, /, ^) or parentheses (, )
    final validCharacters = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '+', '-', '*', '/', '^', '(', ')', '√'];

    // Check if the input is an operator and the last character in the expression is also an operator
    if (_result.isNotEmpty &&
        ['+', '-', '*', '/', '^'].contains(value) &&
        ['+', '-', '*', '/', '^'].contains(_result[_result.length - 1])) {
      // Replace the last operator with the new operator
      _result = _result.replaceRange(_result.length - 1, _result.length, value);
      _result = _result.substring(0, _result.length - 1);
      return true;
    }

    // Check if the input is a dot and the current number already contains a dot
    if (value == '.' && _result.isNotEmpty && _result.split(RegExp(r'[+\-*/^]')).last.contains('.')) {
      return false;
    }

    // Check if the first character is an operator, dot, or right parenthesis
    if (_result.isEmpty && (value == '.' || ['+', '*', '/', '^', ')'].contains(value))) {
      return false;
    }

    // Check if the character after an operator, dot, or left parenthesis is a digit or left parenthesis
    if (_result.isNotEmpty && (['+', '-', '*', '/', '^', '(', '.'].contains(_result[_result.length - 1]) || _result[_result.length - 1] == '(') && !['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '(', '-', '√'].contains(value)) {
      return false;
    }

    // Check if the character after a right parenthesis is a digit, left parenthesis, operator, or dot
    if (_result.isNotEmpty && _result[_result.length - 1] == ')' && !['+', '-', '*', '/', '^', '(', ')', '.'].contains(value)) {
      return false;
    }

    // Check if there are more right parentheses than left parentheses + operators after a left parenthesis
    final leftParenthesesCount = _result.split('(').length - 1;
    final rightParenthesesCount = _result.split(')').length - 1;
    if (rightParenthesesCount > leftParenthesesCount) {
      return false;
    }

    // Check if the input is a right parenthesis and there are no matching left parentheses
    if (value == ')' && _result.split('(').length <= _result.split(')').length) {
      return false;
    }

    // Check if there is a left parenthesis after a right parenthesis
    if (value == '(' && _result.isNotEmpty && _result[_result.length - 1] == ')') {
      return false;
    }

    // Check if there is a digit before a left parenthesis
    if (value == '(' && _result.isNotEmpty && RegExp(r'\d').hasMatch(_result[_result.length - 1])) {
      return false;
    }

    // Check if there is a digit after a right parenthesis
    if (RegExp(r'\d').hasMatch(value) && _result.isNotEmpty && _result[_result.length - 1] == ')') {
      return false;
    }
    
    // Check if the input is a negative sign and can be placed at the beginning or after an opening parenthesis
    if (value == '-' && (_result.isEmpty || _result[_result.length - 1] == '(')) {
      return true;
    }

    return validCharacters.contains(value);
  }

  void _calculateResult() {
    setState(() {
      try {
        if (_isFirstDivisionByZero(_result)) {
          _result = "На ноль делить нельзя!";
          return;
        }
        _result = eval(_result);
        // Проверяем, если результат содержит нечисловые символы (слова), выводим Error
        if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(_result)) {
          _result = "Error";
        }
      } catch (e) {
        _result = "0";
      }
    });
  }

  void _clearExpression() {
    setState(() {
      _result = '';
    });
  }

  void _deleteSymbol() {
    setState(() {
      _result = _result.replaceRange(_result.length - 1, _result.length, "");
    });
  }

  Color _getButtonColor(String value) {
    // Оранжевые кнопки для операций
    if (['+', '-', '*', '/', '^', '=', '√'].contains(value)) {
      return Color(0xFFFF9500);
    }
    // Серые кнопки для функций
    if (['C', '⌫'].contains(value)) {
      return Color(0xFFA6A6A6);
    }
    // Темно-серые кнопки для цифр и скобок
    return Color(0xFF333333);
  }

  Color _getTextColor(String value) {
    // Черный текст для серых кнопок
    if (['C', '⌫'].contains(value)) {
      return Colors.black;
    }
    // Белый текст для остальных
    return Colors.white;
  }

  Widget _buildCalculatorButton(String value, {bool isDoubleWidth = false}) {
    return Expanded(
      flex: isDoubleWidth ? 2 : 1,
      child: Padding(
        padding: EdgeInsets.all(6),
        child: Material(
          color: _getButtonColor(value),
          borderRadius: BorderRadius.circular(50),
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () {
              if (value == '=') {
                _calculateResult();
              } else if (value == 'C') {
                _clearExpression();
              } else if (value == '⌫') {
                _deleteSymbol();
              } else {
                _appendToExpression(value);
              }
            },
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: _getTextColor(value),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        autofocus: true,
        child: SafeArea(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                alignment: Alignment.bottomRight,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    _result.isEmpty ? '0' : _result.toString(),
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildCalculatorButton('C'),
                      _buildCalculatorButton('('),
                      _buildCalculatorButton(')'),
                      _buildCalculatorButton('⌫'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildCalculatorButton('7'),
                      _buildCalculatorButton('8'),
                      _buildCalculatorButton('9'),
                      _buildCalculatorButton('+'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildCalculatorButton('4'),
                      _buildCalculatorButton('5'),
                      _buildCalculatorButton('6'),
                      _buildCalculatorButton('-'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildCalculatorButton('1'),
                      _buildCalculatorButton('2'),
                      _buildCalculatorButton('3'),
                      _buildCalculatorButton('*'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildCalculatorButton('0', isDoubleWidth: true),
                      _buildCalculatorButton('.'),
                      _buildCalculatorButton('='),
                      _buildCalculatorButton('/'),
                      _buildCalculatorButton('^'),
                      _buildCalculatorButton('√'),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}