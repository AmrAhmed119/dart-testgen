class PromptGenerator {
  static String testPrompt(String fileContent, String filePath) {
    return ''' 
    ```dart
    $fileContent
    ```

    File path from root directory: $filePath

    **Instructions:**  
    - Generate a new test file by importing the Dart test package and this file.  
    - Write structured, simple, and efficient test cases for the core logic.  
    - **Skip tests** for non-relevant parts like imports, global constants, and simple variable declarations.

    **Guidelines:**  
    - Focus on necessary functions and methods that require validation.  
    - Use descriptive test method names reflecting the purpose of the test.  

    **Testing Decision Flag:**  
    - If the file has functions or classes requiring tests, set: `needTesting = true`.  
    - If no testing is needed, set: `needTesting = false`.  

    **Additional Requirements:**  
    - List any required packages or comments.
    ''';
  }

  static String analyzeErrorPrompt(String error) {
    return ''' 
    Dart Analysis Error: 

    ```dart
    // Error: $error
    ```
    
    **Instructions:**  
    - Analyze the error message and suggest a corrected version of the code.  
    - If applicable, generate test cases to ensure the issue does not recur.  
    - List any required packages or additional comments.
    ''';
  }

  static String testNotRunningErrorPrompt(String error) {
    return ''' 
    Test Execution Error, test cases are not running as expected.

    ```dart
    // Error: $error
    ```
    
    **Instructions:**  
    - Diagnose the issue preventing test execution.  
    - Identify any missing dependencies or misconfigurations.  
    - Provide fixes to ensure tests run correctly.  
    - Generate additional test cases if necessary.  
    - If the error persists, modify or delete the problematic test case.  
    - List any comments or needed packages.
    ''';
  }

  static String commentErrors(String error) {
    return '''
    ```dart
    // Error: $error
    ```

    **Instructions:**  
    - Comment out or remove all lines that cause test or analysis errors. 
    ''';
  }
}
