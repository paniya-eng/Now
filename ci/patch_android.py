"""تنظیمات اندروید که بعد از `flutter create` اعمال می‌شود (اعلان، ویجت، دسترسی‌ها، صداها)."""
import glob
import os
import re
import shutil


def rd(p):
    return open(p, encoding='utf-8').read()


def wr(p, s):
    open(p, 'w', encoding='utf-8').write(s)


# ---------- ۱) AndroidManifest ----------
mp = 'android/app/src/main/AndroidManifest.xml'
m = rd(mp)
perms = ['INTERNET', 'POST_NOTIFICATIONS', 'SCHEDULE_EXACT_ALARM', 'USE_EXACT_ALARM',
         'RECEIVE_BOOT_COMPLETED', 'VIBRATE', 'WAKE_LOCK', 'USE_FULL_SCREEN_INTENT']
perm_xml = ''.join('\n    <uses-permission android:name="android.permission.%s"/>' % p
                   for p in perms if 'android.permission.%s"' % p not in m)
m = re.sub(r'(<manifest[^>]*>)', lambda x: x.group(1) + perm_xml, m, count=1)
m = re.sub(r'android:label="[^"]*"', 'android:label="الآن"', m, count=1)
if 'usesCleartextTraffic' not in m:
    m = m.replace('<application', '<application\n        android:usesCleartextTraffic="true"', 1)
if 'showWhenLocked' not in m:
    m = m.replace('android:name=".MainActivity"',
                  'android:name=".MainActivity"\n            android:showWhenLocked="true"\n            android:turnScreenOn="true"', 1)
receivers = '''
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
        <receiver android:name=".NowWidgetProvider" android:label="الآن (سفید)" android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
                <action android:name="android.intent.action.DATE_CHANGED"/>
                <action android:name="android.intent.action.TIME_SET"/>
                <action android:name="android.intent.action.TIMEZONE_CHANGED"/>
                <action android:name="com.now.now_app.MIDNIGHT"/>
            </intent-filter>
            <meta-data android:name="android.appwidget.provider" android:resource="@xml/now_widget_info"/>
        </receiver>
        <receiver android:name=".NowWidgetTransparentProvider" android:label="الآن (شفاف)" android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
            </intent-filter>
            <meta-data android:name="android.appwidget.provider" android:resource="@xml/now_widget_info_transparent"/>
        </receiver>
'''
m = m.replace('</application>', receivers + '    </application>', 1)
wr(mp, m)
print('patched manifest')

# ---------- ۲) Gradle (اپ) ----------
for f in ('android/app/build.gradle.kts', 'android/app/build.gradle'):
    if not os.path.exists(f):
        continue
    s = rd(f)
    kts = f.endswith('.kts')
    lint = ("android {\n    lint {\n        checkReleaseBuilds = false\n        abortOnError = false\n    }\n" if kts
            else "android {\n    lint {\n        checkReleaseBuilds false\n        abortOnError false\n    }\n")
    s = s.replace('android {\n', lint, 1)
    flag = '        isCoreLibraryDesugaringEnabled = true\n' if kts else '        coreLibraryDesugaringEnabled true\n'
    if 'compileOptions {' in s:
        s = s.replace('compileOptions {\n', 'compileOptions {\n' + flag, 1)
    deps = ('\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n' if kts
            else "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n")
    s += deps
    wr(f, s)
    print('patched', f)

# ---------- ۳) Gradle (ریشه): همهٔ افزونه‌ها با compileSdk 36 ----------
kts_root = ('subprojects {\n    afterEvaluate {\n        extensions.findByName("android")?.let { ext ->\n'
            '            ext.withGroovyBuilder { "compileSdkVersion"(36) }\n        }\n    }\n}\n\n')
groovy_root = ('subprojects {\n    afterEvaluate { project ->\n        if (project.hasProperty("android")) {\n'
               '            project.android.compileSdkVersion 36\n        }\n    }\n}\n\n')
for f, block in (('android/build.gradle.kts', kts_root), ('android/build.gradle', groovy_root)):
    if os.path.exists(f):
        wr(f, block + rd(f))
        print('patched root', f)

# ---------- ۴) کد بومی ویجت + MainActivity + صداها ----------
shutil.copytree('android_overlay', 'android/app/src/main', dirs_exist_ok=True)
os.makedirs('android/app/src/main/res/raw', exist_ok=True)
for w in glob.glob('assets/sounds/*.wav'):
    shutil.copy(w, 'android/app/src/main/res/raw/' + os.path.basename(w).lower())
# فونت درشت (وزیرمتن / فونت برنامه) برای ویجت
os.makedirs('android/app/src/main/res/font', exist_ok=True)
shutil.copy('assets/fonts/app-bold.ttf', 'android/app/src/main/res/font/app_font_bold.ttf')
shutil.copy('assets_widget/vazirmatn_fd_bold.ttf', 'android/app/src/main/res/font/app_font_fd_bold.ttf')
print('overlay + sounds + fonts copied')
