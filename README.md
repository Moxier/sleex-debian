# Sleex on Debian

สคริปต์ติดตั้ง [Sleex](https://github.com/AxOS-project/Sleex) (Desktop Environment ของ AxOS ที่ใช้ Hyprland + Quickshell) บน Debian และ distro ที่ใช้ Debian เป็นฐาน

Installer for the [Sleex](https://github.com/AxOS-project/Sleex) desktop (AxOS, Hyprland + Quickshell) on Debian-based distros.

> [!NOTE]
> ทดสอบแล้วบนเครื่องจริง: **PikaOS 4** (Debian sid, Hyprland 0.57) ติดตั้งคู่กับ desktop เดิมของ PikaOS ได้โดยไม่ลบอะไร
> Tested on real hardware: **PikaOS 4** (Debian sid, Hyprland 0.57), side by side with PikaOS's own desktop.
>
> Debian 13 / testing / sid แบบเพียวยังไม่ได้ทดสอบ / Plain Debian not tested yet.

## ความต้องการ / Requirements

- amd64 (x86_64)
- Hyprland **≥ 0.55** (Sleex ใช้ config แบบ Lua)
- Quickshell และ Qt ≥ 6.8

| Distro | สถานะ |
|---|---|
| PikaOS 4 | ✅ ทดสอบแล้ว |
| Debian 13 (trixie) | ⚠️ ยังไม่ได้ทดสอบ (เปิด `trixie-backports` ให้อัตโนมัติ) |
| Debian testing / sid | ⚠️ ยังไม่ได้ทดสอบ |
| Ubuntu / Mint | ❌ Hyprland ใน repo ยังเก่ากว่า 0.55 (สคริปต์จะหยุดตั้งแต่ต้น) |

## วิธีใช้ / Usage

```bash
git clone https://github.com/Moxier/sleex-debian
cd sleex-debian
sudo ./install-sleex-debian.sh 2>&1 | tee install.log
```

จากนั้น logout แล้วเลือก session **Sleex** ที่หน้า login
Then log out and choose the **Sleex** session in your display manager.

ถ้ามีปัญหา แนบ `install.log` มาตอนแจ้ง issue ด้วย / Attach `install.log` when reporting issues.

## ตั้งค่าภาษาไทย / Thai keyboard (Alt+Space)

ใส่ไว้ที่ `~/.config/sleex/custom/general.lua` (Sleex โหลดหลัง config หลัก และอัปเดตไม่ทับ):

```lua
hl.config({
    input = {
        kb_layout = "us,th",
        kb_variant = ",",
        kb_options = "grp:alt_space_toggle",
    },
})
```

แล้ว logout/login ใหม่ หรือ `hyprctl reload` ถ้าไม่ตั้งเอง Sleex จะอ่านค่าจาก `/etc/default/keyboard`

## สคริปต์ทำอะไรบ้าง / What it does

1. เช็กเวอร์ชัน Hyprland / Quickshell / Qt ก่อนเริ่ม ถ้าไม่ถึงจะหยุดทันที
2. ติดตั้ง dependency จาก PKGBUILD ของ Arch ที่แปลงเป็นชื่อแพ็กเกจ Debian
   - ตัวที่ไม่มีใน repo จะข้าม
   - **ตัวที่ติดตั้งแล้วต้องลบแพ็กเกจที่มีอยู่จะข้าม** (เช่นบน PikaOS: `power-profiles-daemon` ชนกับ `tuned-ppd`)
   - สรุปรายการที่ข้ามให้ดูตอนจบ
3. Build จาก source: ปลั๊กอิน QML ของ Sleex, `sleex-ui-kit`, `sleex-welcome-screen`, `hypnos`
4. ดาวน์โหลดของที่ Arch ได้จาก AUR: matugen, เคอร์เซอร์ Bibata, ธีม adw-gtk3, ฟอนต์ (Material Symbols, Gabarito, Rubik, Readex Pro, JetBrains Mono Nerd), hyprshot, papirus-folders
5. แพตช์สำหรับ Debian:
   - อ่าน layout คีย์บอร์ดจาก `/etc/default/keyboard` แทน `/etc/vconsole.conf` ของ Arch
   - `qt_standard_project_setup(REQUIRES 6.9)` → 6.8 (เฉพาะเมื่อ Qt < 6.9)
   - กฎ polkit กลุ่ม `wheel` → `sudo`
   - venv แยกสำหรับ `materialyoucolor` (ไม่ pip ลงระบบ)
   - ปุ่ม power saver ใช้ `busctl` แทน `powerprofilesctl` ถ้าเครื่องใช้ `tuned-ppd`
   - ใช้ `Hyprland` ตรงๆ ถ้าไม่มี `start-hyprland`
6. คัดลอก config เริ่มต้นให้ผู้ใช้ที่รัน sudo **โดยไม่ทับไฟล์เดิม**

## ปัญหาที่เจอบ่อย / Troubleshooting

**ไอคอน/ธีมใน file manager หาย** — ถ้ามี `~/.config/qt6ct/qt6ct.conf` อยู่ก่อนแล้ว (เช่นของ PikaOS) สคริปต์จะไม่ทับ แอป Qt เลยใช้ธีมไอคอนเดิมที่ Sleex อาจหาไม่เจอ แก้โดย (มีผลกับ desktop เดิมด้วย เพราะใช้ไฟล์ร่วมกัน):

```bash
cp ~/.config/qt6ct/qt6ct.conf ~/.config/qt6ct/qt6ct.conf.bak
sed -i 's/^icon_theme=.*/icon_theme=Papirus-Dark/; s/^style=.*/style=kvantum/' ~/.config/qt6ct/qt6ct.conf
```

**แอป Flatpak ไม่ขึ้นใน launcher** — ถ้าเพิ่งติดตั้งแอป Flatpak ระหว่างใช้ Sleex ให้ logout/login ใหม่

## ข้อจำกัดที่รู้อยู่ / Known limitations

- ถ้าปลั๊กอินของ Sleex ใช้ API เฉพาะ Qt 6.9 จะ build ไม่ผ่านบน Debian 13 (testing/sid ไม่มีปัญหา)
- API ของ Lua config ใน Hyprland 0.55 (backports) อาจต่างจากเวอร์ชันที่ AxOS ใช้
- `hypnos` อาจ build ไม่ผ่านถ้า Rust ของ Debian เก่าไป → ฟีเจอร์ idle/auto-lock ใช้ไม่ได้ (สคริปต์เตือนแล้วทำต่อ)
- ไม่รวม: Howdy (สแกนหน้า), Mission Center, breeze-plus, สคริปต์ uninstall

## License

GPL-3.0 เหมือนกับ Sleex ต้นทาง / GPL-3.0, same as upstream Sleex.
