# API Teamyar

مستندات API های تیمیار، گروه‌بندی‌شده بر اساس ماژول/بخش پورتال.

دامنه پورتال: `erp.bimehland.com`

## ساختار

هر ماژول یک پوشه دارد و هر API یک فایل `{نام_api}.md` شامل آدرس (endpoint)،
بدنه درخواست، بدنه پاسخ و جدول توضیح فیلدها.

## داشبورد من (خانه)

| API | آدرس | توضیح |
|-----|------|-------|
| [show_popup](داشبورد%20من%20%28خانه%29/show_popup.md) | `/api/show_popup` | ایجاد popup |
| [removePopup](داشبورد%20من%20%28خانه%29/removePopup.md) | `/api/removePopup` | حذف پاپ‌آپ |
| [add_linkmodule](داشبورد%20من%20%28خانه%29/add_linkmodule.md) | `/api/add_linkmodule` | ایجاد لینک بین ماژول‌ها |
| [removeLinkModule](داشبورد%20من%20%28خانه%29/removeLinkModule.md) | `/api/removeLinkModule` | حذف لینک تیمیاری (بین دو ماژول) |
| [deleteLinks](داشبورد%20من%20%28خانه%29/deleteLinks.md) | `/api/deleteLinks` | حذف لینک تیمیاری |

## سایت

| API | آدرس | توضیح |
|-----|------|-------|
| [user/login](سایت/user_login.md) | `/api/user/login` | لاگین کردن در پورتال |
| [user/login/token](سایت/user_login_token.md) | `/api/user/login/token` | ایجاد توکن جهت لاگین در پورتال |
| [user/password/change](سایت/user_password_change.md) | `/api/user/password/change` | تغییر رمز کاربر |
| [user/password/check](سایت/user_password_check.md) | `/api/user/password/check` | چک پسورد کاربر |
| [user/password/forgot/sendSecurityCode](سایت/user_password_forgot_sendSecurityCode.md) | `/api/user/password/forgot/sendSecurityCode` | ارسال کد امنیتی |
| [user/password/forgot/change](سایت/user_password_forgot_change.md) | `/api/user/password/forgot/change` | فراموشی رمز عبور |

## پروفایل

| API | آدرس | توضیح |
|-----|------|-------|
| [profile/getInfo](پروفایل/profile_getInfo.md) | `/api/profile/getInfo` | دریافت پروفایل‌ها |
| [profile/getProfile](پروفایل/profile_getProfile.md) | `/api/profile/getProfile` | دریافت اطلاعات پروفایل |
| [profile/update](پروفایل/profile_update.md) | `/api/profile/update` | آپدیت پروفایل |

## اسناد

| API | آدرس | توضیح |
|-----|------|-------|
| [createDocumentFile](اسناد/createDocumentFile.md) | `/api/createDocumentFile` | ایجاد سند |
| [createDocumentFolder](اسناد/createDocumentFolder.md) | `/api/createDocumentFolder` | ایجاد پوشه |
| [deleteDocumentWithCheck](اسناد/deleteDocumentWithCheck.md) | `/api/deleteDocumentWithCheck` | حذف سند به همراه چک |
| [document/deleteAdditionalVersions](اسناد/document_deleteAdditionalVersions.md) | `/api/document/deleteAdditionalVersions` | حذف ورژن‌های فایل |
| [document/list](اسناد/document_list.md) | `/api/document/list` | فهرست اسناد |
| [document/getByMetadata](اسناد/document_getByMetadata.md) | `/api/document/getByMetadata` | گرفتن سند از طریق متادیتا |
| [document/getInfo](اسناد/document_getInfo.md) | `/api/document/getInfo` | گرفتن اطلاعات یک سند |
| [document/getName](اسناد/document_getName.md) | `/api/document/getName` | دریافت نام سند |
| [folder/getAutoNamingSetting](اسناد/folder_getAutoNamingSetting.md) | `/api/folder/getAutoNamingSetting` | گرفتن نام خودکار سند |
| [folder/getDisplayName](اسناد/folder_getDisplayName.md) | `/api/folder/getDisplayName` | گرفتن نام فولدر |
| [getAutoName](اسناد/getAutoName.md) | `/api/getAutoName` | ساخت نام خودکار سند |
| [document/attach](اسناد/document_attach.md) | `/api/document/attach` | منگنه کردن فایل |
| [document/detach](اسناد/document_detach.md) | `/api/document/detach` | بازکردن منگنه |
| [client/getRootId](اسناد/client_getRootId.md) | `/api/client/getRootId` | گرفتن پوشه‌ی مشتریان |
| [client/getFolderId](اسناد/client_getFolderId.md) | `/api/client/getFolderId` | گرفتن شناسه پوشه مشتری |
| [client/getSubfolderId](اسناد/client_getSubfolderId.md) | `/api/client/getSubfolderId` | گرفتن زیرپوشه‌های پوشه مشتری |
| [client/updateFolderId](اسناد/client_updateFolderId.md) | `/api/client/updateFolderId` | به‌روزرسانی پوشه مشتریان |
| [setting/template/folder/getUserType](اسناد/setting_template_folder_getUserType.md) | `/api/setting/template/folder/getUserType` | گرفتن نوع زیرپوشه مشتریان |
