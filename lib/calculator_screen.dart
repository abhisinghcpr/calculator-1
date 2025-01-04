  import 'package:calculator/button_values.dart';
  import 'package:flutter/material.dart';
  import 'package:math_expressions/math_expressions.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  class CalculatorScreen extends StatefulWidget {
    const CalculatorScreen({Key? key}) : super(key: key);

    @override
    State<CalculatorScreen> createState() => _CalculatorScreenState();
  }

  class _CalculatorScreenState extends State<CalculatorScreen> {
    String input = '';
    String output = '';
    List<String> calculationHistory = [];

    @override
    void initState() {
      super.initState();
      _loadHistory();
    }

    void _loadHistory() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        calculationHistory = prefs.getStringList('calculationHistory') ?? [];
      });
    }

    void _saveHistory() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setStringList('calculationHistory', calculationHistory);
    }

    void onButtonClick(String context, BuildContext buildContext) {
      if (context == "C") {
        input = '';
        output = '';
      } else if (context == "()") {
        // Toggle between "(" and ")"
        if (input.endsWith("(")) {
          input = input.substring(0, input.length - 1) + ")";
        } else if (input.endsWith(")")) {
          input = input.substring(0, input.length - 1) + "(";
        } else {
          if (input.isNotEmpty && !RegExp(r'[0-9.]$').hasMatch(input)) {
            input += "(";
          } else {
            input += ")";
          }
        }
      } else if (context == "=") {
        // Check if parentheses are balanced before evaluating the expression
        if (areParenthesesBalanced(input)) {
          try {
            var userInput = input;

            // Handle percentage operation first
            userInput = userInput.replaceAllMapped(
              RegExp(r'(\d+(?:\.\d+)?)\s*%\s*(\+|\-|\*|\/|$)'),
                  (match) {
                var value = double.parse(match.group(1)!);
                var operator = match.group(2) ?? '';
                return (value / 100).toString() + operator;
              },
            );

            // Updated logic for handling negative numbers
            userInput = userInput.replaceAllMapped(
              RegExp(r'(?<=\d)\s*(-)\s*(?=\d)'),
                  (match) => match.group(0)!.contains('-') ? '-' : '+',
            );

            // Ensure that "÷" is replaced with "/" and "×" is replaced with "*"
            userInput = userInput.replaceAll('÷', '/');
            userInput = userInput.replaceAll('×', '*');

            // Check if the input exceeds 15 digits
            if (getDigitCount(userInput) > 15) {
              // Display a pop-up notifying the user
              showDigitLimitExceededDialog(buildContext);
              return;
            }

            Parser p = Parser();
            Expression expression = p.parse(userInput);
            ContextModel cm = ContextModel();
            var finalValue = expression.evaluate(EvaluationType.REAL, cm);
            output = formatNumber(finalValue.toString());

            // Format the input with periods as thousands separators
            input = formatNumber(userInput);

            // Add the expression to the calculation history
            calculationHistory.add("$input = $output");

            // Save updated history to SharedPreferences
            _saveHistory();
          } catch (e) {
            // Handle parsing or evaluation errors
            output = '';
            input = '';
          }
        } else {
          // Handle the case when parentheses are not balanced
          output = '';
          input = '';
        }
      } else if (context == "+/-") {
        // ... (existing code)
      } else if (context == "%") {
        // Handle percentage button
        if (input.isNotEmpty && RegExp(r'[0-9.]$').hasMatch(input)) {
          input += "%";
        }
      } else {
        // Handle numeric input
        if (context == "." && input.contains(".")) {
          // Prevent entering multiple decimal points
          return;
        }

        if (context == "÷") {
          // Handle division symbol
          input += "÷";
        } else if (context == "×") {
          // Handle multiplication symbol
          input += "×";
        } else {
          // Avoid replacing special characters

          // Check if adding the new character will exceed 15 digits
          if (getDigitCount(input + context) > 15) {
            // Display a pop-up notifying the user
            showDigitLimitExceededDialog(buildContext);
            return;
          }

          input += context;
        }
      }

      setState(() {});
    }

    int getDigitCount(String input) {
      return input.replaceAll(RegExp(r'[^0-9]'), '').length;
    }

    void showDigitLimitExceededDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Digit Limit Exceeded"),
            content: Text("You can input numbers with a maximum of 15 digits."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.black, // Set button text color to black
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    String formatNumber(String numberString) {
      // Replace "/" with "÷" and "*" with "×"
      var formattedNumber =
      numberString.replaceAll('/', '÷').replaceAll('*', '×');

      // Check if the number is an integer
      if (formattedNumber.contains('.') &&
          double.tryParse(formattedNumber)! % 1 == 0) {
        // Remove decimal part for integers
        formattedNumber = formattedNumber.replaceAll(RegExp(r'\.0$'), '');
      }

      return formattedNumber;
    }

    bool areParenthesesBalanced(String input) {
      int count = 0;
      for (var char in input.runes) {
        if (String.fromCharCode(char) == '(') {
          count++;
        } else if (String.fromCharCode(char) == ')') {
          count--;
        }
        if (count < 0) {
          return false; // Mismatched closing parenthesis
        }
      }
      return count == 0; // Parentheses are balanced if count is zero
    }

    @override
    Widget build(BuildContext context) {
      final screenSize = MediaQuery.of(context).size;
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  reverse: true,
                  child: Stack(
                    children: [
                      Container(
                        width: 350,
                        height: 270,
                        alignment: Alignment.bottomRight,
                        padding: const EdgeInsets.all(8.0),
                        margin: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0XFFF4EAE0),
                        ),
                        child: Column(
                          children: <Widget>[
                            Container(
                              alignment: Alignment.bottomRight,
                              padding: const EdgeInsets.all(8.0),
                              margin: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0XFFF4EAE0),
                              ),
                              child: Column(
                                children: <Widget>[
                                  Text(
                                    input,
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                  Text(
                                    output,
                                    style: const TextStyle(
                                      fontSize: 80,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        left: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () {
                                // Show calculation history
                                showHistoryDialog(context);
                              },
                              icon: Icon(Icons.history),
                            ),
                            IconButton(
                              onPressed: () {
                                if (input.isNotEmpty) {
                                  input = input.substring(0, input.length - 1);
                                  setState(() {});
                                }
                              },
                              icon: Icon(Icons.backspace_outlined),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  children: [
                    ...ButtonArea1.values.map(
                          (e) => SizedBox(
                        width: screenSize.width / 4.19,
                        height: screenSize.width / 4.19,
                        child: buildButton(
                          text: e.text,
                          color: e.color,
                          textColor: e.textColor,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildButton({
      required String text,
      required Color color,
      required Color textColor,
    }) {
      return Container(
        margin: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(75),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              offset: Offset(4, 4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white,
              offset: Offset(-4, -4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => onButtonClick(text, context),
          style: ElevatedButton.styleFrom(
            backgroundColor: color, // Background color
            elevation: 0, // Set elevation to 0 to delete default shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(75),
            ),
          ),
          child: FittedBox(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 32,
                color: textColor,
              ),
            ),
          ),
        ),
      );
    }

    void showHistoryDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Container(
              alignment: Alignment.center,
              child: Text("Calculation History", style: TextStyle(fontSize: 20)),
            ),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: calculationHistory.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(calculationHistory[index]),
                  );
                },
              ),
            ),
            backgroundColor: Color(0xFFF4F6F0), // Set background color
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFCB935F)
                          .withOpacity(0.83), // Set the container color
                      borderRadius:
                      BorderRadius.circular(20), // Set border radius
                    ),
                    child: TextButton(
                      onPressed: () {
                        // Clear history from both memory and shared preferences
                        setState(() {
                          calculationHistory.clear();
                        });
                        _saveHistory(); // Save cleared history
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black, // Set button text color
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Clear History"),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFCB935F)
                          .withOpacity(0.83), // Set the container color
                      borderRadius:
                      BorderRadius.circular(20), // Set border radius
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black, // Set button text color
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Close"),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    }
  }
