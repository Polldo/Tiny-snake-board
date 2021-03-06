/*
*	Module name: menu.asm
*
*	Module description:
*		Here is implemented the main menu of the application running on the microcontroller. An image is shown and the program waits for buttons to be pressed.
*		One button is used to change the menu option selected and the other button is used to access to the option selected.
*		Also the record memorized in the EEPROM is shown.
*
*
*	Author: Paolo Calao
*/ 

#ifndef _MENU_
#define _MENU_

#include "oled_driver.asm"
#include "oled_buffer_driver.asm"
#include "buttons.asm"
#include "record.asm"

.macro DRAW_CHAR
		ldi		r17, @0
		rcall	OLED_DRAW_CHAR
.endmacro
 
.macro DRAW_H_WALL
		ldi		r17, @0
		ldi		r16, 62
LOOP_H_WALL:
		rcall	OLED_SET_PIXEL
		dec		r16
		brne	LOOP_H_WALL
		rcall	OLED_SET_PIXEL
.endmacro

.macro DRAW_V_WALL
		ldi		r16, @0
		ldi		r17, 47
LOOP_V_WALL:
		rcall	OLED_SET_PIXEL
		dec		r17
		brne	LOOP_V_WALL
		rcall	OLED_SET_PIXEL
.endmacro

.macro DRAW_AUDIO_ON
		ldi		r17, 78
		ldi		r18, 127
		ldi		r19, 7
		ldi		r20, 7
		OLED_START_DRAW_CHAR
		DRAW_CHAR 'O'
		DRAW_CHAR 'n'
		DRAW_CHAR ' '
.endmacro

.macro DRAW_AUDIO_OFF
		ldi		r17, 78
		ldi		r18, 127
		ldi		r19, 7
		ldi		r20, 7
		OLED_START_DRAW_CHAR
		DRAW_CHAR 'O'
		DRAW_CHAR 'f'
		DRAW_CHAR 'f'
.endmacro

.macro CHANGE_AUDIO_SETTING
		tst		r5
		breq	TURN_AUDIO_ON ;audio off->on
	;TURN_AUDIO_OFF:
		DRAW_AUDIO_OFF
		rjmp	EXIT_CHANGE_AUDIO	
TURN_AUDIO_ON:
		DRAW_AUDIO_ON
EXIT_CHANGE_AUDIO:
		com		r5
		rcall	INIT_TIMER_NOTE
		rcall	SHORT_DELAY
		rcall	STOP_TIMER_NOTE
.endmacro

.macro MOVE_POINTER_MENU
		ldi		r17, 22
		ldi		r18, 127
		ldi		r19, 6
		ldi		r20, 7
	;draw updated pointer
		sbrs	r21, 0 ;move to second menu item
		ldi		r19, 7
		OLED_START_DRAW_CHAR
		DRAW_CHAR '^'
	;delete old pointer
		ldi		r17, 22
		ldi		r19, 7
		sbrs	r21, 0
		ldi		r19, 6
		OLED_START_DRAW_CHAR
		DRAW_CHAR ' '
		com		r21
.endmacro

SPLASHSCREEN: ;draw the initial image and wait for a button press
		clr		r17 ;x start
		ldi		r18, 127 ; x end
		clr		r19 ;y page start
		ldi		r20, 5 ;y page end
		ldi		zh, high(IMG_SCREEN*2) ;let z point to the initial image
		ldi		zl, low(IMG_SCREEN*2)
		rcall	OLED_DRAW_BMP 
		;'blink' the buzzer
		rcall	INIT_TIMER_NOTE
		rcall	SHORT_DELAY
		rcall	STOP_TIMER_NOTE
		;end output notes
		rcall	INIT_TIMER_BUTTONS
	;PRINT RECORD
		ldi		r17, 30
		ldi		r18, 127
		ldi		r19, 5
		ldi		r20, 5
		OLED_START_DRAW_CHAR
		DRAW_CHAR 'R'
		DRAW_CHAR 'e'
		DRAW_CHAR 'c'
		DRAW_CHAR 'o'
		DRAW_CHAR 'r'
		DRAW_CHAR 'd'
		DRAW_CHAR ' '
		;check the record in the EEPROM. 255 is the 'magic value' -> byte not initialized
		rcall	GET_RECORD
		cpi		r30, 0xFF
		brne	SHOW_RECORD
		rcall	INIT_RECORD
SHOW_RECORD:
		ldi		r16, 86
		ldi		r17, 5
		rcall	PRINT_SCORE
		clr		r30 ;score start at 0
	;PRINT MENU
	;play text
		ldi		r17, 30
		ldi		r18, 127
		ldi		r19, 6
		ldi		r20, 6
		OLED_START_DRAW_CHAR
		DRAW_CHAR 'P'
		DRAW_CHAR 'l'
		DRAW_CHAR 'a'
		DRAW_CHAR 'y'
	;sound on/off text
		ldi		r17, 30
		ldi		r18, 127
		ldi		r19, 7
		ldi		r20, 7
		OLED_START_DRAW_CHAR
		DRAW_CHAR 'S'
		DRAW_CHAR 'o'
		DRAW_CHAR 'u'
		DRAW_CHAR 'n'
		DRAW_CHAR 'd'
	;init audio to OFF
		tst		r5
		breq	INIT_AUDIO_OFF
		DRAW_AUDIO_ON
		rjmp	INIT_MENU_POINTER
INIT_AUDIO_OFF:
		DRAW_AUDIO_OFF
INIT_MENU_POINTER:
		ldi		r21, 0xFF ;cleared when menu pointer points to the first item. 0xff when second element selected
		MOVE_POINTER_MENU
LOOP_SPLASHSCREEN:
		tst		r8 
		breq	LOOP_SPLASHSCREEN
		mov		r16, r8
		clr		r8 ;button pressed is read now
		cpi		r16, 0x03
		breq	MENU_RIGHT_PRESSED
	;MENU_LEFT_PRESSED:
		MOVE_POINTER_MENU
		rcall	SHORT_DELAY
		clr		r4
		rjmp	LOOP_SPLASHSCREEN
MENU_RIGHT_PRESSED:
		tst		r21
		breq	EXIT_SPLASHSCREEN
		CHANGE_AUDIO_SETTING
		rcall	SHORT_DELAY
		clr		r4
		rjmp	LOOP_SPLASHSCREEN
EXIT_SPLASHSCREEN:
		STOP_TIMER_BUTTONS
		rcall	OLED_CLEAR_DISPLAY
		ret

INIT_GAME_SCREEN:
		rcall	INIT_OLED
		rcall	OLED_CLEAR_DISPLAY
		rcall	OLED_DISPLAY_ON
		rcall	OLED_CLEAR_DISPLAY_TABLE
		rcall	SPLASHSCREEN
		ldi		r17, 0
		ldi		r18, 127
		ldi		r19, 0
		ldi		r20, 1
		OLED_START_DRAW_CHAR
		DRAW_CHAR 'S'
		DRAW_CHAR 'n'
		DRAW_CHAR 'a'
		DRAW_CHAR 'k'
		DRAW_CHAR 'e'
	;INIT_SCORE:
		clr		r30
		ldi		r17, 55
		ldi		r18, 127
		ldi		r19, 0
		ldi		r20, 1
		OLED_START_DRAW_CHAR
		DRAW_CHAR 'S'
		DRAW_CHAR 'c'
		DRAW_CHAR 'o'
		DRAW_CHAR 'r'
		DRAW_CHAR 'e'
	;	DRAW_CHAR ':'
		ldi		r16, SCORE_X_1
		ldi		r17, 0
		rcall	PRINT_SCORE
		DRAW_H_WALL 0
		DRAW_H_WALL 47
		DRAW_V_WALL 0
		DRAW_V_WALL 62
		ret


IMG_SCREEN: .db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe0, 0x20, 0x20, 0x20, 0x20, 0x20, 0x00, \
				0x00, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, \
				0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc0, 0x00, 0x00, 0x80, 0xc0, 0x60, 0x20, 0x00, 0x80, \
				0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x87, 0x84, 0x84, 0x84, 0x84, 0x84, 0xfc, \
				0x00, 0xff, 0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x7f, 0x00, 0x80, 0x60, 0x38, 0x0f, 0x09, \
				0x08, 0x09, 0x0e, 0x78, 0x80, 0x00, 0x00, 0x7f, 0x86, 0x0f, 0x31, 0x60, 0xc0, 0x3e, 0xeb, 0x89, \
				0x88, 0x88, 0x88, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0xe0, 0x9c, \
				0x82, 0x83, 0x88, 0x98, 0x50, 0x78, 0x08, 0x08, 0x08, 0xc0, 0x78, 0x2c, 0x26, 0x24, 0x28, 0x70, \
				0xc0, 0x00, 0xfc, 0x0c, 0x08, 0x18, 0x08, 0x04, 0xfe, 0xf0, 0xb8, 0xac, 0xa4, 0x84, 0x80, 0x40, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0x92, 0x92, 0x9e, 0xf0, 0x00, 0xf0, 0x80, \
				0x80, 0xf0, 0x00, 0x00, 0x00, 0xff, 0x09, 0x09, 0x09, 0x0f, 0x00, 0xf0, 0x90, 0x90, 0xf0, 0x00, \
				0x00, 0xff, 0x00, 0xf0, 0x90, 0x90, 0xff, 0x00, 0xf0, 0x90, 0x90, 0xf0, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0xf0, 0x50, 0x70, 0x00, 0xf0, 0xd0, 0x70, 0x00, 0xf0, 0x50, 0x00, 0x70, 0xd0, 0x00, 0x70, \
				0xd0, 0x00, 0x00, 0x00, 0x10, 0xf0, 0x10, 0x00, 0xf0, 0x10, 0xf0, 0x00, 0x00, 0x00, 0xf0, 0x50, \
				0x70, 0x00, 0xf0, 0x00, 0x00, 0x00, 0xf0, 0x50, 0xf0, 0x00, 0x30, 0x20, 0xf0, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x04, \
				0x04, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0x00, 0x01, \
				0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, \
				0x00, 0x00, 0x01, 0x01, 0x01, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

#endif
