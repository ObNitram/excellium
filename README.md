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

- `model/` : `Sheet`, `ColumnDef`, `SheetRow`, `CellValue`, styles
  (`CellStyle`), critères de tri et de filtre, vues (`ViewSpec`, `SavedView`).
  Les cellules sont rattachées à l'identifiant de leur colonne, pas à sa lettre
  ni à sa position.
- `logic/` : interprétation d'une saisie selon le type de colonne
  (`parseCellInput`), conversion lors d'un changement de type, tri et filtres
  (`applyRowQuery`), style effectif d'une cellule (`resolveStyle`), catégories
  d'une colonne, libellé et recherche des lignes référencées.
- `ports/` : `SheetRepository`, `ColumnRepository`, `RowRepository`,
  `ViewRepository` et `ExcelliumStore`. Ce sont les seules choses que le reste
  du code connaît du stockage.
- `usecases/` : `WorkbookService`, pour les actions qui enchaînent plusieurs
  écritures ou portent une règle (créer une feuille, changer le type d'une
  colonne, styler une colonne, déplacer, enregistrer une vue…).
- `memory.dart` : un stockage en mémoire, utilisé par les tests de l'interface.

### L'application (`app`)

```
lib/
  main.dart            racine de composition : ouvre le stockage et l'injecte
  bootstrap/           seul dossier autorisé à connaître Drift
  app/                 MaterialApp, thème, écran d'erreur de démarrage
  shared/              providers du stockage, panneau flottant, glisser-déposer
  features/
    workbook/          écran principal, onglets, feuille active
    grid/              grille, rendu des cellules, sélection
    columns/           en-tête de colonne, menu, filtre, renommage
    styling/           barre de style
    editing/           barre d'édition, choix d'une ligne référencée
    views/             vue en cours, vues enregistrées, barre de vue
    kanban/            affichage Kanban
    calendar/          affichage Calendrier
```

Les écrans lisent l'état par des providers Riverpod écrits à la main (sans
génération de code) et agissent en appelant `WorkbookService`, ou les dépôts à
travers `storeProvider`. Les principaux :

- `sheetsProvider`, `columnsProvider`, `rowsProvider`, `savedViewsProvider` :
  flux issus du stockage ;
- `selectionProvider` : cellule ou colonne sélectionnée ;
- `viewSpecProvider` : vue en cours d'une feuille (affichage, tri, filtres,
  colonnes masquées). Elle vit en mémoire ; seules les vues enregistrées vont
  dans le stockage ;
- `visibleColumnsProvider`, `visibleRowsProvider` : ce que la vue en cours
  laisse voir, partagé par la grille, le kanban et le calendrier.

## Changer de moteur de stockage

1. Créer un paquet qui implémente `ExcelliumStore` et ses quatre dépôts.
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

## Suppressions

Les suppressions sont définitives (il n'y a pas encore d'annulation) : une
confirmation annonce ce qui sera perdu. Elles passent par `WorkbookService`,
qui garde le classeur cohérent :

- supprimer une feuille vide les colonnes Référence qui la visaient ;
- supprimer une colonne la retire des vues enregistrées et des recherches des
  colonnes Référence ;
- supprimer une ligne la retire des cellules Référence qui la visaient ;
- il reste toujours au moins une feuille, et au moins une colonne par feuille.

## Où sont les données

La base SQLite `excellium.sqlite` est créée dans le dossier de données de
l'application fourni par le système (sous Linux,
`~/.local/share/dev.excellium.excellium_app/`).

## État actuel

Fait :

- feuilles en onglets : ajout, déplacement par glisser-déposer, renommage
  (double-clic ou menu de l'onglet), suppression ;
- colonnes typées avec changement de type et conversion des valeurs, renommage
  (double-clic sur l'en-tête), largeur réglable, déplacement par
  glisser-déposer, suppression (menu de la colonne), hauteur des lignes
  réglable, suppression d'une ligne (clic sur son numéro) ;
- sélection d'une cellule ou d'une colonne entière (clic sur l'en-tête) ;
- barre de style, limitée aux réglages qui ont un sens pour le type : gras,
  italique, souligné, alignement, booléen en case à cocher, interrupteur ou
  texte, pourcentage en valeur ou en barre de progression ; par colonne ou par
  cellule ;
- barre d'édition adaptée au type : texte, nombre, pourcentage, date, durée,
  catégories en pastilles, Vrai / Faux, recherche d'une ligne dans la feuille
  liée (avec choix des colonnes de recherche et relation 1 – n ou n – n) ;
- tri et filtres depuis le menu de la colonne, critères rappelés dans la barre
  de vue ;
- colonnes masquées, vues enregistrées (affichage, tri, filtres, colonnes) ;
- affichages Grille, Kanban (à partir d'une colonne Catégorie unique) et
  Calendrier (à partir d'une colonne Date), avec glisser-déposer des lignes ;
- dans le kanban, création d'une carte (une ligne) dans une étape et d'une
  étape (une catégorie de la colonne) ;
- persistance SQLite, avec migration du schéma.

Pas encore fait :

- créer une ligne depuis le calendrier ;
- menus de la barre de titre (Fichier, Édition…), annuler / rétablir,
  copier-coller, sélection de plusieurs cellules, navigation au clavier dans la
  grille ;
- styles de police, de couleur et de bordure, formats de nombre ;
- sélecteur de date en français (il s'affiche en anglais) ;
- import et export.
