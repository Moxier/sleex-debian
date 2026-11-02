# Sleex on Debian

สคริปต์ติดตั้ง [Sleex](https://github.com/AxOS-project/Sleex) (Desktop Environment ของ AxOS ที่ใช้ Hyprland + Quickshell) บน Debian และ distro ที่ใช้ Debian เป็นฐาน

Installer for the [Sleex](https://github.com/AxOS-project/Sleex) desktop (AxOS, Hyprland + Quickshell) on Debian-based distros.

> [!WARNING]
> ยังไม่ได้ทดสอบบนเครื่อง Debian จริง ควรลองใน VM ก่อน
> Not yet tested on real Debian hardware — try it in a VM first.

## ความต้องการ / Requirements

- amd64 (x86_64)
- Hyprland **≥ 0.55** (Sleex ใช้ config แบบ Lua)
- Quickshell และ Qt ≥ 6.8

| Distro | สถานะ |
|---|---|
| Debian 13 (trixie) | ✅ เปิด `trixie-backports` ให้อัตโนมัติ |
| Debian testing / sid | ✅ |
| Ubuntu / Mint | ❌ Hyprland ใน repo ยังเก่ากว่า 0.55 (สคริปต์จะหยุดตั้งแต่ต้น) |

## วิธีใช้ / Usage

```bash
git clone https://github.com/Moxier/sleex-debian
cd sleex-debian
sudo ./install-sleex-debian.sh
```

จากนั้น logout แล้วเลือก session **Sleex** ที่หน้า login
Then log out and choose the **Sleex** session in your display manager.

## สคริปต์ทำอะไรบ้าง / What it does

1. เช็กเวอร์ชัน Hyprland / Quickshell / Qt ก่อนเริ่ม ถ้าไม่ถึงจะหยุดทันที
2. ติดตั้ง dependency จาก PKGBUILD ของ Arch ที่แปลงเป็นชื่อแพ็กเกจ Debian (ตัวที่ไม่มีใน repo จะข้ามและสรุปให้ดูตอนจบ)
3. Build จาก source: ปลั๊กอิน QML ของ Sleex, `sleex-ui-kit`, `sleex-welcome-screen`, `hypnos`
4. ดาวน์โหลดของที่ Arch ได้จาก AUR: matugen, เคอร์เซอร์ Bibata, ธีม adw-gtk3, ฟอนต์ (Material Symbols, Gabarito, Rubik, Readex Pro, JetBrains Mono Nerd), hyprshot, papirus-folders
5. แพตช์สำหรับ Debian:
   - `qt_standard_project_setup(REQUIRES 6.9)` → 6.8 (เฉพาะเมื่อ Qt < 6.9)
   - กฎ polkit กลุ่ม `wheel` → `sudo`
   - venv แยกสำหรับ `materialyoucolor` (ไม่ pip ลงระบบ)
   - ใช้ `Hyprland` ตรงๆ ถ้าไม่มี `start-hyprland`
6. คัดลอก config เริ่มต้นให้ผู้ใช้ที่รัน sudo **โดยไม่ทับไฟล์เดิม**

## ข้อจำกัดที่รู้อยู่ / Known limitations

- ถ้าปลั๊กอินของ Sleex ใช้ API เฉพาะ Qt 6.9 จะ build ไม่ผ่านบน Debian 13 (testing/sid ไม่มีปัญหา)
- API ของ Lua config ใน Hyprland 0.55 (backports) อาจต่างจากเวอร์ชันที่ AxOS ใช้
- `hypnos` อาจ build ไม่ผ่านถ้า Rust ของ Debian เก่าไป → ฟีเจอร์ idle/auto-lock ใช้ไม่ได้ (สคริปต์เตือนแล้วทำต่อ)
- ไม่รวม: Howdy (สแกนหน้า), Mission Center, breeze-plus, สคริปต์ uninstall

## License

GPL-3.0 เหมือนกับ Sleex ต้นทาง / GPL-3.0, same as upstream Sleex.
