# Excellium

Un tableur à colonnes typées (texte, nombre, pourcentage, date, durée,
catégories, booléen, référence vers une autre feuille), écrit en Flutter.

## Organisation

Le dépôt est un espace de travail Dart composé de quatre paquets. Les
dépendances ne vont que dans un sens : l'application et le stockage dépendent
du cœur, jamais l'inverse.

| Paquet | Rôle | Dépend de |
|---|---|---|
| `packages/excellium_core` | Cœur métier en Dart pur : modèle, règles de saisie, tri et filtres, cas d'usage, **interfaces de stockage** | rien (ni Flutter, ni base) |
| `packages/excellium_storage_drift` | Implémentation SQLite des interfaces de stockage, avec Drift | `excellium_core`, `drift` |
| `packages/excellium_store_contract` | Suite de tests que tout moteur de stockage doit réussir | `excellium_core`, `test` |
| `app` | Interface Flutter et état (Riverpod) | `excellium_core`, et le stockage **uniquement** dans `lib/bootstrap/` |

### Le cœur (`excellium_core`)

- `model/` : `Sheet`, `ColumnDef`, `SheetRow`, `CellValue`, critères de tri et
  de filtre. Les cellules sont rattachées à l'identifiant de leur colonne, pas
  à sa lettre ni à sa position.
- `logic/` : interprétation d'une saisie selon le type de colonne
  (`parseCellInput`), conversion lors d'un changement de type, application du
  tri et des filtres (`applyRowQuery`).
- `ports/` : `SheetRepository`, `ColumnRepository`, `RowRepository` et
  `ExcelliumStore`. Ce sont les seules choses que le reste du code connaît du
  stockage.
- `usecases/` : `WorkbookService`, pour les actions qui enchaînent plusieurs
  écritures (créer une feuille, changer le type d'une colonne…).
- `memory.dart` : un stockage en mémoire, utilisé par les tests de l'interface.

### L'application (`app`)

```
lib/
  main.dart            racine de composition : ouvre le stockage et l'injecte
  bootstrap/           seul dossier autorisé à connaître Drift
  shared/providers.dart    storeProvider, workbookServiceProvider
  app/                 MaterialApp, thème, écran d'erreur de démarrage
  features/
    workbook/          onglets, feuille active
    grid/              grille, en-têtes de colonne, rendu des cellules
    editing/           barre d'édition
```

Les écrans lisent l'état par des providers Riverpod (`sheetsProvider`,
`columnsProvider`, `rowsProvider`, `selectionProvider`) et agissent en appelant
`WorkbookService` ou les dépôts à travers `storeProvider`.

## Changer de moteur de stockage

1. Créer un paquet qui implémente `ExcelliumStore` et ses trois dépôts.
2. Lui faire passer la suite de contrat :

   ```dart
   import 'package:excellium_store_contract/excellium_store_contract.dart';

   void main() {
     runStoreContractTests('mon moteur', () => MonStore());
   }
   ```

3. Remplacer le contenu de `app/lib/bootstrap/storage.dart` pour qu'il renvoie
   ce nouveau stockage.

Aucun écran, provider ou cas d'usage n'est à modifier. Le test
`app/test/architecture_test.dart` échoue si un fichier hors de `lib/bootstrap/`
importe Drift.

## Commandes

Depuis la racine du dépôt :

```bash
flutter pub get
```

Lancer l'application de bureau :

```bash
cd app && flutter run -d linux
```

(`-d macos` ou `-d windows` selon la machine.)

Lancer les tests de chaque paquet :

```bash
cd packages/excellium_core && dart test
```

```bash
cd packages/excellium_storage_drift && dart test
```

```bash
cd app && flutter test
```

Régénérer le code Drift après une modification du schéma
(`packages/excellium_storage_drift/lib/src/database.dart`) :

```bash
cd packages/excellium_storage_drift && dart run build_runner build
```

## Où sont les données

La base SQLite `excellium.sqlite` est créée dans le dossier de données de
l'application fourni par le système (sous Linux,
`~/.local/share/dev.excellium.excellium_app/`).

## État actuel

Fait : onglets, grille, colonnes typées avec changement de type et conversion
des valeurs, renommage de colonne, saisie par la barre d'édition avec
validation, cases à cocher, ajout de feuille, de colonne et de ligne,
persistance SQLite.

Le cœur sait déjà trier et filtrer (`applyRowQuery`), mais l'interface ne
l'expose pas encore.

Pas encore fait, par rapport à la maquette : barre de style, choix d'une ligne
référencée, tri et filtres à l'écran, vues enregistrées, colonnes masquées,
kanban, calendrier, redimensionnement et déplacement des colonnes à la souris.
