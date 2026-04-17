#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <string>
#include <vector>

// Creates a console for the current process and redirects stdout/stderr to it.
void CreateAndAttachConsole();

// Returns the command line arguments as UTF-8 strings.
std::vector<std::string> GetCommandLineArguments();

// Converts a UTF-16 string to UTF-8.
std::string Utf8FromUtf16(const wchar_t* utf16_string);

#endif  // RUNNER_UTILS_H_
