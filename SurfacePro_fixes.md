# Surface Pro 3 Linux Fixes: Touchscreen & Kernel Upgrade

## 📝 Set 1: Permanent Touchscreen Disable via udev (Recommended)

This will kill the touchscreen at a deep level, preventing ghost taps permanently. Use this if the screen is broken and you want to be 100% sure it never interferes again.

**Step 1: Identify your device ID**

```bash
ls /sys/bus/hid/drivers/hid-multitouch/
```

Look for a line that starts with `0018:1B96:1B05.` (e.g., `0018:1B96:1B05.0002`).

**Step 2: Temporary test (disable now, resets on reboot)**

```bash
sudo sh -c 'echo -n "0018:1B96:1B05.0002" > /sys/bus/hid/drivers/hid-multitouch/unbind'
```

The touchscreen should stop working immediately. If it works, proceed.

**Step 3: Create permanent udev rule**

```bash
sudo nano /etc/udev/rules.d/99-disable-touchscreen.rules
```

Paste the following line (ensure the `0018:1B96:1B05.*` pattern matches your ID from Step 1).

```
ACTION=="add", SUBSYSTEM=="hid", DRIVERS=="hid-multitouch", KERNEL=="0018:1B96:1B05.*", RUN+="/bin/sh -c 'echo -n $kernel > /sys/bus/hid/drivers/hid-multitouch/unbind'"
```

Save with `Ctrl+O`, `Enter`, and exit with `Ctrl+X`.

**Step 4: Activate and verify**

```bash
sudo udevadm control --reload-rules
sudo reboot
```

**To revert:**

```bash
sudo rm /etc/udev/rules.d/99-disable-touchscreen.rules
sudo reboot
```

**Check if it worked after reboot:**

```bash
xinput list | grep -i "touch\|ntrg"
```

No output means the touchscreen is successfully disabled.

---

## 📝 Set 2: Install linux-surface Kernel (Improved Hardware Support)

This custom kernel from the [linux-surface](https://github.com/linux-surface/linux-surface) project provides better support for all Surface hardware, including cameras, sensors, battery status, and more. It is actively maintained, receives regular security updates via `apt`, and includes fixes for many common issues.

### ⚙️ Installation

**Step 1: Add the official repository**

```bash
sudo apt update
sudo apt install curl wget gnupg
curl -s https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc | sudo apt-key add -
echo "deb [arch=amd64] https://pkg.surfacelinux.com/debian release main" | sudo tee /etc/apt/sources.list.d/linux-surface.list
```

**Step 2: Install the kernel and components**

```bash
sudo apt update
sudo apt install linux-image-surface linux-headers-surface iptsd libwacom-surface
```

**Step 3: Update bootloader and reboot**

```bash
sudo update-grub
sudo reboot
```

**Step 4: Verify the installation**

```bash
uname -r
```

You should see a version like `5.15.84-surface-1` or newer.

### 🔄 How Updates Work

Once installed, the `linux-surface` kernel updates just like any other package. Regular system updates using `sudo apt update && sudo apt upgrade` will automatically fetch and install newer versions of the kernel. After an update, a reboot will load the new kernel version by default.

### ⏪ Switching Back to the Stock Astra Kernel

You can always switch back to the original Astra kernel.

**Method A: Temporary (one-time boot)**

1.  Reboot and hold `Shift` to enter the GRUB menu.
2.  Go to `Advanced options for Debian GNU/Linux`.
3.  Select your original Astra kernel from the list (e.g., `Debian GNU/Linux, with Linux ...`).
4.  Press `Enter` to boot.

**Method B: Permanent (change default)**

1.  Boot into the Astra kernel using the temporary method.
2.  Once logged in, run:
    ```bash
    sudo update-grub
    ```
    This will set the Astra kernel as the default for subsequent boots.

**To completely remove the linux-surface kernel:**

```bash
sudo apt purge linux-image-surface linux-headers-surface iptsd libwacom-surface
sudo update-grub
sudo reboot
```

---

## ⚠️ Notes & Troubleshooting

*   **Secure Boot:** The `linux-surface` kernel is signed and should work with Secure Boot enabled.
*   **Audio Issues:** If you experience issues with audio routing (e.g., hissing from speakers when headphones are plugged in), you may need to disable `Auto-Mute Mode`:
    ```bash
    sudo amixer sset "Auto-Mute Mode" Disabled
    ```
*   **Source:** The official `linux-surface` documentation and issue tracker is the best resource for troubleshooting.
