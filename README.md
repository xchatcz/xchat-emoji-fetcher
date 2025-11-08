# xchat-emoji-fetcher
Umí stáhnout všechny aktuální smajlíky ze serveru XChat.cz

## Nápověda
```text
Použití:
  ./fetch.sh OD DO

Popis:
  Stáhne všechny soubory ve tvaru CISLO.gif do adresáře ./sm/.
  URL vzor: http://x.ximg.cz/images/x4/sm/%1/%2.gif
    - %2 = celé číslo smajlíku (bez nulování), např. 90 → "90.gif"
    - %1 = pokud poslední dvě číslice (%2 mod 100) jsou 00–09, použije se JEDINÁ číslice 0–9
           jinak se použijí POSLEDNÍ DVA znaky 10–99

Příklady:
  ./fetch.sh 0 99
  ./fetch.sh 1 1234

Poznámky:
  - Vyžaduje 'wget'
  - Cíl: ./sm/ (vytváří se automaticky)
```

Copyright &copy: [Jan Elznic](https://janelznic.cz) (Elza) <jan@elznic.com>
