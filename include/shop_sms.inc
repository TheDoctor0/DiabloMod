#if defined _shop_sms_included
	#endinput
#endif
#define _shop_sms_included

#pragma library "shop_sms"

#include <shop_sms_const>

native ss_register_module(const name[],const numbers[],const text[]);
/*------------------------------
 * Rejestruje modul, ktory bedzie obslugiwal zakupy
 * ---------------------------
 * name - nazwa modulu
 * numbers - tablica numerow
 * text - tresc wiadomosci do wpisania
------------------------------*/

native ss_create_config(const path[],const name[],default_set,const text[],which);
/*------------------------------
 * Tworzy plik konfiguracyjny dla uslugi lub modulu.
 * ---------------------------
 * path - sciezka do pliku konfiguracyjnego
 * name - nazwa modulu
 * value - dodaæ domyœlne ustawienia
 * text - dodatkowe ustawienia
 * which - jaka usluga
------------------------------*/

native ss_register_service(const name[], const opis[], const tag[],const values[]);
/*------------------------------
 * Rejestruje usluge, ktora bedzie pozniej dostepna w sklepie
 * ---------------------------
 * name - nazwa uslugi
 * tag - jednostka wartosci
 * values - 10-elementowa tablica wartosci za dana kwote smsa
------------------------------*/

native ss_service_add_user(const auth[], const password[], const access[], const flags[], lenght);
/*------------------------------
 * Dodaje flagi graczowi na okreslona ilosc dni.
 * ---------------------------
 * auth - klucz identyfikacyjny np. STEAM_ID, nick lub IP
 * password - haslo ( opcjonalnie )
 * access - flagi uprawnien
 * flags - flagi dostepu
 * lenght - dlugosc trwania uslugi
------------------------------*/

native ss_show_sms_info(id);
/*------------------------------
 * Kontynuuje proces zakupu po zwroceniu wartosci SS_STOP w forwardzie ss_service_chosen
 * ---------------------------
 * id - index gracza dokonujacego zakupu
------------------------------*/

native ss_log(const message[],any:...);
/*------------------------------
 * Dodaje informacje do logów.
------------------------------*/

native bool:ss_is_steam(id);
/*------------------------------
 * Sprawdza, czy gracz ma steama
 * ---------------------------
 * id - index gracza dokonujacego zakupu
------------------------------*/

native ss_get_config_path(const path[], len);
/*------------------------------
 * Pobiera sciezke do pliku konfiguracyjnego
------------------------------*/

native ss_get_config_dir_path(const path[], len);
/*------------------------------
 * Pobiera sciezke do folderu z plikami konfiguracyjnymi
------------------------------*/

native ss_get_users_path(const path[], len);
/*------------------------------
 * Pobiera sciezke do pliku z uprawnieniami uzytkownikow
------------------------------*/

native ss_get_codes_path(const path[], len);
/*------------------------------
 * Pobiera sciezke do pliku z kodami
------------------------------*/

forward ss_service_addingtolist(id);
/*------------------------------
 * Forward wysylany ( do pluginu z ktorego zostala zarejstrowana usluga )
 * w momencie dodawania uslugi do menu z uslugami.
 * Funkcja powinna zwracaæ jedn¹ z dwoch wartosci:
 *  ITEM_ENABLED - usluga ma byc dostepna
 *  ITEM_DISABLED - usluga ma byc niedostepna
 * ---------------------------
 * id - index gracza dokonujacego zakupu
------------------------------*/

forward ss_service_chosen(id, wybor);
/*------------------------------
 * Forward wysylany ( do pluginu z ktorego zostala zarejstrowana usluga )
 * w momencie wybrania uslugi.
 * Funkcja powinna zwracaæ jedn¹ z dwoch wartosci:
 *  SS_OK
 *  SS_STOP - gdy chcemy na pewien czas zatrzymaæ proces wykupowania us³ugi.
 *		Potem musimy go wznowiæ za pomoc¹ natywu ss_show_sms_info.
 * ---------------------------
 * id - index gracza dokonujacego zakupu
------------------------------*/

forward ss_service_bought(id, choice);
/*------------------------------
 * Forward wysylany ( do pluginu z ktorego zostala zarejstrowana usluga ) w momencie zakupu uslugi.
 * Mozna zwrocic wartosc SS_ERROR w przypadku wystapienia bledu przy dodawaniu uslugi.
 * ---------------------------
 * id - index gracza dokonujacego zakupu
 * choice - index w tablicy values podanej przy rejestracji uslugi
------------------------------*/

forward ss_module_validate(id, const code[], value);
/*------------------------------
 * Forward wysylany do pluginu z ktorego zostal zarejstrowany obecnie uzywany modul.
 * Wywolywany jest podczas weryfikacji kodu zwrotnego.
 * Mozna zwrocic nastepujace wartosci:
 *  SS_OK - w przypadku prawidlowego kodu
 *  SS_REPEAT - zostanie wykonany forward ss_module_validate_repeat
 *  SS_WRONG - w przypadku zlego kodu
 *  SS_ERROR - w przypadku bledu
 * ---------------------------
 * id - index gracza dokonujacego zakupu
 * code - kod zwrotny podany przez gracza
 * value - index w tablicy z numerami
------------------------------*/

forward ss_module_validate_repeat(id, const code[], value);
/*------------------------------
 * Forward wysylany do pluginu z ktorego zostal zarejstrowany obecnie uzywany modul.
 * Wywolywany jest, gdy w forwardzie ss_module_validate zostala zwrocona wartosc SS_REPEAT.
 * Wywolywany jest co 0.5sec przez maksymalnie X sekund. Wartosc X definiuje cvar sklepsms_timeout.
 * Mozna zwrocic nastepujace wartosci:
 *  SS_OK - w przypadku prawidlowego kodu
 *  SS_REPEAT - zostanie wykonany forward ss_module_validate_repeat
 *  SS_WRONG - w przypadku zlego kodu
 *  SS_ERROR - w przypadku bledu
 * ---------------------------
 * id - index gracza dokonujacego zakupu
 * code - kod zwrotny podany przez gracza
 * value - index w tablicy z numerami
------------------------------*/

forward ss_module_validate_timeout(id);
/*------------------------------
 * Forward wysylany do pluginu z ktorego zostal zarejstrowany obecnie uzywany modul.
 * Wywolywany jest, gdy czas oczekiwania(sec) na odpowiedz serwera jest dluzszy 
 * niz ten zdefiniowany za pomoca cvaru sklepsms_timeout.
 * ---------------------------
 * id - index gracza dokonujacego zakupu
------------------------------*/
