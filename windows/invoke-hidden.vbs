Option Explicit

Dim shell, args, command, index, exitCode
Set shell = CreateObject("WScript.Shell")
Set args = WScript.Arguments

If args.Count = 0 Then
    WScript.Quit 2
End If

command = ""
For index = 0 To args.Count - 1
    If index > 0 Then
        command = command & " "
    End If
    command = command & QuoteArgument(args(index))
Next

exitCode = shell.Run(command, 0, True)
WScript.Quit exitCode

Function QuoteArgument(value)
    Dim result, position, character, backslashCount

    If Len(value) > 0 And InStr(value, " ") = 0 And InStr(value, vbTab) = 0 And InStr(value, Chr(34)) = 0 Then
        QuoteArgument = value
        Exit Function
    End If

    result = Chr(34)
    backslashCount = 0
    For position = 1 To Len(value)
        character = Mid(value, position, 1)
        If character = "\" Then
            backslashCount = backslashCount + 1
        ElseIf character = Chr(34) Then
            result = result & String(backslashCount * 2 + 1, "\") & Chr(34)
            backslashCount = 0
        Else
            result = result & String(backslashCount, "\") & character
            backslashCount = 0
        End If
    Next

    result = result & String(backslashCount * 2, "\") & Chr(34)
    QuoteArgument = result
End Function
