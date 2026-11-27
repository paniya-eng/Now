"""تنظیمات ویندوز بعد از `flutter create`: نام برنامه، اندازهٔ پنجره، دکمهٔ ×، حالت ویجت."""
import os
import re


def rd(p):
    return open(p, encoding='utf-8').read()


def wr(p, s):
    open(p, 'w', encoding='utf-8').write(s)


TITLE = 'L"Now / \\u0627\\u0644\\u0622\\u0646"'

# ---------- نام فایل اجرایی و عنوان پنجره ----------
cm = 'windows/CMakeLists.txt'
if os.path.exists(cm):
    s = rd(cm)
    s = re.sub(r'set\(BINARY_NAME\s+"[^"]*"\)', 'set(BINARY_NAME "Now")', s, count=1)
    wr(cm, s)
    print('binary name -> Now')

mp = 'windows/runner/main.cpp'
if os.path.exists(mp):
    s = rd(mp)
    s = s.replace('L"now_app"', TITLE)
    s = re.sub(r'size\(1280,\s*720\)', 'size(360, 780)', s)
    wr(mp, s)
    print('window title/size set')

rc = 'windows/runner/Runner.rc'
if os.path.exists(rc):
    s = rd(rc)
    s = s.replace('now_app.exe', 'Now.exe').replace('"now_app"', '"Now"')
    wr(rc, s)

# ---------- کد بومی: کوچک شدن با ×، بازگرداندن پنجره، حالت ویجت ----------
fw = 'windows/runner/flutter_window.cpp'
INCLUDES = '''#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
'''
GLOBALS = '''
static bool g_close_minimizes = true;
static bool g_widget_mode = false;
static RECT g_saved_rect = {0, 0, 0, 0};
static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_now_channel;
'''
CHANNEL = '''
  g_now_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "now/window",
      &flutter::StandardMethodCodec::GetInstance());
  HWND now_hwnd = GetHandle();
  g_now_channel->SetMethodCallHandler(
      [now_hwnd](const flutter::MethodCall<flutter::EncodableValue>& call,
                 std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const std::string& m = call.method_name();
        if (m == "closeMode") {
          const bool* v = std::get_if<bool>(call.arguments());
          if (v) g_close_minimizes = *v;
          result->Success();
        } else if (m == "restore") {
          if (IsIconic(now_hwnd)) {
            ShowWindow(now_hwnd, SW_RESTORE);
          } else {
            ShowWindow(now_hwnd, SW_SHOW);
          }
          SetForegroundWindow(now_hwnd);
          result->Success();
        } else if (m == "minimize") {
          ShowWindow(now_hwnd, SW_MINIMIZE);
          result->Success();
        } else if (m == "widget") {
          const bool* v = std::get_if<bool>(call.arguments());
          bool on = v ? *v : false;
          double scale = FlutterDesktopGetDpiForHWND(now_hwnd) / 96.0;
          if (on && !g_widget_mode) {
            GetWindowRect(now_hwnd, &g_saved_rect);
            g_widget_mode = true;
            RECT wa;
            SystemParametersInfo(SPI_GETWORKAREA, 0, &wa, 0);
            int w = static_cast<int>(340 * scale);
            int h = static_cast<int>(210 * scale);
            int margin = static_cast<int>(20 * scale);
            ShowWindow(now_hwnd, SW_RESTORE);
            SetWindowPos(now_hwnd, HWND_TOPMOST, wa.right - w - margin, wa.top + margin, w, h, SWP_SHOWWINDOW);
          } else if (!on && g_widget_mode) {
            g_widget_mode = false;
            SetWindowPos(now_hwnd, HWND_NOTOPMOST, g_saved_rect.left, g_saved_rect.top,
                         g_saved_rect.right - g_saved_rect.left, g_saved_rect.bottom - g_saved_rect.top,
                         SWP_SHOWWINDOW);
          }
          result->Success();
        } else {
          result->NotImplemented();
        }
      });
'''
CLOSE = '''
  if (message == WM_CLOSE) {
    if (g_widget_mode) {
      g_widget_mode = false;
      SetWindowPos(hwnd, HWND_NOTOPMOST, g_saved_rect.left, g_saved_rect.top,
                   g_saved_rect.right - g_saved_rect.left, g_saved_rect.bottom - g_saved_rect.top,
                   SWP_SHOWWINDOW);
      if (g_now_channel) g_now_channel->InvokeMethod("widgetClosed", nullptr);
      return 0;
    }
    if (g_close_minimizes) {
      ShowWindow(hwnd, SW_MINIMIZE);
      return 0;
    }
  }
'''


def patch_cpp(src):
    """اگر الگوی قالب پیدا نشد، None برمی‌گرداند (برنامه بدون این قابلیت‌ها ساخته می‌شود)."""
    m1 = re.search(r'#include "flutter_window.h"\n', src)
    m2 = re.search(r'\nFlutterWindow::FlutterWindow\(', src)
    m3 = re.search(r'SetChildContent\([^;]*\);\n', src)
    m4 = re.search(r'FlutterWindow::MessageHandler\([^)]*\)\s*noexcept\s*\{\n', src)
    if not (m1 and m2 and m3 and m4):
        return None
    out = src
    # از انتها به ابتدا درج می‌کنیم تا جایگاه‌ها جابه‌جا نشوند
    out = out[:m4.end()] + CLOSE + out[m4.end():]
    out = out[:m3.end()] + CHANNEL + out[m3.end():]
    out = out[:m2.start()] + '\n' + GLOBALS + out[m2.start():]
    out = out[:m1.end()] + INCLUDES + out[m1.end():]
    return out


if os.path.exists(fw):
    patched = patch_cpp(rd(fw))
    if patched is None:
        print('WARNING: flutter_window.cpp template not recognised; skipping native window features')
    else:
        wr(fw, patched)
        print('native window features added')
