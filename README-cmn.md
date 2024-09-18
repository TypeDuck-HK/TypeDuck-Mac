README in [粵語(Cantonese)](README.md) | [English](README-en.md)

# TypeDuck for macOS
兼容性: macOS 12 Monterey 或者更高。

## 如何安裝（How to install）
1. 首先去 [Releases](https://github.com/TypeDuck-HK/TypeDuck-Mac/releases) 頁面下載 PKG 文件。
2. 雙擊開啟下載到的 PKG 文件，開始安裝。
3. 按提示步驟進行。中途有可能系統設置App會彈出來，請求添加 TypeDuck 輸入法。
4. 到最後一步，安裝程序會請求你登出電腦。要登出、再登入，Mac 輸入法才會正常生效。

**請注意**: 登出電腦會將所有程序結束運行。

安裝之後，如果看不到有 TypeDuck 輸入法，請前往 系統設置App → 鍵盤 → 輸入方式，手動添加。  
添加的時候，可以在「Cantonese, Traditional」/繁體粵語/繁體廣東話 語言項找到 TypeDuck，也可以搜索「TypeDuck」來找。


<img width="300" alt="Screenshot 1" src="images/screenshot-step-1-and-2.png"/><img width="300" alt="Screenshot 2" src="images/screenshot-step-3.png"/>
<br>
<img width="300" alt="Screenshot 3" src="images/screenshot-step-4-and-5.png"/><img width="300" alt="Screenshot 4" src="images/screenshot-step-6.png"/>


## 如何卸載（How to uninstall）
首先，去 系統設置App → 鍵盤 → 輸入方式，移除 TypeDuck。  
然後，刪除以下文件／文件夾：
~~~bash
/Library/Input\ Methods/TypeDuck.app
~/Library/Application\ Scripts/hk.eduhk.inputmethod.TypeDuck
~/Library/Containers/hk.eduhk.inputmethod.TypeDuck
~~~

最後，登出電腦再登入，或者重啟電腦。


## 如何構建（How to build）
前置要求（Build requirements）
- macOS 14.0+
- Xcode 15.4+

先構建數據庫 (Prepare databases)
~~~bash
# cd path/to/TypeDuck-Mac
cd ./Preparing/
swift run -c release
~~~
然後用 Xcode 開啟 `TypeDuck.xcodeproj` 即可。  
注意事項: 不要直接在 Xcode 按 Run，只可以 Build 或 [Archive](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases#Create-an-archive-of-your-app)


如果要在自己本機測試，請將 Archive & Export 出來的 TypeDuck.app 放入 `/Library/Input\ Methods/` 文件夾。  
如果替換舊有 TypeDuck.app 的時候，彈提示説它正在運行、無法替換，可以到 Terminal 用以下命令將它結束運行：
~~~bash
osascript -e 'tell application id "hk.eduhk.inputmethod.TypeDuck" to quit'
~~~


如果想要替換 CSV 詞庫，請替換 `./Preparing/Sources/Preparing/Resources/data.csv` 文件，再依上文重新構建一次數據庫。
