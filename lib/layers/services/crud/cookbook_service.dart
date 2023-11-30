import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sharedcookbook/extensions/list/filter.dart';
import 'package:sharedcookbook/layers/services/crud/crud_exceptions.dart';
import 'package:sqflite/sqflite.dart';

class CookbookService {
  Database? _db;
  //List<DatabaseRecipe> _recipes = [];
  List<DatabaseCookbook> _cookbooks = [];
  DatabaseUser? _user;

  // create a singleton of CookbookService using a factory constructor
  CookbookService._sharedInstance() {
    _cookbooksStreamController =
        StreamController<List<DatabaseCookbook>>.broadcast(
      onListen: () {
        _cookbooksStreamController.sink.add(_cookbooks);
      },
    );
  }
  static final CookbookService _shared = CookbookService._sharedInstance();
  factory CookbookService() => _shared;

  //final _recipesStreamController =
  //StreamController<List<DatabaseRecipe>>.broadcast();
  late final StreamController<List<DatabaseCookbook>>
      _cookbooksStreamController;

  Stream<List<DatabaseCookbook>> get allCookbooks =>
      _cookbooksStreamController.stream.filter((cookbook) {
        final currentUser = _user;
        if (currentUser != null) {
          return cookbook.createdByUserId == currentUser.id;
        } else {
          throw UserNotSetBeforeReadingCookbooksException();
        }
      });

  Future<DatabaseUser> getOrCreateUser({
    required String email,
    bool setAsCurrentUser = true,
  }) async {
    try {
      final user = await getUserByEmail(email: email);
      if (setAsCurrentUser) {
        _user = user;
      }
      return user;
    } on UserNotFoundException {
      final createdUser = await createUser(
        firstName: '',
        lastName: '',
        email: email,
      );
      if (setAsCurrentUser) {
        _user = createdUser;
      }
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  // Future<void> _cacheCookbookRecipes(int cookbookId) async {
  //   final recipes = await getRecipesByCookbookId(cookbookId);
  //   _recipes = recipes.toList();
  //   _recipesStreamController.add(_recipes);
  // }

  Future<void> _cacheCookbooks(int userId) async {
    final cookbooks = await getCookbooksByUserId(userId);
    _cookbooks = cookbooks.toList();
    _cookbooksStreamController.add(_cookbooks);
  }

  Future<Iterable<DatabaseCookbook>> getCookbooksByUserId(
    int userId,
  ) async {
    await _ensureDbIsOpen();
    final db = _getDatabase();
    final cookbooks = await db.query(
      cookbookTable,
      limit: 100,
      where: 'CreatedByUserId = ?',
      whereArgs: [userId],
    );
    return cookbooks
        .map((cookbookRow) => DatabaseCookbook.fromRow(cookbookRow));
  }

  Future<Iterable<DatabaseRecipe>> getRecipesByCookbookId(
    int cookbookId,
  ) async {
    await _ensureDbIsOpen();
    final db = _getDatabase();
    final recipes = await db.query(
      recipeTable,
      limit: 100,
      where: 'CookbookId = ?',
      whereArgs: [cookbookId],
    );
    return recipes.map((recipeRow) => DatabaseRecipe.fromRow(recipeRow));
  }

  Future<DatabaseCookbook> updateCookbookTitle({
    required DatabaseCookbook cookbook,
    required String title,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabase();

    // ensure cookbook exists, exception thrown if it does not
    await getCookbookById(id: cookbook.id);

    // update db
    final updatesCount = await db.update(
      cookbookTable,
      {titleColumn: title},
      where: 'Id = ?',
      whereArgs: [cookbook.id],
    );
    if (updatesCount == 1) {
      final updatedCookbook = await getCookbookById(id: cookbook.id);

      // update our local cache
      _cookbooks.removeWhere((cookbook) => cookbook.id == updatedCookbook.id);
      _cookbooks.add(updatedCookbook);
      _cookbooksStreamController.add(_cookbooks);

      return updatedCookbook;
    } else {
      throw CouldNotUpdateCookbookException();
    }
  }

  Future<DatabaseCookbook> getCookbookById({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabase();
    final results = await db.query(
      cookbookTable,
      limit: 1,
      where: 'Id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      final cookbook = DatabaseCookbook.fromRow(results.first);
      _cookbooks.removeWhere((cookbook) => cookbook.id == id);
      _cookbooks.add(cookbook);
      _cookbooksStreamController.add(_cookbooks);
      return cookbook;
    } else {
      throw CookbookNotFoundException();
    }
  }

  Future<void> deleteCookbookById({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabase();
    final deletedCount = await db.delete(
      cookbookTable,
      where: 'Id = ?',
      whereArgs: [id],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteRecipeException();
    } else {
      _cookbooks.removeWhere((cookbook) => cookbook.id == id);
      _cookbooksStreamController.add(_cookbooks);
    }
  }

  Future<DatabaseCookbook> createCookbook({required DatabaseUser owner}) async {
    await _ensureDbIsOpen();
    final db = _getDatabase();
    // ensure owner exists in database
    final dbUser = await getUserByEmail(email: owner.email);
    if (dbUser == owner) {
      // create cookbook
      final cookbookId = await db.insert(
        cookbookTable,
        {
          titleColumn: '',
          createdByUserIdColumn: owner.id,
        },
      );
      final cookbook = DatabaseCookbook(
        id: cookbookId,
        createdByUserId: owner.id,
        title: '',
      );
      _cookbooks.add(cookbook);
      _cookbooksStreamController.add(_cookbooks);
      return cookbook;
    } else {
      throw UserNotFoundException();
    }
  }

  Future<DatabaseUser> getUserByEmail({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabase();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'Email = ?',
      whereArgs: [email],
    );
    if (results.isNotEmpty) {
      return DatabaseUser.fromRow(results.first);
    } else {
      throw UserNotFoundException();
    }
  }

  Future<DatabaseUser> createUser({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabase();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'Email = ?',
      whereArgs: [email],
    );
    if (results.isEmpty) {
      final userId = await db.insert(
        userTable,
        {
          emailColumn: email.toLowerCase(),
          firstNameColumn: firstName,
          lastNameColumn: lastName,
        },
      );
      final user = DatabaseUser(
        id: userId,
        email: email,
        firstName: firstName,
        lastName: lastName,
      );
      return user;
    } else {
      throw UserAlreadyExistsException();
    }
  }

  Future<void> deleteUserByEmail({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabase();
    final deletedCount = await db.delete(
      userTable,
      where: 'Email = ?',
      whereArgs: [email],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUserException;
    }
  }

  Database _getDatabase() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsClosedException();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsClosedException();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      // empty
    }
  }

  Future<void> open() async {
    if (_db == null) {
      try {
        final docsPath = await getApplicationDocumentsDirectory();
        final dbPath = join(docsPath.path, dbName);
        final db = await openDatabase(dbPath);
        _db = db;

        await db.execute(createUserTable);
        await db.execute(createRecipeTable);
        await db.execute(createCookbookTable);
        await _cacheCookbooks(1); // TODO fix this
      } on MissingPlatformDirectoryException {
        throw UnableToGetDocumentsDirectoryException();
      }
    } else {
      throw DatabaseAlreadyOpenException();
    }
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;
  final String firstName;
  final String lastName;

  const DatabaseUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String,
        firstName = map[emailColumn] as String,
        lastName = map[emailColumn] as String;

  @override
  String toString() => 'User, Id = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class DatabaseRecipe {
  final int id;
  final int cookbookId;
  final String title;
  final String ingredients;
  final String instructions;
  final String imageURL;
  final int createdByUserId;

  const DatabaseRecipe({
    required this.id,
    required this.cookbookId,
    required this.title,
    required this.ingredients,
    required this.instructions,
    required this.imageURL,
    required this.createdByUserId,
  });

  DatabaseRecipe.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        cookbookId = map[cookbookIdColumn] as int,
        title = map[titleColumn] as String,
        ingredients = map[ingredientsColumn] as String,
        instructions = map[instructionsColumn] as String,
        imageURL = map[imageUrlColumn] as String,
        createdByUserId = map[createdByUserIdColumn] as int;

  @override
  String toString() => 'Recipe, Id = $id, Title = $title';

  @override
  bool operator ==(covariant DatabaseRecipe other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class DatabaseCookbook {
  final int id;
  final String title;
  // final String description;
  // final String coverImageUrl;
  // final String primaryColor;
  // final String secondaryColor;
  // final String pattern;
  final int createdByUserId;

  const DatabaseCookbook({
    required this.id,
    required this.title,
    // required this.description,
    // required this.coverImageUrl,
    // required this.primaryColor,
    // required this.secondaryColor,
    // required this.pattern,
    required this.createdByUserId,
  });

  DatabaseCookbook.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        title = map[titleColumn] as String,
        // description = map[descriptionColumn] as String,
        // coverImageUrl = map[coverImageUrlColumn] as String,
        // primaryColor = map[primaryColorColumn] as String,
        // secondaryColor = map[secondaryColorColumn] as String,
        // pattern = map[patternColumn] as String,
        createdByUserId = map[createdByUserIdColumn] as int;

  @override
  String toString() => 'Cookbook, Id = $id, Title = $title';

  @override
  bool operator ==(covariant DatabaseCookbook other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// shared column names
const idColumn = 'Id';
const titleColumn = 'Title';
const createdByUserIdColumn = 'CreatedByUserId';

// recipe column names
const cookbookIdColumn = 'CookbookId';
const ingredientsColumn = 'Ingredients';
const instructionsColumn = 'Instructions';
const imageUrlColumn = 'ImageURL';

// cookbook column names
const descriptionColumn = 'DescriptionColumn';
const coverImageUrlColumn = 'CoverImageURL';
const primaryColorColumn = 'PrimaryColor';
const secondaryColorColumn = 'SecondaryColor';
const patternColumn = 'Pattern';

// user column names
const usernameColumn = 'Username';
const passwordHashColumn = 'PasswordHash';
const emailColumn = 'Email';
const firstNameColumn = 'FirstName';
const lastNameColumn = 'LastName';

// database constants
const dbName = 'testing.db';
const recipeTable = 'Recipe';
const userTable = 'User';
const cookbookTable = 'Cookbook';

// create table statements
const createUserTable = '''
  CREATE TABLE IF NOT EXISTS "User" (
    "Id"	INTEGER,
    "Email"	TEXT NOT NULL UNIQUE,
    "FirstName"	TEXT,
    "LastName"	TEXT,
    PRIMARY KEY("Id" AUTOINCREMENT)
  );''';

const createRecipeTable = '''
  CREATE TABLE IF NOT EXISTS "Recipe" (
    "Id"	INTEGER,
    "CookbookId"	INTEGER,
    "Title"	INTEGER NOT NULL,
    "Ingredients"	INTEGER,
    "Instructions"	INTEGER,
    "ImageURL"	BLOB,
    "CreatedByUserId"	INTEGER,
    FOREIGN KEY("CookbookId") REFERENCES "Cookbook"("Id"),
    FOREIGN KEY("CreatedByUserId") REFERENCES "User"("Id"),
    PRIMARY KEY("Id" AUTOINCREMENT)
  )''';

const createCookbookTable = '''
  CREATE TABLE IF NOT EXISTS "Cookbook" (
    "Id"	INTEGER,
    "Title"	TEXT NOT NULL,
    --"Description"	TEXT,
    --"CoverImageURL"	TEXT,
    --"PrimaryColor"	TEXT,
    --"SecondaryColor"	TEXT,
    --"Pattern"	TEXT,
    "CreatedByUserId"	INTEGER,
    FOREIGN KEY("CreatedByUserId") REFERENCES "User"("Id"),
    PRIMARY KEY("Id" AUTOINCREMENT)
  )''';
