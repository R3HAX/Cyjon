db	VARIABLE_ASCII_CODE_NEWLINE
db	"                              W a t a h a . n e t", VARIABLE_ASCII_CODE_NEWLINE
db	"                            -----------------------", VARIABLE_ASCII_CODE_NEWLINE
db	"                                       Cyjon v", VARIABLE_KERNEL_VERSION, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_NEWLINE
db	" [EN] Sorry, this file is only in Polish.", VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_NEWLINE
db	" Prosty i wielozadaniowy system operacyjny, napisany w jezyku asemblera dla", VARIABLE_ASCII_CODE_NEWLINE
db	" procesorow z rodziny amd64/x86-64.", VARIABLE_ASCII_CODE_NEWLINE
db	"", VARIABLE_ASCII_CODE_NEWLINE
db	" 1. Cyjon API", VARIABLE_ASCII_CODE_NEWLINE
db	"", VARIABLE_ASCII_CODE_NEWLINE
db	"    Jak zapewne dobrze wiesz, aby skorzystac z uslug jadra w roznych aspektach", VARIABLE_ASCII_CODE_NEWLINE
db	" nalezy wywolac przerwanie programowe. Kazde jadro systemu posiada wlasny numer", VARIABLE_ASCII_CODE_NEWLINE
db	" przerwania tj. MS-DOS 0x21, Linux 0x80. Cyjon wykorzystuje numer 0x40,", VARIABLE_ASCII_CODE_NEWLINE
db	" w systemie dziesietnym to liczba 64 (sentyment do C64).", VARIABLE_ASCII_CODE_NEWLINE
db	"", VARIABLE_ASCII_CODE_NEWLINE
db	"    Wszystkie uslugi wykonywane przez jadro, sa pogrupowane w kategorie/grupy.", VARIABLE_ASCII_CODE_NEWLINE
db	" Grupe wybieramy za pomoca rejestru AH. Rejestr AL jest numerem uslugi z danej", VARIABLE_ASCII_CODE_NEWLINE
db	" grupy. Ponizsza tabelka przedstawia aktualnie wszystkie dostepne uslugi dla", VARIABLE_ASCII_CODE_NEWLINE
db	" programow.", VARIABLE_ASCII_CODE_NEWLINE
db	"", VARIABLE_ASCII_CODE_NEWLINE
db	" ------------------------------------------------------------------------------", VARIABLE_ASCII_CODE_NEWLINE
db	" | GRUPA | USLUGA | OPIS                                                      |", VARIABLE_ASCII_CODE_NEWLINE
db	" ------------------------------------------------------------------------------", VARIABLE_ASCII_CODE_NEWLINE
db	" |  0x00 |   0x00 | Zakonczenie procesu wywolujacego.                         |", VARIABLE_ASCII_CODE_NEWLINE
db	" ------------------------------------------------------------------------------", VARIABLE_ASCII_CODE_NEWLINE
db	" |  0x00 |   0x01 | Uruchomienie nowego procesu/programu.                     |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wejscie:                                                  |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rcx - ilosc znakow w nazwie pliku do uruchomienia,     |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rdx - ilosc znakow w przekazywanych argumantach,       |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rsi - wskaznik do nazwy pliku,                         |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rdi - wskaznik do argumentow.                          |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wyjscie:                                                  |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rcx - numer PID uruchomionego procesu, jesli ZERO      |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |          program nie zostal uruchomiony, kod bledu        |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |          znajduje sie w rejestrze RAX.                    |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Pozostale rejestry zachowane.                             |", VARIABLE_ASCII_CODE_NEWLINE
db	" ------------------------------------------------------------------------------", VARIABLE_ASCII_CODE_NEWLINE
db	" |  0x00 |   0x02 | Sprawdz czy proces o podanym PID jest uruchomiony.        |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wejscie:                                                  |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rcx - numer PID procesu do sprawdzenia.                |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wyjscie:                                                  |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rcx - jesli ZERO, proces nie istnieje, w innym         |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |          rejestr nie zmiania wartosci.                    |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |  Pozostale rejestry zachowane.                           ", 0xFF, "|", VARIABLE_ASCII_CODE_NEWLINE
db	" ------------------------------------------------------------------------------", VARIABLE_ASCII_CODE_NEWLINE

