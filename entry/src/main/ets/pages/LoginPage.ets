import { UserDatabaseHelper, User } from '../helper/UserDatabaseHelper';
import { AppConstants } from '../constants/AppConstants';
import { UserInfo } from '../entity/UserInfo';
import getContext from '@ohos.app.ability.common';
import Context from '@ohos.app.ability.common';

@Builder
export function LoginPageBuilder() {
  LoginPage()
}

@Component
export struct LoginPage {
  @Consume('pathStack') pathStack: NavPathStack;

  @State isLoginMode: boolean = true;

  async aboutToAppear() {
    const context = getContext() as Context;
    await UserDatabaseHelper.init(context);
  }
  @State username: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State nickname: string = '';
  @State isLoading: boolean = false;
  @State showToast: boolean = false;
  @State toastMessage: string = '';
  @State toastType: 'success' | 'error' | 'info' = 'info';

  showMessage(message: string, type: 'success' | 'error' | 'info' = 'info') {
    this.toastMessage = message;
    this.toastType = type;
    this.showToast = true;
    setTimeout(() => {
      this.showToast = false;
    }, 2000);
  }

  async handleLogin() {
    if (!this.username.trim()) {
      this.showMessage('请输入用户名', 'error');
      return;
    }
    if (!this.password.trim()) {
      this.showMessage('请输入密码', 'error');
      return;
    }

    this.isLoading = true;
    const user = await UserDatabaseHelper.login(this.username.trim(), this.password.trim());
    this.isLoading = false;

    if (user) {
      this.showMessage('登录成功！', 'success');
      
      const userInfo: UserInfo = new UserInfo();
      userInfo.userId = user.id;
      userInfo.nickname = user.nickname;
      userInfo.avatarUrl = user.avatarUrl;
      userInfo.vipType = 0;
      userInfo.follows = 0;
      userInfo.followeds = 0;
      userInfo.level = 1;
      
      AppStorage.set<string>(AppConstants.CACHE_USER, JSON.stringify(userInfo));
      AppStorage.set<boolean>('is_logged_in', true);
      
      setTimeout(() => {
        this.pathStack.pop();
      }, 1000);
    } else {
      this.showMessage('用户名或密码错误', 'error');
    }
  }

  async handleRegister() {
    if (!this.username.trim()) {
      this.showMessage('请输入用户名', 'error');
      return;
    }
    if (!this.password.trim()) {
      this.showMessage('请输入密码', 'error');
      return;
    }
    if (this.password.trim().length < 6) {
      this.showMessage('密码长度至少6位', 'error');
      return;
    }
    if (this.password !== this.confirmPassword) {
      this.showMessage('两次密码输入不一致', 'error');
      return;
    }

    this.isLoading = true;
    const exists = await UserDatabaseHelper.isUsernameExists(this.username.trim());
    
    if (exists) {
      this.isLoading = false;
      this.showMessage('用户名已存在', 'error');
      return;
    }

    const success = await UserDatabaseHelper.register(
      this.username.trim(), 
      this.password.trim(), 
      this.nickname.trim() || this.username.trim()
    );
    
    this.isLoading = false;

    if (success) {
      this.showMessage('注册成功！请登录', 'success');
      this.isLoginMode = true;
      this.username = '';
      this.password = '';
      this.confirmPassword = '';
      this.nickname = '';
    } else {
      this.showMessage('注册失败，请重试', 'error');
    }
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          Row() {
            Button('返回')
              .fontSize(14)
              .fontColor('#007DFF')
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.pathStack.pop();
              })
            Blank()
            Text(this.isLoginMode ? '登录' : '注册')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ff333333')
            Blank()
            Text('')
              .width(40)
          }
          .width('100%')
          .padding({ top: 12, bottom: 12, left: 16, right: 16 })

          Column() {
            SymbolGlyph($r('sys.symbol.person'))
              .fontSize(64)
              .fontColor(['#E3323D'])
              .margin({ bottom: 32 })
          }
          .width('100%')
          .padding({ top: 60 })
          .justifyContent(FlexAlign.Center)

          Column({ space: 16 }) {
            Column({ space: 8 }) {
              Text('用户名')
                .fontSize(14)
                .fontColor('#ff666666')
                .width('100%')
                .textAlign(TextAlign.Start)
              
              TextInput({ placeholder: '请输入用户名' })
                .width('100%')
                .height(48)
                .backgroundColor('#fff5f5f5')
                .borderRadius(12)
                .padding({ left: 16, right: 16 })
                .onChange((value: string) => {
                  this.username = value;
                })
            }

            if (!this.isLoginMode) {
              Column({ space: 8 }) {
                Text('昵称')
                  .fontSize(14)
                  .fontColor('#ff666666')
                  .width('100%')
                  .textAlign(TextAlign.Start)
                
                TextInput({ placeholder: '请输入昵称（可选）' })
                  .width('100%')
                  .height(48)
                  .backgroundColor('#fff5f5f5')
                  .borderRadius(12)
                  .padding({ left: 16, right: 16 })
                  .onChange((value: string) => {
                    this.nickname = value;
                  })
              }
            }

            Column({ space: 8 }) {
              Text('密码')
                .fontSize(14)
                .fontColor('#ff666666')
                .width('100%')
                .textAlign(TextAlign.Start)
              
              TextInput({ placeholder: '请输入密码' })
                .width('100%')
                .height(48)
                .backgroundColor('#fff5f5f5')
                .borderRadius(12)
                .padding({ left: 16, right: 16 })
                .type(InputType.Password)
                .onChange((value: string) => {
                  this.password = value;
                })
            }

            if (!this.isLoginMode) {
              Column({ space: 8 }) {
                Text('确认密码')
                  .fontSize(14)
                  .fontColor('#ff666666')
                  .width('100%')
                  .textAlign(TextAlign.Start)
                
                TextInput({ placeholder: '请再次输入密码' })
                  .width('100%')
                  .height(48)
                  .backgroundColor('#fff5f5f5')
                  .borderRadius(12)
                  .padding({ left: 16, right: 16 })
                  .type(InputType.Password)
                  .onChange((value: string) => {
                    this.confirmPassword = value;
                  })
              }
            }

            Button(this.isLoading ? '处理中...' : (this.isLoginMode ? '登录' : '注册'))
              .width('100%')
              .height(48)
              .backgroundColor('#E3323D')
              .fontColor(Color.White)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .borderRadius(24)
              .margin({ top: 20 })
              .onClick(() => {
                if (!this.isLoading) {
                  if (this.isLoginMode) {
                    this.handleLogin();
                  } else {
                    this.handleRegister();
                  }
                }
              })

            Row() {
              Text(this.isLoginMode ? '还没有账号？' : '已有账号？')
                .fontSize(14)
                .fontColor('#ff999999')
              Text(this.isLoginMode ? '立即注册' : '立即登录')
                .fontSize(14)
                .fontColor('#E3323D')
                .margin({ left: 4 })
                .onClick(() => {
                  this.isLoginMode = !this.isLoginMode;
                  this.username = '';
                  this.password = '';
                  this.confirmPassword = '';
                  this.nickname = '';
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 16 })
          }
          .width('100%')
          .padding({ left: 24, right: 24 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F4F4F4')

        if (this.showToast) {
          Column() {
            Text(this.toastMessage)
              .fontSize(14)
              .fontColor(Color.White)
              .padding({ left: 20, right: 20, top: 12, bottom: 12 })
          }
          .backgroundColor(this.toastType === 'success' ? '#52C41A' : (this.toastType === 'error' ? '#FF4D4F' : '#1890FF'))
          .borderRadius(20)
          .shadow({ radius: 10, color: 'rgba(0,0,0,0.2)', offsetY: 4 })
        }
      }
    }
    .hideTitleBar(true)
  }
}