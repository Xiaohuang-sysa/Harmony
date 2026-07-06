import relationalStore from '@ohos.data.relationalStore';
import { BusinessError } from '@ohos.base';
import Context from '@ohos.app.ability.common';

export interface User {
  id: number;
  username: string;
  password: string;
  nickname: string;
  avatarUrl: string;
  createdAt: number;
}

export class UserDatabaseHelper {
  private static rdbStore: relationalStore.RdbStore | null = null;
  private static appContext: Context | null = null;
  private static readonly DB_NAME = 'hw_music_users.db';
  private static readonly DB_VERSION = 1;

  private static readonly CREATE_TABLE_SQL = `
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      nickname TEXT DEFAULT '',
      avatarUrl TEXT DEFAULT '',
      createdAt INTEGER NOT NULL
    )
  `;

  private static readonly CREATE_SESSION_TABLE_SQL = `
    CREATE TABLE IF NOT EXISTS user_session (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL UNIQUE,
      username TEXT NOT NULL,
      nickname TEXT DEFAULT '',
      avatarUrl TEXT DEFAULT '',
      login_time INTEGER NOT NULL
    )
  `;

  static setContext(context: Context): void {
    UserDatabaseHelper.appContext = context;
  }

  private static async ensureInit(): Promise<void> {
    if (UserDatabaseHelper.rdbStore) {
      return;
    }
    if (!UserDatabaseHelper.appContext) {
      throw new Error('Context not set. Call setContext() first.');
    }
    await UserDatabaseHelper.init(UserDatabaseHelper.appContext);
  }

  static async init(context: Context): Promise<void> {
    if (UserDatabaseHelper.rdbStore) {
      return;
    }
    UserDatabaseHelper.appContext = context;

    try {
      const config: relationalStore.StoreConfig = {
        name: UserDatabaseHelper.DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1
      };

      UserDatabaseHelper.rdbStore = await relationalStore.getRdbStore(context, config);
      await UserDatabaseHelper.rdbStore.executeSql(UserDatabaseHelper.CREATE_TABLE_SQL);
      await UserDatabaseHelper.rdbStore.executeSql(UserDatabaseHelper.CREATE_SESSION_TABLE_SQL);
    } catch (err) {
      console.error(`UserDatabaseHelper init failed: ${JSON.stringify(err)}`);
      throw new Error(`UserDatabaseHelper init failed: ${JSON.stringify(err)}`);
    }
  }

  static async register(username: string, password: string, nickname: string = ''): Promise<boolean> {
    await UserDatabaseHelper.ensureInit();

    try {
      const values: relationalStore.ValuesBucket = {
        username: username,
        password: password,
        nickname: nickname || username,
        avatarUrl: '',
        createdAt: Date.now()
      };

      const result = await UserDatabaseHelper.rdbStore!.insert('users', values);
      return result > 0;
    } catch (err) {
      console.error(`UserDatabaseHelper register failed: ${JSON.stringify(err)}`);
      return false;
    }
  }

  static async login(username: string, password: string): Promise<User | null> {
    await UserDatabaseHelper.ensureInit();

    try {
      const predicates = new relationalStore.RdbPredicates('users');
      predicates.equalTo('username', username);

      const result = await UserDatabaseHelper.rdbStore!.query(predicates, ['*']);
      
      if (result.rowCount > 0) {
        await result.goToFirstRow();
        
        const user: User = {
          id: result.getLong(result.getColumnIndex('id')),
          username: result.getString(result.getColumnIndex('username')),
          password: result.getString(result.getColumnIndex('password')),
          nickname: result.getString(result.getColumnIndex('nickname')),
          avatarUrl: result.getString(result.getColumnIndex('avatarUrl')),
          createdAt: result.getLong(result.getColumnIndex('createdAt'))
        };

        result.close();

        if (user.password === password) {
          return user;
        }
      }

      result.close();
      return null;
    } catch (err) {
      console.error(`UserDatabaseHelper login failed: ${JSON.stringify(err)}`);
      return null;
    }
  }

  static async getUserById(id: number): Promise<User | null> {
    await UserDatabaseHelper.ensureInit();

    try {
      const predicates = new relationalStore.RdbPredicates('users');
      predicates.equalTo('id', id);

      const result = await UserDatabaseHelper.rdbStore!.query(predicates, ['*']);
      
      if (result.rowCount > 0) {
        await result.goToFirstRow();
        
        const user: User = {
          id: result.getLong(result.getColumnIndex('id')),
          username: result.getString(result.getColumnIndex('username')),
          password: result.getString(result.getColumnIndex('password')),
          nickname: result.getString(result.getColumnIndex('nickname')),
          avatarUrl: result.getString(result.getColumnIndex('avatarUrl')),
          createdAt: result.getLong(result.getColumnIndex('createdAt'))
        };

        result.close();
        return user;
      }

      result.close();
      return null;
    } catch (err) {
      console.error(`UserDatabaseHelper getUserById failed: ${JSON.stringify(err)}`);
      return null;
    }
  }

  static async updateUser(user: User): Promise<boolean> {
    await UserDatabaseHelper.ensureInit();

    try {
      const values: relationalStore.ValuesBucket = {
        nickname: user.nickname,
        avatarUrl: user.avatarUrl
      };

      const predicates = new relationalStore.RdbPredicates('users');
      predicates.equalTo('id', user.id);

      const result = await UserDatabaseHelper.rdbStore!.update(values, predicates);
      return result > 0;
    } catch (err) {
      console.error(`UserDatabaseHelper updateUser failed: ${JSON.stringify(err)}`);
      return false;
    }
  }

  static async isUsernameExists(username: string): Promise<boolean> {
    await UserDatabaseHelper.ensureInit();

    try {
      const predicates = new relationalStore.RdbPredicates('users');
      predicates.equalTo('username', username);

      const result = await UserDatabaseHelper.rdbStore!.query(predicates, ['id']);
      const exists = result.rowCount > 0;
      result.close();
      return exists;
    } catch (err) {
      console.error(`UserDatabaseHelper isUsernameExists failed: ${JSON.stringify(err)}`);
      return false;
    }
  }

  // ==================== 登录会话管理（SQLite） ====================

  static async saveSession(userId: number, username: string, nickname: string, avatarUrl: string): Promise<void> {
    await UserDatabaseHelper.ensureInit();
    try {
      // 先清空旧会话（确保只有一条会话记录）
      await UserDatabaseHelper.rdbStore!.executeSql('DELETE FROM user_session');
      const values: relationalStore.ValuesBucket = {
        user_id: userId,
        username: username,
        nickname: nickname,
        avatarUrl: avatarUrl,
        login_time: Date.now()
      };
      await UserDatabaseHelper.rdbStore!.insert('user_session', values);
    } catch (err) {
      console.error(`UserDatabaseHelper saveSession failed: ${JSON.stringify(err)}`);
    }
  }

  static async loadSession(): Promise<User | null> {
    await UserDatabaseHelper.ensureInit();
    try {
      const result = await UserDatabaseHelper.rdbStore!.querySql(
        'SELECT * FROM user_session ORDER BY login_time DESC LIMIT 1'
      );
      if (result.rowCount > 0) {
        result.goToFirstRow();
        const user: User = {
          id: result.getLong(result.getColumnIndex('user_id')),
          username: result.getString(result.getColumnIndex('username')),
          password: '',
          nickname: result.getString(result.getColumnIndex('nickname')),
          avatarUrl: result.getString(result.getColumnIndex('avatarUrl')),
          createdAt: 0
        };
        result.close();
        return user;
      }
      result.close();
      return null;
    } catch (err) {
      console.error(`UserDatabaseHelper loadSession failed: ${JSON.stringify(err)}`);
      return null;
    }
  }

  static async clearSession(): Promise<void> {
    await UserDatabaseHelper.ensureInit();
    try {
      await UserDatabaseHelper.rdbStore!.executeSql('DELETE FROM user_session');
    } catch (err) {
      console.error(`UserDatabaseHelper clearSession failed: ${JSON.stringify(err)}`);
    }
  }
}