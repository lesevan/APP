# 使用: 工作流 编译APP

```js
name: Build IPA

on:
  push:
    branches: [ "main" ]
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-15
    steps:
     - uses: actions/checkout@v3
     - name: Compile
       run: make
     
     - name: Upload artifact
       uses: actions/upload-artifact@v4
       with:
        name: APP
        path: APP.ipa
```

# make文件 内容
```js
BASEDIR = $(shell pwd)
BUILD_DIR = $(BASEDIR)/build
INSTALL_DIR = $(BUILD_DIR)/install
PROJECT = $(BASEDIR)/APP.xcodeproj
SCHEME = APP
CONFIGURATION = Release
SDK = iphoneos
DERIVED_DATA_PATH = $(BUILD_DIR)

all: ipa

# 依赖关系
ipa: $(PROJECT)
	mkdir -p ./build
	xcodebuild -jobs 8 -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -sdk $(SDK) -derivedDataPath $(DERIVED_DATA_PATH) CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO DSTROOT=$(INSTALL_DIR)
	rm -rf ./build/APP.ipa
	rm -rf ./build/Payload
	mkdir -p ./build/Payload
	cp -rv ./build/Build/Products/Release-iphoneos/APP.app ./build/Payload
	cd ./build && zip -r APP.ipa Payload
	mv ./build/APP.ipa ./

# 强制重新构建
force: clean ipa

clean:
	rm -rf ./build
	rm -rf ./APP.ipa

.PHONY: all ipa clean force
```

![Preview](./X/x.png)

---

# 使用: Theos 去编译 APP.ipa 方法
### 终端: cd APP这文件夹
### 终端: make


```js
终端执行 克隆 Theos 仓库
git clone --recursive https://github.com/theos/theos.git

将 Theos 的路径添加到环境变量中：
方法一：
终端执行 直接添加到 ~/theos

export THEOS=~/theos
export PATH=$THEOS/bin:$PATH

终端执行  重新 加载配置：
source ~/.zshrc

另一种方法：
终端执行 打开配置文件 .zshrc
nano ~/.zshrc

# Theos 配置  // theos文件夹 的本地路径
export THEOS=/Users/pxx917144686/theos     

之后；contron + X 是退出编辑； 按‘y’ 保存编辑退出！

终端执行  重新 加载配置：
source ~/.zshrc
```

</td>
</tr>
</table>

</details>

---

<!-- 左右排列 -->
<div style="display: flex; justify-content: space-evenly; align-items: center; width: 100%; overflow: auto; gap: 40px; padding: 10px 0;">
    <img src="./X/1.PNG" alt="Preview" width="300" />
    <img src="./X/2.PNG" alt="Preview" width="300" />
    <img src="./X/3.PNG" alt="Preview" width="300" />
    <img src="./X/4.PNG" alt="Preview" width="300" />
    <img src="./X/5.PNG" alt="Preview" width="300" />
    <img src="./X/6.PNG" alt="Preview" width="300" />
</div>

<hr style="border: 1px solid #ccc; margin: 20px 0;">

---

<!-- 左右排列 -->
<div style="display: flex; justify-content: space-evenly; align-items: center; width: 100%; overflow: auto; gap: 40px; padding: 10px 0;">
    <img src="./X/7.PNG" alt="Preview" width="300" />
    <img src="./X/8.PNG" alt="Preview" width="300" />
    <img src="./X/9.PNG" alt="Preview" width="300" />
    <img src="./X/10.PNG" alt="Preview" width="300" />
    <img src="./X/11.PNG" alt="Preview" width="300" />
    <img src="./X/12.PNG" alt="Preview" width="300" />
</div>

<hr style="border: 1px solid #ccc; margin: 20px 0;">
