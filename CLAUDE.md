# Zen POS — Project Context for Claude

## Co je tento projekt
Flutter POS (Point of Sale) systém pro restaurace/bary. Skládá se ze dvou aplikací:
- **Admin web** (`lib/main_admin.dart`) → nasazeno na https://zen-pos.web.app
- **POS tablet** (`lib/main.dart`) → běží nativně na iPad

## Tech stack
- Flutter + Dart
- Firebase (Firestore + Authentication)
- Provider (state management)
- Google Fonts (Inter pro admin)
- fl_chart (grafy)
- Bluetooth printing (flutter_bluetooth_serial)

## Architektura
```
lib/
  main.dart              # Entry point pro iPad POS (iOS theme)
  main_admin.dart        # Entry point pro admin web (světlý theme)
  models/                # Data modely
    order_model.dart     # Objednávky + OrderItem (s addony, storno)
    payment_model.dart   # Platby (s položkami, slevami, stornem, staffem)
    product_model.dart   # Produkty + kategorie
    table_model.dart     # Stoly
    staff_model.dart     # Zaměstnanci + role
    cash_movement_model.dart  # Pohyby hotovosti + uzávěrky
    stock_model.dart     # Sklad (karty, transakce, inventury, dodavatelé)
    happy_hour_model.dart     # Časové slevy
    addon_model.dart     # Přídavky/modifiery k produktům
    pos_settings_model.dart   # Nastavení pokladny
  screens/
    kiosk_login_screen.dart   # iPad login (výběr profilu + PIN)
    unified_pos_screen.dart   # Hlavní POS obrazovka
    payment_screen.dart       # Platba (s tipy, slevami)
    admin_dashboard_screen.dart  # Admin dashboard + sidebar
    admin_section_profit.dart    # Sekce: Zisk
    admin_section_receipts.dart  # Sekce: Účtenky
    admin_section_cash.dart      # Sekce: Pokladna + uzávěrky
    admin_section_storno.dart    # Sekce: Storna a slevy
    admin_section_addons.dart    # Sekce: Přídavky k produktům
    admin_section_happy_hours.dart  # Sekce: Happy Hours
    admin_section_tables_manage.dart # Sekce: Správa stolů
    admin_section_pos_settings.dart  # Sekce: Nastavení pokladny
    admin_section_stock.dart    # Sekce: Sklad (kompletní modul)
  services/
    firestore_service.dart   # Veškerá Firebase komunikace
    printer_service.dart     # Bluetooth tisk
  viewmodels/
    tables_viewmodel.dart    # Stoly, objednávky, platby, storno, slevy
    products_viewmodel.dart  # Produkty a kategorie
    auth_viewmodel.dart      # Autentizace (PIN + Firebase)
  theme/
    app_colors.dart      # Barvy (light/dark, iOS-inspired)
    app_typography.dart  # Typografie (Inter pro admin, SF Pro pro iOS)
    app_spacing.dart     # Spacing + corner radius systém
```

## Design filozofie

### Admin web (zen-pos.web.app)
- Inspirace: **Storyous admin** (https://admin.storyous.com)
- Světlý theme: bílé pozadí, `#F2F2F7` jako secondary
- Primary barva: `#E8445A` (Storyous red)
- Font: **Inter** (Google Fonts)
- Čistý, minimalistický, profesionální webový styl
- Sidebar 220px, scrollovatelný, sekce rozdělené labely

### POS tablet (iPad)
- Filozofie: **nativně Apple/iOS**
- System font: SF Pro (`.SF Pro Text`)
- iOS Human Interface Guidelines
- Velké touch targety (min 44pt)
- Bílé karty s jemnými stíny na `#F2F2F7` pozadí
- Zaoblené rohy 12-16px
- Cupertino komponenty kde možné
- Primary: `#E8445A`, accent: `#007AFF` (iOS blue)

## Klíčové funkcionality

### POS tablet
- Výběr profilu s PIN přihlášením
- Správa stolů (obsazeno/volné/rezervováno)
- **Počet osob** — dialog při otevření stolu
- Přidávání produktů do objednávky
- **Storno položek** — long press → dialog s důvodem
- **Slevy na účet** — tlačítko v detailu stolu
- Platba (karta/hotovost/převod) se spropitným
- Bluetooth tisk účtenek

### Admin web
Sidebar sekce:
- **PŘEHLEDY**: Tržby, Zisk, Aktuální přehled, Historie, Storna a slevy
- **ÚČTY**: Účtenky (s filtry + detail), Pokladna (pohyby + uzávěrky)
- **MENU**: Produkty, Kategorie, Přídavky/Modifiery, Happy Hours
- **PERSONÁL**: Zaměstnanci, Role
- **SPRÁVA**: Stoly (CRUD), Nastavení pokladny, Sklad, Tiskárna

### Sklad (kompletní modul)
- Skladové karty (s jednotkami, min zásobou, nákupní cenou)
- Naskladnění / Přeskladnění / Odpisy
- Inventury (draft → completed → approved)
- Přehled dodavatelů

## Firebase kolekce
- `categories`, `products`, `tables`, `payments`
- `staff`, `roles`
- `cash_movements`, `day_closures`
- `stock_items`, `stock_transactions`, `inventories`, `suppliers`
- `happy_hours`, `product_addons`
- `settings/pos_settings`

## Designové myšlenky vlastníka
- UI by mělo vypadat jako **nativní Apple aplikace** na iPadu
- Admin web by měl být čistý jako **Storyous** (referenční systém)
- Konzistentní šířky karet a layoutu v každé sekci
- Žádné tmavé pozadí — vše světlé a přehledné
- Profesionální, ne "podomácky vyrobené"

## Deploy
```bash
# Deploy admin na Firebase Hosting
flutter build web --target lib/main_admin.dart --release
firebase deploy --only hosting

# Spustit lokálně
flutter run -d chrome --target lib/main_admin.dart  # admin
flutter run -d chrome --target lib/main.dart         # POS
```

## Firebase projekt
- Project ID: `zen-pos`
- Hosting: https://zen-pos.web.app
- Firestore rules: `allow read, write: if true` (development)
