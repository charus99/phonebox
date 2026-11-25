# PhoneBox: ไฟล์ติดตั้งพร้อมหน้าจอของเรา

ใช้ติดตั้ง [PhoneBox](https://github.com/ersinkoc/phonebox) บนคอมเครื่องอื่น แล้วได้หน้าจอบนมือถือเหมือนเครื่องหลัก
ทั้ง 9 หน้า shortcut การตั้งค่าหน้าจอ และวิดเจ็ตแมว

## ติดตั้งบน Windows

1. ก๊อปไฟล์ **`install-pc.cmd`** ไปไว้ที่เครื่องนั้น (ไฟล์เดียวพอ) จะใช้ USB drive หรือดาวน์โหลดจาก
   [GitHub](https://github.com/charus99/phonebox/blob/custom/custom/install-pc.cmd) โดยกด **Download raw file** ก็ได้
2. เสียบมือถือ แล้วเปิด **USB debugging** ไว้ก่อน (Settings › About phone › แตะ Build number 7 ครั้ง
   แล้วไปที่ Developer options › USB debugging)
3. **ดับเบิลคลิก** `install-pc.cmd` (อย่าเลือก *Run as administrator*) แล้วตอบคำถามที่ขึ้นมา
   - *Start PhoneBox when you sign in to Windows?* ให้เปิดพร้อม Windows หรือไม่ ตามสะดวก
   - *Install the PhoneBox app on a phone connected over USB now?* ตอบ `Y` แล้วกดยืนยันบนมือถือ
4. เมื่อติดตั้งเสร็จ ไปใส่ URL ปฏิทินเองที่ **Settings › General** บนหน้า `http://127.0.0.1:8765`
   (URL ปฏิทินเป็นความลับ จึงไม่ได้เก็บไว้ใน repo นี้)

ถ้า Windows ขึ้นเตือนว่าเป็นไฟล์จากอินเทอร์เน็ต ให้กด **More info › Run anyway**

### เครื่องที่ใช้ได้

- Windows 10/11 แบบ 64-bit (x64) หรือ macOS บน Apple silicon (M1 ขึ้นไป) หรือ Intel
- ต้องต่ออินเทอร์เน็ต
- มือถือ Android 5.0 ขึ้นไป

### ตัวเลือก

พิมพ์ต่อท้ายชื่อไฟล์ใน Command Prompt หรือ PowerShell เช่น `install-pc.cmd -NoPhone`

| ตัวเลือก | ใช้เมื่อ |
|---|---|
| `-DryRun` | ลองดูว่าจะทำอะไรบ้างโดยไม่เปลี่ยนอะไรในเครื่อง |
| `-NoPhone` | ไม่ต้องลงแอปบนมือถือผ่าน USB |
| `-LayoutOnly` | เครื่องนี้มี PhoneBox อยู่แล้ว และอยากได้แค่หน้าจอ |
| `-Serial <id>` | เสียบมือถือไว้หลายเครื่อง (ดู id ได้จาก `adb devices`) |

## ติดตั้งบน Mac

1. ก๊อปไฟล์ **`install-mac.sh`** ไปไว้ที่ Mac (ไฟล์เดียวพอ) หรือดาวน์โหลดจาก
   [GitHub](https://github.com/charus99/phonebox/blob/custom/custom/install-mac.sh) โดยกด **Download raw file**
2. เสียบมือถือแล้วเปิด USB debugging ไว้ เหมือนบน Windows
3. เปิด **Terminal** แล้วรันคำสั่งข้างล่าง (ถ้าไฟล์อยู่ที่อื่น ให้เปลี่ยน `~/Downloads` เป็นโฟลเดอร์นั้น)
   ```sh
   cd ~/Downloads
   bash install-mac.sh --dry-run   # ลองดูก่อน ไม่เปลี่ยนอะไร
   bash install-mac.sh
   ```
   ไม่ต้องใส่ `sudo` ตัวติดตั้งจะถามเองถ้าต้องติดตั้งโปรแกรมเสริม เช่น adb ผ่าน Homebrew
4. ใส่ URL ปฏิทินเองที่ **Settings › General** บนหน้า `http://127.0.0.1:8765`

บน Mac ปุ่ม shortcut ทุกปุ่มจะหน้าตาเหมือนบน Windows แต่จะเปิดแอปของ Mac แทน เช่น Terminal จะเปิดด้วย
`open -a Terminal`, Files จะเปิด Finder, Task Manager จะเปิด Activity Monitor และ Snip จะเปิด Screenshot

ครั้งแรกที่ใช้ macOS อาจถามว่าจะยอมให้ PhoneBoxAgent ควบคุม Music/Spotify หรือรับการเชื่อมต่อไหม ให้กด Allow
ส่วน shortcut ที่กดคีย์ลัดต้องเปิดสิทธิ์ที่ **System Settings › Privacy & Security › Accessibility** ก่อน

ตัวเลือกบน Mac: `--dry-run`, `--no-phone`, `--layout-only`, `--serial <id>`

## ลงแอปบนมือถือเครื่องใหม่

ไม่ต้องเก็บไฟล์ APK ไว้เอง เลือกวิธีไหนก็ได้

1. **ระหว่างติดตั้งบนคอม**: ตอนรัน `install-pc.cmd` หรือ `install-mac.sh` ให้ตอบ `Y` ที่คำถาม
   *Install the PhoneBox app on a phone connected over USB now?* แล้ว setup จะโหลดแอปรุ่นที่ตรงกับคอม
   ตรวจ checksum และลงให้
2. **คอมมี PhoneBox อยู่แล้ว**: เสียบมือถือ (เปิด USB debugging ไว้) แล้วไปที่ `http://127.0.0.1:8765` ›
   **Settings › General › Install the phone app**
3. **ไม่ใช้คอม**: เปิด <https://github.com/ersinkoc/phonebox/releases/latest> บนมือถือ โหลด `PhoneBox-x.y.z.apk`
   แล้วแตะติดตั้ง (มือถือจะถามให้อนุญาตการติดตั้งแอปที่ไม่ได้มาจาก Play Store) ถ้าลงแบบนี้แต่จะใช้แบบเสียบสาย
   ต้องเปิด USB debugging ด้วย

ถ้าเสียบมือถือเครื่องเดิมเข้าคอมอีกเครื่อง ไม่ต้องลงแอปใหม่และไม่ต้องตั้งค่าอะไรบนมือถือ แค่กด **Allow** ตอนมือถือถาม
*Allow USB debugging?* ครั้งแรก หน้าจอที่แสดงจะเป็น layout ของคอมเครื่องที่เสียบอยู่

### ถ้าเครื่องนั้นมี PhoneBox อยู่แล้ว

ไฟล์ติดตั้งจะถามก่อนว่าจะแทนที่หน้าจอเดิมไหม ถ้าตอบ `y` ระบบจะเก็บสำรองของ `config.json` ไว้ที่
`%APPDATA%\PhoneBox\config.json.before-layout-<วันเวลา>` (บน Mac อยู่ที่
`~/Library/Application Support/PhoneBox/`) ถ้าอยากได้หน้าจอเดิมกลับคืน ให้ปิด PhoneBox แล้วก๊อปไฟล์สำรองนั้นทับ
`config.json`

## ไฟล์ในโฟลเดอร์นี้

| ไฟล์ | หน้าที่ |
|---|---|
| `install-pc.cmd` | ไฟล์ที่ดับเบิลคลิกเพื่อติดตั้งบน Windows |
| `install-mac.sh` | ไฟล์ติดตั้งบน Mac (รันใน Terminal) |
| `install.ps1` | ไฟล์ติดตั้งโหลดมาเอง: รัน `setup.ps1` ของ PhoneBox แล้วใส่หน้าจอ |
| `layout.json` | หน้าจอของเรา: หน้า shortcut การตั้งค่าหน้าจอ โหมดกลางคืน และเมืองพยากรณ์อากาศ |
| `export-layout.ps1` | ดึงหน้าจอปัจจุบันของเครื่องนี้ออกมาเป็น `layout.json` |
| `widgets/cat.html` | โค้ดวิดเจ็ตแมว (มีอยู่ใน `layout.json` แล้ว เก็บไว้แก้ไขต่อ) |

## ความปลอดภัย

- repo นี้เป็น **public** ใครก็เปิดดูได้ `layout.json` จึงไม่มี token, key หรือ URL ปฏิทิน
  `export-layout.ps1` ดึงออกมาเฉพาะ 5 ส่วนข้างบน และจะเตือนถ้าเจอ URL
- ไฟล์ทุกไฟล์ที่โหลดมาถูกล็อกไว้ที่ commit หนึ่ง และตรวจ SHA-256 ก่อนใช้ ถ้าไม่ตรงจะหยุดโดยไม่ติดตั้งอะไร
  ส่วนตัวโปรแกรม PhoneBox เอง `setup.ps1` จะโหลดเวอร์ชันล่าสุดและตรวจ checksum ของมันอีกชั้นหนึ่ง

## อัปเดตหน้าจอหลังแก้บนเครื่องหลัก

1. รัน `.\custom\export-layout.ps1` แล้วอ่านคำเตือนเรื่อง URL ที่พิมพ์ออกมา
2. ใส่ SHA-256 ใหม่ของ `layout.json` ลงใน `$LayoutSha256` ของ `install.ps1` แล้ว commit และ push
3. ใส่ commit นั้นกับ SHA-256 ของ `install.ps1` ลงใน `COMMIT` และ `SHA256` ของ `install-pc.cmd`
   และใส่ commit เดียวกันกับ SHA-256 ของ `layout.json` ลงใน `COMMIT` และ `LAYOUT_SHA256` ของ `install-mac.sh`
   แล้ว commit และ push อีกรอบ

ต้องทำสองรอบ เพราะไฟล์ติดตั้งอ้างถึง commit ของตัวเองไม่ได้ ก่อนใช้ควรทดสอบกับ agent แยกก่อน
(`PhoneBoxAgent.exe --config <โฟลเดอร์ทดสอบ>\config.json --port 18765`)
