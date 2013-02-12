package com.mobileapptracker;

import android.content.ContentProvider;
import android.content.ContentUris;
import android.content.ContentValues;
import android.content.Context;
import android.content.UriMatcher;
import android.database.Cursor;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.database.sqlite.SQLiteQueryBuilder;
import android.net.Uri;
import android.util.Log;

public class MATProvider extends ContentProvider {
    public static final String _ID = "_id";
    public static final String PUBLISHER_PACKAGE_NAME = "publisher_package_name";
    public static final String TRACKING_ID = "tracking_id";

    private static final int REFERRER_APPS = 1;

    private static final UriMatcher uriMatcher;
    static {
        uriMatcher = new UriMatcher(UriMatcher.NO_MATCH);
        uriMatcher.addURI("*", "referrer_apps", REFERRER_APPS);
    }

    private SQLiteDatabase matDB;
    private static final String DATABASE_NAME = "MAT";
    private static final String DATABASE_TABLE = "referrer_apps";
    private static final int DATABASE_VERSION = 1;
    private static final String DATABASE_CREATE =
          "create table " + DATABASE_TABLE
          + " (_id integer primary key autoincrement, "
          + PUBLISHER_PACKAGE_NAME + " text not null, "
          + TRACKING_ID + " text, "
          + "unique(publisher_package_name) on conflict replace);";

    private static class DatabaseHelper extends SQLiteOpenHelper {
       DatabaseHelper(Context context) {
           super(context, DATABASE_NAME, null, DATABASE_VERSION);
       }

       @Override
       public void onCreate(SQLiteDatabase db) {
          db.execSQL(DATABASE_CREATE);
       }

       @Override
       public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
          Log.w("Content provider database",
               "Upgrading database from version "
               + oldVersion + " to " 
               + newVersion
               + ", which will destroy all old data");
          db.execSQL("DROP TABLE IF EXISTS siteids");
          onCreate(db);
       }
    }

    @Override
    public int delete(Uri uri, String selection, String[] selectionArgs) {
        int count = 0;
        switch (uriMatcher.match(uri)) {
           case REFERRER_APPS:
              count = matDB.delete(
                 DATABASE_TABLE,
                 selection, 
                 selectionArgs);
              break;
           default: throw new IllegalArgumentException(
              "Unknown URI " + uri);
        }
        getContext().getContentResolver().notifyChange(uri, null);
        return count;
    }

    @Override
    public String getType(Uri uri) {
        switch (uriMatcher.match(uri)) {
            // Get all site ids
            case REFERRER_APPS:
                return "vnd.android.cursor.dir/vnd.mobileapptracker.referrer_apps ";
            default:
                throw new IllegalArgumentException("Unsupported URI: " + uri);
        }
    }

    @Override
    public Uri insert(Uri uri, ContentValues values) {
        // Add a new site id
        long rowID = matDB.insert(DATABASE_TABLE, "", values);

        // If added successfully
        if (rowID > 0) {
           Uri _uri = ContentUris.withAppendedId(uri, rowID);
           getContext().getContentResolver().notifyChange(_uri, null);
           return _uri;
        }
        throw new SQLException("Failed to insert row into " + uri);
    }

    @Override
    public boolean onCreate() {
        Context context = getContext();
        DatabaseHelper dbHelper = new DatabaseHelper(context);
        matDB = dbHelper.getWritableDatabase();
        return (matDB == null) ? false : true;
    }

    @Override
    public Cursor query(Uri uri, String[] projection, String selection, String[] selectionArgs, String sortOrder) {
        SQLiteQueryBuilder sqlBuilder = new SQLiteQueryBuilder();
        sqlBuilder.setTables(DATABASE_TABLE);

        if (sortOrder == null || sortOrder == "")
           sortOrder = PUBLISHER_PACKAGE_NAME;

        Cursor c = sqlBuilder.query(
            matDB,
            projection,
            selection,
            selectionArgs,
            null,
            null,
            sortOrder);

        // Register to watch a content URI for changes
        c.setNotificationUri(getContext().getContentResolver(), uri);
        return c;
    }

    @Override
    public int update(Uri uri, ContentValues values, String selection, String[] selectionArgs) {
        int count = 0;
        switch (uriMatcher.match(uri)) {
           case REFERRER_APPS:
              count = matDB.update(
                 DATABASE_TABLE, 
                 values,
                 selection, 
                 selectionArgs);
              break;
           default: throw new IllegalArgumentException("Unknown URI " + uri);
        }
        getContext().getContentResolver().notifyChange(uri, null);
        return count;
    }
}
