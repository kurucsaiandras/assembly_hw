; -----------------------------------------------------------
; Mikrokontroller alapú rendszerek házi feladat
; Készítette: Kurucsai András
; Neptun code: WWEI3B
; Feladat leírása:
; 			Belső memóriában 32 biten bináris számként tárolt telefonszámok
; 			tömbjében adott szám keresése. Bemenet: tömb kezdőcíme (mutató),
; 			a tömb mérete (32 bites szavak száma - 1 regiszterben), a keresett
; 			telefonszám (4 db regiszterben). Kimenet: telefonszám sorszáma a
; 			tömbben, 0 ha nem fordul elő.
;			Az eredményt az R5-ös regiszterben kapjuk vissza, az eredmény az
;			57. soron elhelyezett Breakpoint-on már biztosan előáll.
; -----------------------------------------------------------

$NOMOD51 ; a sztenderd 8051 regiszter definíciók nem szükségesek

$INCLUDE (SI_EFM8BB3_Defs.inc) ; regiszter és SFR definíciók

	;regiszterek átnevezése a könnyebb olvashatóság érdekében:
	RPTR EQU R0	   ; adott regiszter (telefonszám egyes bájtjai) címére mutató pointer
	IDX  EQU R5    ; keresett telefonszám sorszáma (itt lesz az eredmény)
	SIZE EQU R6    ; tömb mérete
	OFS EQU R7	   ; relatív címet tárolja a tömb elejéhez képest

	ADR  EQU 0x100 ; a tömb kezdőcíme //bemeneti adat

	CSEG AT ADR	   ; adatok elhelyezése a kódmemóriába //bemeneti adat
	Numbers: DB 0x25, 0xE3, 0xF7, 0x11, 0xBC, 0x70, 0xDB, 0x28, 0xCE, 0x6D, 0x05, 0x12, 0xBC, 0x70, 0xDB, 0x29, 0x87, 0x98, 0xFE, 0x0B, 0xF9, 0x64, 0x03, 0x12

; Ugrótábla létrehozása
	CSEG AT 0
	SJMP Main

myprog SEGMENT CODE			;saját kódszegmens létrehozása
RSEG myprog 				;saját kódszegmens kiválasztása
; ------------------------------------------------------------
; Főprogram
; ------------------------------------------------------------
; Feladata: a szükséges inicializációs lépések elvégzése és a
;			feladatot megvalósító szubrutin meghívása
; ------------------------------------------------------------
Main:
	CLR IE_EA ; interruptok tiltása watchdog tiltás idejére
	MOV WDTCN,#0DEh ; watchdog timer tiltása
	MOV WDTCN,#0ADh
	SETB IE_EA ; interruptok engedélyezése

	; paraméterek előkészítése a szubrutin híváshoz
	MOV SIZE, #6		;a feltöltött tömb mérete //bemeneti adat
	MOV R1, #0xBC       ;a keresett telefonszám az R1..R4 regiszterekben található(LSB R1-ben) //bemeneti adatok
	MOV R2, #0x70
	MOV R3, #0xDB
	MOV R4, #0x29
	MOV DPTR, #Numbers  ;tömb kezdőcímét a Data Pointerbe rakjuk

	CALL SearchPhoneNumber ; keresés elvégzése, az eredmény az R5 regiszterben látható
	JMP $ ; végtelen ciklusban várunk

; -----------------------------------------------------------
; SearchPhoneNumber szubrutin
; -----------------------------------------------------------
; Funkció: 		Adott telefonszám sorszámának megkeresése
; Bementek:		R1 - telefonszám 1. bájt
;			 	R2 - telefonszám 2. bájt
;			 	R3 - telefonszám 3. bájt
;				R4 - telefonszám 4. bájt
;				DPTR - a tömb kezdőcíme
;				SIZE(R6) - a tömb mérete
; Kimenetek:	IDX(R5) - a keresett sorszám
; Regisztereket módosítja:
;				A, RPTR(R0), IDX(R5), OFS(R7)
; -----------------------------------------------------------
SearchPhoneNumber:
			MOV IDX,  #1
			MOV RPTR, #0x01		;A regiszter pointert R1 címére állítjuk
			MOV OFS, #0		    ;R7-ben a tömb elejéhez relatív indexet fogjuk tárolni, kezdetben ez 0
			MOV A, #0
	Loop:
			MOVC A, @A+DPTR		;ezen a ponton A-ban mindig a relatív index van tárolva
			XRL A, @RPTR		;egy bájt összehasonlítása
			JNZ Nemegyezik
			;ha  egyezik a két bájt:
			CJNE RPTR, #0x04, Nemnegyedik ;ha ez a szó 4. bájtja volt, a két telefonszám egyezik, visszatérünk, ha nem, folytatjuk az ellenőrzést
			RET
	Nemnegyedik: 		;ha az egyező bájtok nem a telefonszám utolsói voltak, folytatjuk az ellenőrzést
			INC OFS
			INC RPTR
			MOV A, OFS	;relatív indexet A-ba töltjük
			JMP Loop
	Nemegyezik:			;ha az összehasonlított bájtok nem egyeztek
			MOV A, IDX
			XRL A, SIZE
			JNZ Nemutolso
			MOV IDX, #0 ;ha a legutolsó szó valamelyik bájtjánál nem találunk egyezést, akkor a szám nincs benne a tömbben
			RET
	Nemutolso:			;ha a bájtok nem egyeztek, de még nem értük el a tömb végét
			MOV A, IDX
			MOV B, #4
			MUL AB
			MOV OFS, A	;a tömbben következőként rögtön a következő szó első bájtját ellenőrizzük, a relatív indexet R7-ben is eltároljuk
			MOV RPTR, #0x01 ;ehhez a keresett szám bájtjaira mutató pointert is az első bájtra kell visszaállítani
			INC IDX		;következő szám jön, növeljük az indexet
			JMP Loop

END
