# AlienFX-For-MacOS

### 20220726
1. Fixed sleep/wake related issue

Control your logo&amp;keyboard light of Alienware FX in Mac OS

Screenshot:

<img width="212" alt="QQ20210925-231546@2x" src="https://user-images.githubusercontent.com/46492291/134776461-233dca24-75b6-480a-880a-69981de9bdf9.png">

Note:

This project contains AlienFX_SDK.h & AlienFX_SDK.cpp which can be used to control AlienFX under Mac OS.

The test APP can automatically turn off keyboard light when built-in screen goes off, and turn on agian when screen goes on.

The test APP is wrote for Alienware Area51m R2, other model may have different configuration and venderID or productID.

If you want to use it in other model, try to use the raw AlienFX_SDK.h & AlienFX_SDK.cpp, or you can try change the verderID & productID and test if it works.

This code is port from: https://github.com/T-Troll/alienfx-tools, and thanks to @T-Troll for having done such a great job.

Haven't done much test and only tested the brightness, if you want more functionality, just fork and modify.
