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
db	" Tabela nr 1", VARIABLE_ASCII_CODE_NEWLINE
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
db	" |       |        |          przypadku pozostaje bez zmian.                   |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Pozostale rejestry zachowane.                             |", VARIABLE_ASCII_CODE_NEWLINE
db	" ------------------------------------------------------------------------------", VARIABLE_ASCII_CODE_NEWLINE
db	" |  0x00 |   0x03 | Popros o dostep do wiekszej przestrzeni pamieci.          |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wejscie:                                                  |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rcx - rozmiar przestrzeni do zaalokowania,             |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |          wielokrotnosc 4096 Bajtow tj. 1 strony.          |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rdi - adres pod jakim udostepnic przestrzen,           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |          pamietaj o wyrownaniu adresu do pelnej strony,   |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |          and di, 0xF000                                   |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wyjscie:                                                  |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rcx - jesli ZERO - brak wolnej pamieci do              |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |          przydzielenia.                                   |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Pozostale rejestry zachowane.                             |", VARIABLE_ASCII_CODE_NEWLINE
db	" ------------------------------------------------------------------------------", VARIABLE_ASCII_CODE_NEWLINE
db	" |  0x00 |   0x05 | Pobierz argumenty przeslane wraz z programem.             |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wejscie:                                                  |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rdi - wskaznik do miejsca zapisu pobranych argumentow. |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wyjscie:                                                  |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rcx - rozmiar danych w znakach, jesli ZERO - brak,     |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |          przeslanych argumentow,                          |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rdi - wskaznik do danych (argumentow).                 |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Pozostale rejestry zachowane.                             |", VARIABLE_ASCII_CODE_NEWLINE
db	" ------------------------------------------------------------------------------", VARIABLE_ASCII_CODE_NEWLINE
db	" |  0x01 |   0x00 | Wyczysc przestrzen ekranu.                                |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wejscie:                                                  |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rbx - numer linii od ktorej rozpoczac czyszczenie,     |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rcx - ilosc linii do wyczyszczenia, jesli ZERO -       |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |          wyczysc wszystkie liniie od linii wybranej.      |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wyjscie:                                                  |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    brak                                                   |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wszystkie rejestry zachowane.                             |", VARIABLE_ASCII_CODE_NEWLINE
db	" ------------------------------------------------------------------------------", VARIABLE_ASCII_CODE_NEWLINE
db	" |  0x01 |   0x01 | Wypisz tekst na ekranie od miejsca kursora.               |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wejscie:                                                  |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rbx - kolor znakow,                                    |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rcx - ilosc znakow do wyswietlania z ciagu lub do      |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |          pierwszego TERMINATORA (0x00),                   |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rdx - kolor tla znakow,                                |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rsi - wskaznik ciagu znakow do wyswietlenia.           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wyjscie:                                                  |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    brak                                                   |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wszystkie rejestry zachowane.                             |", VARIABLE_ASCII_CODE_NEWLINE
db	" ------------------------------------------------------------------------------", VARIABLE_ASCII_CODE_NEWLINE
db	" |  0x01 |   0x02 | Wypisz znak na ekranie w miejscu kursora.                 |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wejscie:                                                  |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rbx - kolor znaku,                                     |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rcx - ilosc znakow do wyswietlania (powtorzen),        |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    rdx - kolor tla znaku,                                 |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    r8  - kod ASCII znaku do wyswietlenia.                 |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wyjscie:                                                  |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |    brak                                                   |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        |                                                           |", VARIABLE_ASCII_CODE_NEWLINE
db	" |       |        | Wszystkie rejestry zachowane.                             |", VARIABLE_ASCII_CODE_NEWLINE
db	" ------------------------------------------------------------------------------", VARIABLE_ASCII_CODE_NEWLINE

