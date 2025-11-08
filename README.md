# xchat-emoji-fetcher
Umí stáhnout všechny aktuální smajlíky ze serveru XChat.cz


## Nápověda
```text
Použití:
  ./fetch.sh
  ./fetch.sh MAX
  ./fetch.sh OD DO
  ./fetch.sh --help

Popis:
  Stáhne soubory ve tvaru CISLO.gif do adresáře ./sm/.
  URL vzor: http://x.ximg.cz/images/x4/sm/%1/%2.gif
    - %2 = celé číslo smajlíku (např. 90 → "90.gif")
    - %1 = pokud (%2 mod 100) je 00–09 → použije se JEDNA číslice 0–9
           jinak POSLEDNÍ DVA znaky 10–99

Příklady:
  ./fetch.sh            # 1..9999
  ./fetch.sh 5708       # 1..5708
  ./fetch.sh 50 5708    # 50..5708

Poznámky:
  - Vyžaduje 'wget'
  - Cíl: ./sm/ (vytváří se automaticky)
  - Existující soubory se přeskočí
```
Copyright &copy: [Jan Elznic](https://janelznic.cz) (Elza) <jan@elznic.com>
