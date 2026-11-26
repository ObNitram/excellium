# Excellium

Un tableur à colonnes typées (texte, nombre, pourcentage, date, durée,
catégories, booléen, référence vers une autre feuille), écrit en Flutter.

## Organisation

Le dépôt est un espace de travail Dart composé de cinq paquets. Les
dépendances ne vont que dans un sens : l'application et le stockage dépendent
du cœur, jamais l'inverse.

| Paquet | Rôle | Dépend de |
|---|---|---|
| `packages/excellium_core` | Cœur métier en Dart pur : modèle, règles de saisie, tri et filtres, cas d'usage, **interfaces de stockage** | rien (ni Flutter, ni base) |
| `packages/excellium_storage_drift` | Implémentation SQLite des interfaces de stockage, avec Drift | `excellium_core`, `drift` |
| `packages/excellium_formula` | Moteur de formules : implémente l'interface `FormulaEngine` du cœur | `excellium_core` |
| `packages/excellium_store_contract` | Suite de tests que tout moteur de stockage doit réussir | `excellium_core`, `test` |
| `app` | Interface Flutter et état (Riverpod) | `excellium_core`, et les moteurs concrets (stockage, formules) **uniquement** dans `lib/bootstrap/` |

### Le cœur (`excellium_core`)

- `model/` : `Sheet`, `ColumnDef`, `SheetRow`, `CellValue`, styles
  (`CellStyle`), critères de tri et de filtre, vues (`ViewSpec`, `SavedView`).
  Les cellules sont rattachées à l'identifiant de leur colonne, pas à sa lettre
  ni à sa position.
- `logic/` : interprétation d'une saisie selon le type de colonne
  (`parseCellInput`), conversion lors d'un changement de type, tri et filtres
  (`applyRowQuery`), style effectif d'une cellule (`resolveStyle`), catégories
  d'une colonne, libellé et recherche des lignes référencées.
- `logic/formulas.dart` : `SheetFormulas` relie colonnes et lignes au moteur
  de formules (colonnes Formule, dépendances entre elles, cases de calcul) ;
  `logic/grouping.dart` répartit les lignes en groupes.
- `ports/` : `SheetRepository`, `ColumnRepository`, `RowRepository`,
  `ViewRepository` et `ExcelliumStore`. Ce sont les seules choses que le reste
  du code connaît du stockage. `ports/formula.dart` définit de même
  `FormulaEngine`, la seule chose connue du moteur de formules.
- `usecases/` : `WorkbookService`, pour les actions qui enchaînent plusieurs
  écritures ou portent une règle (créer une feuille, changer le type d'une
  colonne, styler une colonne, déplacer, enregistrer une vue…). Toute
  modification du classeur passe par lui ; il la note dans son `UndoHistory`
  (voir « Annuler et rétablir »).
- `memory.dart` : un stockage en mémoire, utilisé par les tests de l'interface.

### L'application (`app`)

```
lib/
  main.dart            racine de composition : ouvre le stockage et l'injecte
  bootstrap/           seul dossier autorisé à connaître Drift et le moteur
                       de formules concret
  app/                 MaterialApp, thème, écran d'erreur de démarrage
  shared/              providers du stockage, pictogrammes, panneau flottant,
                       boutons et cases à cocher, glisser-déposer
  features/
    workbook/          écran principal, onglets, feuille active
    grid/              grille, rendu des cellules, sélection, lignes de
                       groupe, volet des cases de calcul
    columns/           en-tête de colonne, menu, filtre, renommage
    styling/           barre de style
    editing/           barre d'édition, choix d'une ligne référencée,
                       éditeurs de formule et de case de calcul
    formulas/          textes des résultats et des erreurs de formule
    views/             vue en cours, vues enregistrées, barre de vue
    kanban/            affichage Kanban
    calendar/          affichage Calendrier
```

### Apparence

L'interface reprend la maquette Claude Design (`Main.dc.html`) : mêmes
couleurs, tailles et espacements. Ils sont rassemblés dans
`app/lib/app/theme.dart` (`AppColors`, `AppSizes`, `AppShadows`, `AppText`).

- **Polices** : Inter pour l'interface, en chiffres à chasse fixe comme dans
  la maquette. Les cellules peuvent aussi utiliser Liberation Serif ou
  JetBrains Mono (aussi celle des formules). Toutes sont embarquées dans
  `app/assets/fonts/`, chacune avec sa licence (SIL Open Font License pour
  Inter et Liberation Serif, Apache 2.0 pour JetBrains Mono). Les tests de
  l'interface les chargent aussi, pour mesurer la même mise en page que
  l'application.
- **Pictogrammes** : les tracés SVG de la maquette, dessinés par `AppIcon`
  (`shared/app_icons.dart`) ; aucune icône Material n'est utilisée.
- Le seul bouton de la maquette absent est « Fusionner les cellules » : dans
  un tableur aux colonnes typées, deux cellules de colonnes différentes n'ont
  pas de valeur commune possible.

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
  laisse voir, partagé par la grille, le kanban et le calendrier ;
- `rowGroupsProvider` : les groupes de la grille quand la vue regroupe ;
- `sheetFormulasProvider` : les calculs d'une feuille (colonnes Formule et
  cases de calcul), à partir de `formulaEngineProvider`.

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

## Formules

Le langage : nombres (virgule décimale), noms de colonne (entre crochets
s'ils contiennent des espaces, ou lettre de la colonne), `+ - × /`,
parenthèses et fonctions. Il sert à trois endroits :

- **colonne Formule** : une formule par colonne, calculée pour chaque ligne
  (`Quantité × Prix`) ;
- **cases de calcul** sous la table : un texte, ou un calcul qui commence par
  `=` (`=Somme(Budget)`), sur toute la table ;
- **lignes de regroupement** : même convention, mais chaque groupe calcule sur
  ses propres lignes.

Fonctions fournies : `Somme`, `Moyenne`, `Min`, `Max`, `Nombre` (sur une
colonne entière ; avec plusieurs colonnes, un résultat par colonne),
`Arrondi` et `Abs` (ligne à ligne).

### Ajouter une fonction

Dans `packages/excellium_formula`, écrire une classe et l'ajouter à la liste
`standardFunctions` (`lib/src/standard_functions.dart`). Rien d'autre n'est à
modifier : l'analyse, les erreurs et les boutons de la barre d'édition
s'appuient sur cette description.

```dart
/// Une valeur pour toute une colonne.
final class MedianFunction extends ColumnFunction {
  const MedianFunction();

  @override
  String get name => 'Médiane';

  @override
  String get example => 'Médiane(Budget)';

  @override
  double? compute(ColumnInput input) {
    if (input.numbers.isEmpty) return null;
    final sorted = [...input.numbers]..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }
}
```

Une fonction ligne à ligne étend `RowFunction` de la même façon. On peut
aussi passer sa propre liste au moteur, sans toucher au paquet :
`ExcelliumFormulaEngine(functions: [...standardFunctions, const MedianFunction()])`
dans `app/lib/bootstrap/formulas.dart`.

### Changer de moteur de formules

Écrire une classe qui implémente `FormulaEngine` (`evaluate` et `functions`)
et la renvoyer depuis `app/lib/bootstrap/formulas.dart`. Le moteur ne connaît
ni les feuilles ni les cellules : il reçoit un texte et un `FormulaScope` qui
lui donne des séries de nombres, et rend un `FormulaOutcome`. Le cœur
(`SheetFormulas`) et l'interface ne changent pas.

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
cd packages/excellium_formula && dart test
```

```bash
cd app && flutter test
```

Régénérer le code Drift après une modification du schéma
(`packages/excellium_storage_drift/lib/src/database.dart`) :

```bash
cd packages/excellium_storage_drift && dart run build_runner build
```

## Annuler et rétablir

Avant chaque modification, `WorkbookService` demande à son `UndoHistory`
(`excellium_core`) de garder un instantané du classeur ; annuler remet le
dernier instantané en place, rétablir refait ce qui a été annulé. Les
instantanés viennent du stockage (`ExcelliumStore.snapshot` et `restore`) :
chaque moteur copie et réécrit ses propres données, identifiants compris, ce
qui rend l'annulation exacte quelle que soit l'action (suppression d'une
feuille, changement de type, style…).

- Une action composée (créer une feuille avec ses colonnes et ses lignes)
  s'annule d'un coup.
- Une formule ou une case de calcul tapée lettre par lettre s'annule d'un
  coup : les enregistrements de même clé, à moins de deux secondes
  d'intervalle, sont fusionnés.
- Valider une cellule sans la changer, ou une suppression refusée, ne crée pas
  d'étape.
- L'historique garde les 100 dernières modifications, le temps de la session.
- La vue en cours (tri, filtres, regroupement, colonnes masquées) n'en fait
  pas partie : c'est un réglage d'affichage.

Dans l'application : boutons de la barre de style, menu Édition, Ctrl+Z et
Ctrl+Y (ou Ctrl+Maj+Z). Dans un champ où une saisie est en cours, Ctrl+Z
annule la frappe ; sinon il annule la dernière modification du classeur.

## Suppressions

Une confirmation annonce ce qui sera supprimé ; Ctrl+Z annule la suppression.
Elles passent par `WorkbookService`, qui garde le classeur cohérent :

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
- barre de titre avec les menus Fichier, Édition, Affichage, Insertion,
  Format et Données ;
- annuler et rétablir (boutons, menu, Ctrl+Z / Ctrl+Y) ;
- zoom de la feuille de 50 à 200 % (menu, Ctrl++ / Ctrl+- / Ctrl+0) ;
- barre de style, limitée aux réglages qui ont un sens pour le type : police
  (Inter, Liberation Serif, JetBrains Mono) et taille, gras, italique,
  souligné, couleur du texte, couleur de fond, bordure, alignement, retour à
  la ligne, format des nombres (décimales, €, pourcentage), booléen en case à
  cocher, interrupteur ou texte, pourcentage en valeur ou en barre de
  progression ; par colonne ou par cellule ;
- Σ écrit sous la colonne une case de calcul (somme, moyenne…) ;
- barre d'édition adaptée au type : texte, nombre, pourcentage, date, durée,
  catégories en pastilles, Vrai / Faux, recherche d'une ligne dans la feuille
  liée (avec choix des colonnes de recherche et relation 1 – n ou n – n) ;
- saisie immédiate : un clic sur une cellule ou une case de calcul donne la
  saisie à la barre d'édition, on tape tout de suite. Le texte d'une cellule
  est sélectionné (taper le remplace, Entrée passe à la ligne suivante) ;
  dans une formule ou un calcul, le curseur se place à la fin ;
- tri et filtres depuis le menu de la colonne, critères rappelés dans la barre
  de vue ;
- colonnes masquées, vues enregistrées (affichage, tri, filtres, colonnes) ;
- regroupement de la grille selon une colonne Catégorie ou Référence, avec
  groupes repliables, ajout de ligne dans un groupe et une opération par
  colonne sur les lignes de groupe ;
- colonne de type Formule ; cases de calcul sous la table, alignées sur les
  colonnes, dans un volet réglable et repliable ;
- affichages Grille, Kanban (à partir d'une colonne Catégorie unique) et
  Calendrier (à partir d'une colonne Date), avec glisser-déposer des lignes ;
- dans le kanban, création d'une carte (une ligne) dans une étape et d'une
  étape (une catégorie de la colonne) ;
- persistance SQLite, avec migration du schéma.

Pas encore fait :

- créer une ligne depuis le calendrier ;
- copier-coller, sélection de plusieurs cellules, navigation au clavier dans la
  grille, fusion de cellules ;
- la hauteur d'une ligne ne s'adapte pas à une grande police ou au retour à
  la ligne : on la règle à la main ;
- formules : pas de texte, de condition (`Si`) ni de référence d'une case de
  calcul à une autre ; la hauteur du volet de calcul et les groupes repliés ne
  sont pas mémorisés d'une session à l'autre ;
- sélecteur de date en français (il s'affiche en anglais) ;
- import et export.
