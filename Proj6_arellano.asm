TITLE String Primitives and Macros     (Proj6_arellano.asm)

; Author: Osbaldo Arellano
; Last Modified: 11/28/2022
; OSU email address: arellano@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:   6              Due Date: 12/4/2022
; Description: This program gets 10 integers from the user
;              and stores them in an array. The program reads 
;              the user input as string of digits. Two macros are used 
;              to validate and convert the string digits to its numeric 
;              representation (SDWORDS). 
;              The numbers, total sum, and truncated average is displayed. 

INCLUDE Irvine32.inc

mGetString MACRO mssg, input, buffer, length
	push    edx
	push    ecx
	push    eax
	
	mov     edx, mssg
	call	WriteString
	mov     edx, input
	mov     ecx, buffer
	call	ReadString
	mov     length, eax

	pop     eax
	pop     ecx
	pop     edx
ENDM

mDisplayString MACRO mssg
	push    edx

	mov     edx, mssg
	call	WriteString

	pop     edx
ENDM

MAX_ARR_LEN    = 4
BUFFER         = 20
LO			   = -2147483648
HI			   = 2147483647
NEGATE = -1

.data

intro          BYTE	  "PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",13,10,13,10,0
intro2         BYTE	  "Written by Osbaldo Arellano",13,10,13,10,0
instructions   BYTE	  "Please provide 10 signed integers.",13,10,13,10,0
instructions2  BYTE	  "Each number needs to be small enough to fit inside a 32 bit register.",13,10 
               BYTE	  "After you have finished inputting the numbers the program will display a list of the integers, their sum, and their average value.",13,10,13,10,0
inputMssg      BYTE	  "Please enter a signed number: ",0
error          BYTE	  "You did not enter a signed number or your number was too big",13,10,0
tryAgain       BYTE	  "Please try again: ",0
arrMssg        BYTE	  "You entered the following numbers: ",13,10,0
sumMssg        BYTE	  "The sum of these numbers is: ",0
avgMssg        BYTE	  "The truncated average is:    ",0
goodbye        BYTE	  "Thanks for playing!",13,10,0

positive       BYTE "Num was positive",0
negative       BYTE "Num was negative",0
overflow       BYTE "Overflow detected",13,10,0

overflowed     BYTE "Overflow",13,10,0

input          BYTE	  ?
inputLen       DWORD  ?
validArray     SDWORD MAX_ARR_LEN DUP(0)

mssg BYTE "Displaying arr",13,10,13,10,0

validFlag      BYTE   ?

isValid        DWORD  ?            ; Flag set when user input is valid 
isNegative     DWORD  ?            ; Flag set when user input is negative
isPositive     DWORD  ?            ; Flag set when user input is positive

.code
main PROC
	mDisplayString	OFFSET intro
	mDisplayString	OFFSET intro2
	mDisplayString	OFFSET instructions
	mDisplayString	OFFSET instructions2	

	mov     ecx, MAX_ARR_LEN                ; Reading a max of 10 numbers .... increments when valid flag is not set
	mov     esi, OFFSET validArray
_readLoop:	
	push    ecx
	push    esi
	mov     isNegative, 0
	mov     isPositive, 0

	push    OFFSET isValid                  ; Flag for checking if current number is valid 
	push    OFFSET error                    ; Displays when getting invalid input
	push    esi                             ; Array that holds valid inputs... increments if valid flag is set. otehrwise, stays the same 
	push    OFFSET inputMssg                ; Title Message
	push	OFFSET inputLen                 ; Will hold the length of user input 
	push    OFFSET input                    ; Array that holds user input in form of ASCII chars 
	call	ReadVal

	pop     esi
	pop     ecx
	cmp     isValid, 0
	je      _notValid
	mov     isValid, 0                      ; Reset isValid flag for next byte string 
	add     esi, 4
	loop	_readLoop
	jmp     _continue

_notValid:
	inc     ecx
	loop    _readLoop
_continue:
	push LENGTHOF validArray
	push OFFSET mssg
	push OFFSET validArray
	call displayList

	Invoke ExitProcess,0	
main ENDP


displayList PROC
	push	ebp
	mov     ebp, esp
	mov     esi, [ebp + 8]                 ; Points to array
	mov     ebx, [ebp + 12]                ; Points to sorted list or unsorted list message
	mov     ecx, [ebp + 16]                ; Points to array size 

	mov     edx, ebx
	call	WriteString

	mov     ebx, 0                         ; EBX to keep track of how many primes are printed (20 per line)
_displayLoop:
	cmp     ebx, 20
	je      _printLine
	inc     ebx
	mov     eax, [esi]
	call	WriteInt
	mov     al, ' '
	call	WriteChar
	add     esi, 4
	loop	_displayLoop
	jmp     _done

_printLine:
	call	CrLf
	mov     ebx, 0                         ; EBX keeps track of primes printed. Reinit to 0. 
	inc     ecx
	loop	_displayLoop

_done:
	pop     ebp
	ret     12
displayList ENDP



; ---------------------------------------------------------------
; Name: ReadVal
; 
; Invokes the mGetString macro to get user input 
; in the form of a string of digits. Converts the string
; of digits to its numeric value representation and validates
; user input (no letters, symbols, etc). Finally, the valid 
; inputs are stored into an array. 
; 
; Preconditions: none
;
; Postconditions: One SDWORD will be pushed to validArray 
;
; Recieves: [ebp + 8]  = array that hold user input in the from of ascii chars
;           [ebp + 12] = Will hold the length of the user input
;           [ebp + 16] = Title message
;           [ebp + 20] = array that hold valid inputs
;           [ebp + 24] = error message 
; ---------------------------------------------------------------
ReadVal PROC
	push    ebp		
	mov     ebp, esp

	mov     edi, [ebp + 20]        ; Points to array that will hold valid inputs 

	; mGetString(titleMssg, inputArr, buffer, inputLength)
	mGetString  [ebp + 16], [ebp + 8], BUFFER, [ebp + 12]

	mov    eax, 0 
	mov    edx, 0
	mov    ecx, [ebp + 12]        ; Points to loop constraint = length of user input
	mov    esi, [ebp + 8]         ; Points to BYTE array. Used for user input. 
_checkLoop:
	mov     eax, 0
	LODSB 
	cmp     al, 48
	jl      _checkSign
	cmp     al, 57
	jg      _invalid
	push    ecx
	jmp     _convert

_convert:
	push    eax
	mov     eax, edx    
	mov     ebx, 10
	mul     ebx
	jo      _overflow
	mov     ecx, eax
	pop     eax
	sub     al, 48
	add     eax, ecx
	mov     edx, eax
	pop     ecx
	loop	_checkLoop	
	jmp     _done

_invalid: 
	mov    edx, [ebp + 24]        ; Display error message
	mDisplayString edx
	mov    esi, 0 
	jmp    _returnInvalid

; ---------------
; Compares ECX and user input length. 
; And determines which flag to set. 
;
; If loop is in its first iteration. 
;     - A sign char is ok. Continue.
; else 
;     - Sign is embedded in the byte array. 
;       Not a valid input. Return. 
; -------------------
_checkSign:
	cmp    ecx, [ebp + 12]
	jne    _invalid
	cmp    al, 43                 ; '+' = 43d
	je     _isPositive
	cmp    al, 45                 ; '-' = 45d
	je     _isNegative
	jmp    _invalid

_isPositive:
	mov    isPositive, 1         
	loop   _checkLoop
	jmp    _done
	
_isNegative:
	mov    isNegative, 1
	loop   _checkLoop
	jmp    _done
	 
_done:
	cmp    isNegative, 1
	je     _negate
	mov    [edi], eax 
	mov    eax, 1
	mov    esi, [ebp + 28]          ; Points to isValid flag   
	mov    [esi], eax               ; Set the isValid flag to true 
	pop    ebp
	ret    24

_returnInvalid:
	pop ebp
	ret 24

_negate:
	neg    eax
	mov    [edi], eax 
	mov    eax, 1
	mov    esi, [ebp + 28]   
	mov    [esi], eax               ; Set the isValid flag to true 
	pop    ebp
	ret    24

_overflow:
	pop    eax
	pop    ecx
	mov    edx, [ebp + 24]
	mDisplayString edx 
	mov    esi, 0
	jmp    _returnInvalid

ReadVal ENDP



; ---------------------------------------------------------------
; Name: WriteVal
; 
; Converts numeric SDWORD into an ASCII string of digits. 
; Invokes the mDisplayString macro to display the ASCII representation 
; of the SDWORD numeric value. 
; 
; ---------------------------------------------------------------
WriteVal PROC

WriteVal ENDP

END main
