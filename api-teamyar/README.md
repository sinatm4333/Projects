# API Teamyar

مستندات API های تیمیار، گروه‌بندی‌شده بر اساس ماژول پورتال.

مجموعاً **336 API** در **22 ماژول**.

## ساختار

هر ماژول یک پوشه دارد و هر API یک فایل `{نام_api}.md` شامل آدرس (endpoint)،
بدنه درخواست، بدنه پاسخ و جدول فیلدها با نوع و توضیح فارسی.

منبع: راهنمای API باشگاه مشتریان تیمیار.

## داشبورد من (خانه)

| API | آدرس | توضیح |
|-----|------|-------|
| [add_linkmodule](%D8%AF%D8%A7%D8%B4%D8%A8%D9%88%D8%B1%D8%AF%20%D9%85%D9%86%20(%D8%AE%D8%A7%D9%86%D9%87)/add_linkmodule.md) | `/api/add_linkmodule` | ایجاد لینک بین ماژول ها |
| [deleteLinks](%D8%AF%D8%A7%D8%B4%D8%A8%D9%88%D8%B1%D8%AF%20%D9%85%D9%86%20(%D8%AE%D8%A7%D9%86%D9%87)/deleteLinks.md) | `/api/deleteLinks` | حذف لینک تیمیاری |
| [removeLinkModule](%D8%AF%D8%A7%D8%B4%D8%A8%D9%88%D8%B1%D8%AF%20%D9%85%D9%86%20(%D8%AE%D8%A7%D9%86%D9%87)/removeLinkModule.md) | `/api/removeLinkModule` | حذف لینک تیمیاری |
| [removePopup](%D8%AF%D8%A7%D8%B4%D8%A8%D9%88%D8%B1%D8%AF%20%D9%85%D9%86%20(%D8%AE%D8%A7%D9%86%D9%87)/removePopup.md) | `/api/removePopup` | حذف پاپ آپ |
| [show_popup](%D8%AF%D8%A7%D8%B4%D8%A8%D9%88%D8%B1%D8%AF%20%D9%85%D9%86%20(%D8%AE%D8%A7%D9%86%D9%87)/show_popup.md) | `/api/show_popup` | ایجاد popup |

## سایت

| API | آدرس | توضیح |
|-----|------|-------|
| [user/login](%D8%B3%D8%A7%DB%8C%D8%AA/user_login.md) | `/api/user/login` | لاگین کردن در پورتال |
| [user/login/token](%D8%B3%D8%A7%DB%8C%D8%AA/user_login_token.md) | `/api/user/login/token` | ایجاد توکن جهت لاگین در پورتال |
| [user/password/change](%D8%B3%D8%A7%DB%8C%D8%AA/user_password_change.md) | `/api/user/password/change` | تغییر رمز کاربر |
| [user/password/check](%D8%B3%D8%A7%DB%8C%D8%AA/user_password_check.md) | `/api/user/password/check` | چک پسورد کاربر |
| [user/password/forgot/change](%D8%B3%D8%A7%DB%8C%D8%AA/user_password_forgot_change.md) | `/api/user/password/forgot/change` | فراموشی رمز عبور |
| [user/password/forgot/sendSecurityCode](%D8%B3%D8%A7%DB%8C%D8%AA/user_password_forgot_sendSecurityCode.md) | `/api/user/password/forgot/sendSecurityCode` | ارسال کد امنیتی |

## پروفایل

| API | آدرس | توضیح |
|-----|------|-------|
| [profile/getInfo](%D9%BE%D8%B1%D9%88%D9%81%D8%A7%DB%8C%D9%84/profile_getInfo.md) | `/api/profile/getInfo` | دریافت پروفایل ها |
| [profile/getProfile](%D9%BE%D8%B1%D9%88%D9%81%D8%A7%DB%8C%D9%84/profile_getProfile.md) | `/api/profile/getProfile` | دریافت اطلاعات پروفایل |
| [profile/update](%D9%BE%D8%B1%D9%88%D9%81%D8%A7%DB%8C%D9%84/profile_update.md) | `/api/profile/update` | آپدیت پروفایل |

## اسناد

| API | آدرس | توضیح |
|-----|------|-------|
| [client/getFolderId](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/client_getFolderId.md) | `/api/client/getFolderId` | گرفتن شناسه پوشه مشتری |
| [client/getRootId](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/client_getRootId.md) | `/api/client/getRootId` | گرفتن پوشه ی مشتریان |
| [client/getSubfolderId](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/client_getSubfolderId.md) | `/api/client/getSubfolderId` | گرفتن زیر پوشه های پوشه مشتری |
| [client/updateFolderId](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/client_updateFolderId.md) | `/api/client/updateFolderId` | به روز رسانی پوشه مشتریان |
| [client/updateFolderName](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/client_updateFolderName.md) | `/api/client/updateFolderName` | تغییر نام پوشه مشتری |
| [createDocumentFile](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/createDocumentFile.md) | `/api/createDocumentFile` | ایجاد سند |
| [createDocumentFolder](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/createDocumentFolder.md) | `/api/createDocumentFolder` | ایجاد پوشه |
| [deleteDocumentWithCheck](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/deleteDocumentWithCheck.md) | `/api/deleteDocumentWithCheck` | حذف سند به همراه چک |
| [document/addComment](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/document_addComment.md) | `/api/document/addComment` | اضافه کردن کامنت |
| [document/attach](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/document_attach.md) | `/api/document/attach` | منگنه کردن فایل |
| [document/deleteAdditionalVersions](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/document_deleteAdditionalVersions.md) | `/api/document/deleteAdditionalVersions` | حذف ورژن های فایل |
| [document/deletePermission](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/document_deletePermission.md) | `/api/document/deletePermission` | حذف دسترسی های پوشه ای که برای پورتال انتخاب شده است |
| [document/detach](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/document_detach.md) | `/api/document/detach` | بازکردن منگنه |
| [document/getByMetadata](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/document_getByMetadata.md) | `/api/document/getByMetadata` | گرفتن سند از طریق متادیتا |
| [document/getCreatedTokenForPortal](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/document_getCreatedTokenForPortal.md) | `/api/document/getCreatedTokenForPortal` | /api/document/getCreatedTokenForPortal |
| [document/getInfo](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/document_getInfo.md) | `/api/document/getInfo` | گرفتن اطلاعات یک سند |
| [document/getName](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/document_getName.md) | `/api/document/getName` | دریافت نام سند |
| [document/getSignStatus](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/document_getSignStatus.md) | `/api/document/getSignStatus` | دریافت وضعیت سند |
| [document/list](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/document_list.md) | `/api/document/list` | گرفتن لیست اسناد |
| [document/refuseSignStatus](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/document_refuseSignStatus.md) | `/api/document/refuseSignStatus` | رد سند |
| [document/setSignStatus](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/document_setSignStatus.md) | `/api/document/setSignStatus` | تایید سند |
| [document/setVerifiers](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/document_setVerifiers.md) | `/api/document/setVerifiers` | تغییر در افراد مطلع، تایید کننده، مسئول و امضا کننده |
| [folder/getAutoNamingSetting](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/folder_getAutoNamingSetting.md) | `/api/folder/getAutoNamingSetting` | گرفتن نام خودکار سند |
| [folder/getDisplayName](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/folder_getDisplayName.md) | `/api/folder/getDisplayName` | گرفتن نام فولدر |
| [getAutoName](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/getAutoName.md) | `/api/getAutoName` | ساخت نام خوکار سند |
| [setting/template/folder/getUserType](%D8%A7%D8%B3%D9%86%D8%A7%D8%AF/setting_template_folder_getUserType.md) | `/api/setting/template/folder/getUserType` | گرفتن نوع زیرپوشه مشتریان |

## اقدام

| API | آدرس | توضیح |
|-----|------|-------|
| [todo/category/list/get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_category_list_get.md) | `/api/todo/category/list/get` | دریافت لیست رده های یک بخش |
| [todo/category/update](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_category_update.md) | `/api/todo/category/update` | بروزرسانی رده |
| [todo/customform/get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_customform_get.md) | `/api/todo/customform/get` | دریافت فرم سفارشی |
| [todo/customform/multi_get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_customform_multi_get.md) | `/api/todo/customform/multi_get` | دریافت فرم سفارشی توضیحات |
| [todo/customform/update](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_customform_update.md) | `/api/todo/customform/update` | به روزرسانی فرم سفارشی |
| [todo/delcheck/stock](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_delcheck_stock.md) | `/api/todo/delcheck/stock` | چک وجود انبار در ماژول اقدام |
| [todo/registerform](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_registerform.md) | `/api/todo/registerform` | فراخوانی فرم ماژول های دیگر در اقدام |
| [todo/registerform/delete](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_registerform_delete.md) | `/api/todo/registerform/delete` | حذف فرم مرحله ثبت شده در فرم های اقدام |
| [todo/section/get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_section_get.md) | `/api/todo/section/get` | دریافت اطلاعات بخش |
| [todo/section/list/get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_section_list_get.md) | `/api/todo/section/list/get` | دریافت لیست بخش های اقدام |
| [todo/section/update](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_section_update.md) | `/api/todo/section/update` | بروز رسانی اطلاعات بخش |
| [todo/step/get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_step_get.md) | `/api/todo/step/get` | دریافت اطلاعات مرحله جریان کار |
| [todo/task/assignadd](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_task_assignadd.md) | `/api/todo/task/assignadd` | اساین کردن کاربران در اقدام |
| [todo/task/comment/add](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_task_comment_add.md) | `/api/todo/task/comment/add` | افزودن کامنت به مرحله اقدام |
| [todo/task/crm/add](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_task_crm_add.md) | `/api/todo/task/crm/add` | افزودن مشتری به اقدام |
| [todo/task/event/add](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_task_event_add.md) | `/api/todo/task/event/add` | افزودن رویداد به اقدام |
| [todo/task/get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_task_get.md) | `/api/todo/task/get` | دریافت اطلاعات اقدام |
| [todo/task/list/crm/get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_task_list_crm_get.md) | `/api/todo/task/list/crm/get` | دریافت لیست اقداماتی که یک مشتری در آن اقدام اساین شده است |
| [todo/task/list/get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_task_list_get.md) | `/api/todo/task/list/get` | دریافت اطلاعات اقدام |
| [todo/task/list/link/get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_task_list_link_get.md) | `/api/todo/task/list/link/get` | لیست تسک های لینک شده |
| [todo/task/permcheck/view](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_task_permcheck_view.md) | `/api/todo/task/permcheck/view` | چک دسترسی کاربر روی اقدام |
| [todo/task/status/set](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_task_status_set.md) | `/api/todo/task/status/set` | تغییر وضعیت اقدام |
| [todo/task/stepadd](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_task_stepadd.md) | `/api/todo/task/stepadd` | افزودن مرحله در اقدام |
| [todo/task/taskstep/responsible/set](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_task_taskstep_responsible_set.md) | `/api/todo/task/taskstep/responsible/set` | تغییر مسئول مرحله در اقدام |
| [todo/taskadd](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_taskadd.md) | `/api/todo/taskadd` | ایجاد اقدام |
| [todo/taskedit](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_taskedit.md) | `/api/todo/taskedit` | ویرایش اقدام |
| [todo/taskstep/change/perm/check](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_taskstep_change_perm_check.md) | `/api/todo/taskstep/change/perm/check` | /api/todo/taskstep/change/perm/check |
| [todo/taskstep/status/get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_taskstep_status_get.md) | `/api/todo/taskstep/status/get` | دریافت وضعیت مرحله اقدام |
| [todo/taskstep/status/set](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_taskstep_status_set.md) | `/api/todo/taskstep/status/set` | تغییر وضعیت مرحله اقدام |
| [todo/taskstep/update](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_taskstep_update.md) | `/api/todo/taskstep/update` | افزودن مرحله با مسئول و مهلت در اقدام |
| [todo/topic/get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_topic_get.md) | `/api/todo/topic/get` | دریافت عنوان موضوع |
| [todo/topic/list/get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_topic_list_get.md) | `/api/todo/topic/list/get` | دریافت لیست موضوعات رده اقدام |
| [todo/wf/addtask/get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_wf_addtask_get.md) | `/api/todo/wf/addtask/get` | دریافت اطلاعات جریان کار اقدام * |
| [todo/wf/addtasklist/get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_wf_addtasklist_get.md) | `/api/todo/wf/addtasklist/get` | دریافت لیست جریان کارهای رده اقدام |
| [todo/wf/get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_wf_get.md) | `/api/todo/wf/get` | دریافت اطلاعات جریان کار |
| [todo/wf/list/get](%D8%A7%D9%82%D8%AF%D8%A7%D9%85/todo_wf_list_get.md) | `/api/todo/wf/list/get` | دریافت لیست اطلاعات جریان های کار یک رده |

## اتاق

| API | آدرس | توضیح |
|-----|------|-------|
| [assign/add](%D8%A7%D8%AA%D8%A7%D9%82/assign_add.md) | `/api/assign/add` | اساین کردن به گفتگو |
| [dialog/add](%D8%A7%D8%AA%D8%A7%D9%82/dialog_add.md) | `/api/dialog/add` | ایجاد کانال یا گفتگو گروهی با پیام پیش فرض و اساین کردن کاربران |
| [dialog/assign](%D8%A7%D8%AA%D8%A7%D9%82/dialog_assign.md) | `/api/dialog/assign` | /api/dialog/assign |
| [dialog/close](%D8%A7%D8%AA%D8%A7%D9%82/dialog_close.md) | `/api/dialog/close` | /api/dialog/close |
| [dialog/delete](%D8%A7%D8%AA%D8%A7%D9%82/dialog_delete.md) | `/api/dialog/delete` | حذف گفتگو |
| [dialog/favorite](%D8%A7%D8%AA%D8%A7%D9%82/dialog_favorite.md) | `/api/dialog/favorite` | /api/dialog/favorite |
| [dialog/forward_list](%D8%A7%D8%AA%D8%A7%D9%82/dialog_forward_list.md) | `/api/dialog/forward_list` | /api/dialog/forward_list |
| [dialog/get](%D8%A7%D8%AA%D8%A7%D9%82/dialog_get.md) | `/api/dialog/get` | گرفتن مشخصات گفتگو |
| [dialog/get_id](%D8%A7%D8%AA%D8%A7%D9%82/dialog_get_id.md) | `/api/dialog/get_id` | /api/dialog/get_id |
| [dialog/get_typing](%D8%A7%D8%AA%D8%A7%D9%82/dialog_get_typing.md) | `/api/dialog/get_typing` | /api/dialog/get_typing |
| [dialog/join](%D8%A7%D8%AA%D8%A7%D9%82/dialog_join.md) | `/api/dialog/join` | /api/dialog/join |
| [dialog/list](%D8%A7%D8%AA%D8%A7%D9%82/dialog_list.md) | `/api/dialog/list` | /api/dialog/list |
| [dialog/members](%D8%A7%D8%AA%D8%A7%D9%82/dialog_members.md) | `/api/dialog/members` | /api/dialog/members |
| [dialog/mute](%D8%A7%D8%AA%D8%A7%D9%82/dialog_mute.md) | `/api/dialog/mute` | /api/dialog/mute |
| [dialog/public/add](%D8%A7%D8%AA%D8%A7%D9%82/dialog_public_add.md) | `/api/dialog/public/add` | اضافه کردن گفتگوی عمومی |
| [dialog/public/close](%D8%A7%D8%AA%D8%A7%D9%82/dialog_public_close.md) | `/api/dialog/public/close` | بستن گفتگوی عمومی |
| [dialog/return](%D8%A7%D8%AA%D8%A7%D9%82/dialog_return.md) | `/api/dialog/return` | /api/dialog/return |
| [dialog/typing](%D8%A7%D8%AA%D8%A7%D9%82/dialog_typing.md) | `/api/dialog/typing` | /api/dialog/typing |
| [group/add](%D8%A7%D8%AA%D8%A7%D9%82/group_add.md) | `/api/group/add` | اضافه کردن گروه |
| [group/delete](%D8%A7%D8%AA%D8%A7%D9%82/group_delete.md) | `/api/group/delete` | /api/group/delete |
| [group/get](%D8%A7%D8%AA%D8%A7%D9%82/group_get.md) | `/api/group/get` | دریافت اطلاعات گروه |
| [group/list](%D8%A7%D8%AA%D8%A7%D9%82/group_list.md) | `/api/group/list` | لیست گروه های ماژول گفتگو |
| [group/update](%D8%A7%D8%AA%D8%A7%D9%82/group_update.md) | `/api/group/update` | بروزرسانی اطلاعات گروه |
| [message/add](%D8%A7%D8%AA%D8%A7%D9%82/message_add.md) | `/api/message/add` | اضافه کردن پیام به یک گفتگو |
| [message/delete](%D8%A7%D8%AA%D8%A7%D9%82/message_delete.md) | `/api/message/delete` | /api/message/delete |
| [message/edit](%D8%A7%D8%AA%D8%A7%D9%82/message_edit.md) | `/api/message/edit` | /api/message/edit |
| [message/forward](%D8%A7%D8%AA%D8%A7%D9%82/message_forward.md) | `/api/message/forward` | /api/message/forward |
| [message/get](%D8%A7%D8%AA%D8%A7%D9%82/message_get.md) | `/api/message/get` | دریافت پیغام های گفتگو |
| [message/public/add](%D8%A7%D8%AA%D8%A7%D9%82/message_public_add.md) | `/api/message/public/add` | ارسال پیغام به گفتگوی عمومی |
| [message/public/get](%D8%A7%D8%AA%D8%A7%D9%82/message_public_get.md) | `/api/message/public/get` | دریافت پیغام های گفتگوی عمومی |
| [message/search](%D8%A7%D8%AA%D8%A7%D9%82/message_search.md) | `/api/message/search` | جستجو در پیغام های گفتگو |
| [topic/list](%D8%A7%D8%AA%D8%A7%D9%82/topic_list.md) | `/api/topic/list` | /api/topic/list |
| [topic/update](%D8%A7%D8%AA%D8%A7%D9%82/topic_update.md) | `/api/topic/update` | /api/topic/update |

## حسابداری

| API | آدرس | توضیح |
|-----|------|-------|
| [account_info/get](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/account_info_get.md) | `/api/account_info/get` | دربافت مقدار بدهکار و بستانکار و مانده یک حساب |
| [currency/convert/get](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/currency_convert_get.md) | `/api/currency/convert/get` | تبدیل نرخ ارز |
| [fiscalYear/get](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/fiscalYear_get.md) | `/api/fiscalYear/get` | /api/fiscalYear/get |
| [fiscalYear/list](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/fiscalYear_list.md) | `/api/fiscalYear/list` | /api/fiscalYear/list |
| [newClient/create](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/newClient_create.md) | `/api/newClient/create` | /api/newClient/create |
| [organization/get](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/organization_get.md) | `/api/organization/get` | /api/organization/get |
| [organization/list](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/organization_list.md) | `/api/organization/list` | /api/organization/list |
| [pdc/cash/confirm](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/pdc_cash_confirm.md) | `/api/pdc/cash/confirm` | /api/pdc/cash/confirm |
| [pdc/cash/create](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/pdc_cash_create.md) | `/api/pdc/cash/create` | /api/pdc/cash/create |
| [pdc/cash/delete](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/pdc_cash_delete.md) | `/api/pdc/cash/delete` | /api/pdc/cash/delete |
| [pdc/cash/unconfirm](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/pdc_cash_unconfirm.md) | `/api/pdc/cash/unconfirm` | /api/pdc/cash/unconfirm |
| [pdc/cheque/create](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/pdc_cheque_create.md) | `/api/pdc/cheque/create` | ثبت چک |
| [pdc/cheque/delete](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/pdc_cheque_delete.md) | `/api/pdc/cheque/delete` | /api/pdc/cheque/delete |
| [pdc/unit/list](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/pdc_unit_list.md) | `/api/pdc/unit/list` | /api/pdc/unit/list |
| [pettyCashDetail/create](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/pettyCashDetail_create.md) | `/api/pettyCashDetail/create` | /api/pettyCashDetail/create |
| [request/create](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/request_create.md) | `/api/request/create` | /api/request/create |
| [request/delete](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/request_delete.md) | `/api/request/delete` | حذف درخواست خزانه داری |
| [request/get](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/request_get.md) | `/api/request/get` | دریافت اطلاعات درخواست خزانه داری |
| [request/salary/get](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/request_salary_get.md) | `/api/request/salary/get` | گرفتن جزئیات درخواست |
| [request/update](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/request_update.md) | `/api/request/update` | /api/request/update |
| [symbol/currencyFeeList/get](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/symbol_currencyFeeList_get.md) | `/api/symbol/currencyFeeList/get` | دریافت لیست نرخ تبدیل ارزها |
| [symbol/currencyFee/get](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/symbol_currencyFee_get.md) | `/api/symbol/currencyFee/get` | دریافت نرخ تبدیل ارز |
| [symbol/get](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/symbol_get.md) | `/api/symbol/get` | دریافت لیست ارز در حسابداری |
| [symbol/update](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/symbol_update.md) | `/api/symbol/update` | ویرایش نرخ برابری ارز |
| [voucher/create](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/voucher_create.md) | `/api/voucher/create` | درج سند حسابداری |
| [voucher/records_update](%D8%AD%D8%B3%D8%A7%D8%A8%D8%AF%D8%A7%D8%B1%DB%8C/voucher_records_update.md) | `/api/voucher/records_update` | آپدیت شرح رکورد حسابداری |

## پست

| API | آدرس | توضیح |
|-----|------|-------|
| [email/emailmsgadd](%D9%BE%D8%B3%D8%AA/email_emailmsgadd.md) | `/api/email/emailmsgadd` | ایجاد ایمیل |
| [email/getAddresses](%D9%BE%D8%B3%D8%AA/email_getAddresses.md) | `/api/email/getAddresses` | گرفتن ایمیل آدرس ها |
| [email/getAddressesCount](%D9%BE%D8%B3%D8%AA/email_getAddressesCount.md) | `/api/email/getAddressesCount` | تعداد ایمیل آدرس ها |
| [email/getAssigned](%D9%BE%D8%B3%D8%AA/email_getAssigned.md) | `/api/email/getAssigned` | گرفتن مطلعین |
| [email/getAssignedCount](%D9%BE%D8%B3%D8%AA/email_getAssignedCount.md) | `/api/email/getAssignedCount` | تعداد مطلعین |
| [email/getMessage](%D9%BE%D8%B3%D8%AA/email_getMessage.md) | `/api/email/getMessage` | گرفتن اطلاعات ایمیل |
| [email/getMessageDetail](%D9%BE%D8%B3%D8%AA/email_getMessageDetail.md) | `/api/email/getMessageDetail` | /api/email/getMessageDetail |
| [email/getMessagesByLinkId](%D9%BE%D8%B3%D8%AA/email_getMessagesByLinkId.md) | `/api/email/getMessagesByLinkId` | گرفتن ایمیل ها با استفاده از لینک |
| [email/getMessagesCountByLinkId](%D9%BE%D8%B3%D8%AA/email_getMessagesCountByLinkId.md) | `/api/email/getMessagesCountByLinkId` | گرفتن تعداد ایمیل ها با استفاده از لینک |
| [email/getMessagesTotalCountByLinkId](%D9%BE%D8%B3%D8%AA/email_getMessagesTotalCountByLinkId.md) | `/api/email/getMessagesTotalCountByLinkId` | گرفتن تعداد کل ایمیل ها با استفاده از لینک |
| [email/mailcore/send](%D9%BE%D8%B3%D8%AA/email_mailcore_send.md) | `/api/email/mailcore/send` | /api/email/mailcore/send |
| [email/message/comment/add](%D9%BE%D8%B3%D8%AA/email_message_comment_add.md) | `/api/email/message/comment/add` | /api/email/message/comment/add |
| [email/send](%D9%BE%D8%B3%D8%AA/email_send.md) | `/api/email/send` | ارسال ایمیل |

## سرمایه انسانی

| API | آدرس | توضیح |
|-----|------|-------|
| [hr/baseParamValueUpdate](%D8%B3%D8%B1%D9%85%D8%A7%DB%8C%D9%87%20%D8%A7%D9%86%D8%B3%D8%A7%D9%86%DB%8C/hr_baseParamValueUpdate.md) | `/api/hr/baseParamValueUpdate` | /api/hr/baseParamValueUpdate |
| [hr/calendarDaysUpdate](%D8%B3%D8%B1%D9%85%D8%A7%DB%8C%D9%87%20%D8%A7%D9%86%D8%B3%D8%A7%D9%86%DB%8C/hr_calendarDaysUpdate.md) | `/api/hr/calendarDaysUpdate` | آپدیت روزهای تعطیل در تقویم |
| [hr/hiringGroupsGet](%D8%B3%D8%B1%D9%85%D8%A7%DB%8C%D9%87%20%D8%A7%D9%86%D8%B3%D8%A7%D9%86%DB%8C/hr_hiringGroupsGet.md) | `/api/hr/hiringGroupsGet` | لیست گروه استخدام ها |
| [hr/leaveTransferGet](%D8%B3%D8%B1%D9%85%D8%A7%DB%8C%D9%87%20%D8%A7%D9%86%D8%B3%D8%A7%D9%86%DB%8C/hr_leaveTransferGet.md) | `/api/hr/leaveTransferGet` | دریافت مقدار مانده مرخصی |
| [hr/loanUpdate](%D8%B3%D8%B1%D9%85%D8%A7%DB%8C%D9%87%20%D8%A7%D9%86%D8%B3%D8%A7%D9%86%DB%8C/hr_loanUpdate.md) | `/api/hr/loanUpdate` | /api/hr/loanUpdate |
| [hr/orderInDateGet](%D8%B3%D8%B1%D9%85%D8%A7%DB%8C%D9%87%20%D8%A7%D9%86%D8%B3%D8%A7%D9%86%DB%8C/hr_orderInDateGet.md) | `/api/hr/orderInDateGet` | دریافت حکم فعال در تاریخ مشخص |
| [hr/orderTypesGet](%D8%B3%D8%B1%D9%85%D8%A7%DB%8C%D9%87%20%D8%A7%D9%86%D8%B3%D8%A7%D9%86%DB%8C/hr_orderTypesGet.md) | `/api/hr/orderTypesGet` | نوع حکم |
| [hr/ordersAdd](%D8%B3%D8%B1%D9%85%D8%A7%DB%8C%D9%87%20%D8%A7%D9%86%D8%B3%D8%A7%D9%86%DB%8C/hr_ordersAdd.md) | `/api/hr/ordersAdd` | ایجاد گروهی حکم |
| [hr/personneladd](%D8%B3%D8%B1%D9%85%D8%A7%DB%8C%D9%87%20%D8%A7%D9%86%D8%B3%D8%A7%D9%86%DB%8C/hr_personneladd.md) | `/api/hr/personneladd` | افزودن اطلاعات پرونده های کارمندان |
| [hr/profileSupervisorGet](%D8%B3%D8%B1%D9%85%D8%A7%DB%8C%D9%87%20%D8%A7%D9%86%D8%B3%D8%A7%D9%86%DB%8C/hr_profileSupervisorGet.md) | `/api/hr/profileSupervisorGet` | دریافت سرپرست مربوط به کاربر در یک شعبه |
| [hr/vacation_update](%D8%B3%D8%B1%D9%85%D8%A7%DB%8C%D9%87%20%D8%A7%D9%86%D8%B3%D8%A7%D9%86%DB%8C/hr_vacation_update.md) | `/api/hr/vacation_update` | بروزرسانی مرخصی/مأموریت |

## مخاطب من

| API | آدرس | توضیح |
|-----|------|-------|
| [client/add/comment](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_add_comment.md) | `/api/client/add/comment` | ثبت توضیحات جدید برای مشتری |
| [client/assign/add](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_assign_add.md) | `/api/client/assign/add` | اضافه کردن مطلع به مشتری |
| [client/assign/del](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_assign_del.md) | `/api/client/assign/del` | حذف کردن مطلع از مشتری |
| [client/assign/get](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_assign_get.md) | `/api/client/assign/get` | دریافت مطلعین مشتری |
| [client/category/add](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_category_add.md) | `/api/client/category/add` | اضافه کردن مشتری به رده |
| [client/category/del](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_category_del.md) | `/api/client/category/del` | حذف کردن مشتری از رده |
| [client/check](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_check.md) | `/api/client/check` | چک کردن وجود مشتری |
| [client/contact/add](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_contact_add.md) | `/api/client/contact/add` | اضافه کردن رابط به مشتری |
| [client/contact/del](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_contact_del.md) | `/api/client/contact/del` | حذف کردن رابط از مشتری |
| [client/create](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_create.md) | `/api/client/create` | ایجاد مشتری جدید |
| [client/delete](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_delete.md) | `/api/client/delete` | حذف دائم مشتری |
| [client/get](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_get.md) | `/api/client/get` | دریافت اطلاعات مشتری |
| [client/list](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_list.md) | `/api/client/list` | /api/client/list |
| [client/moveToTrash](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_moveToTrash.md) | `/api/client/moveToTrash` | حذف موقت مشتری |
| [client/notify/add](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_notify_add.md) | `/api/client/notify/add` | ارسال نوتیفای به کاربر |
| [client/portal/add](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_portal_add.md) | `/api/client/portal/add` | ایجاد کاربر پورتال برای مشتری |
| [client/responsible/add](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_responsible_add.md) | `/api/client/responsible/add` | اضافه کردن مسئول به مشتری |
| [client/responsible/del](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_responsible_del.md) | `/api/client/responsible/del` | حذف کردن مسئول از مشتری |
| [client/responsible/get](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_responsible_get.md) | `/api/client/responsible/get` | دریافت مسئولین مشتری |
| [client/update](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/client_update.md) | `/api/client/update` | ویرایش اطلاعات مشتری |
| [section/list](%D9%85%D8%AE%D8%A7%D8%B7%D8%A8%20%D9%85%D9%86/section_list.md) | `/api/section/list` | /api/section/list |

## پیامک

| API | آدرس | توضیح |
|-----|------|-------|
| [sms/getMessageIdByTaskIdAndStepID](%D9%BE%DB%8C%D8%A7%D9%85%DA%A9/sms_getMessageIdByTaskIdAndStepID.md) | `/api/sms/getMessageIdByTaskIdAndStepID` | گرفتن شناسه پیامک |
| [sms/receive](%D9%BE%DB%8C%D8%A7%D9%85%DA%A9/sms_receive.md) | `/api/sms/receive` | دریافت پیامک |
| [sms/send](%D9%BE%DB%8C%D8%A7%D9%85%DA%A9/sms_send.md) | `/api/sms/send` | ارسال پیامک |

## محصول

| API | آدرس | توضیح |
|-----|------|-------|
| [add_product](%D9%85%D8%AD%D8%B5%D9%88%D9%84/add_product.md) | `/api/add_product` | ایجاد کالا/خدمت جدید |
| [add_product_attribute](%D9%85%D8%AD%D8%B5%D9%88%D9%84/add_product_attribute.md) | `/api/add_product_attribute` | اختصاص ویژگی به کالاها |
| [bom/delete](%D9%85%D8%AD%D8%B5%D9%88%D9%84/bom_delete.md) | `/api/bom/delete` | /api/bom/delete |
| [change_request_product_status](%D9%85%D8%AD%D8%B5%D9%88%D9%84/change_request_product_status.md) | `/api/change_request_product_status` | /api/change_request_product_status |
| [change_status_boms](%D9%85%D8%AD%D8%B5%D9%88%D9%84/change_status_boms.md) | `/api/change_status_boms` | تعییر وضعیت bom |
| [get_cardindex](%D9%85%D8%AD%D8%B5%D9%88%D9%84/get_cardindex.md) | `/api/get_cardindex` | محاسبه کاردکس کالا |
| [get_identify_inventory](%D9%85%D8%AD%D8%B5%D9%88%D9%84/get_identify_inventory.md) | `/api/get_identify_inventory` | /api/get_identify_inventory |
| [get_inventory](%D9%85%D8%AD%D8%B5%D9%88%D9%84/get_inventory.md) | `/api/get_inventory` | امکان ایجاد تاریخ تولید کالا برای ویژگی |
| [get_op_setting_by_id](%D9%85%D8%AD%D8%B5%D9%88%D9%84/get_op_setting_by_id.md) | `/api/get_op_setting_by_id` | اضافه شدن تنظیمات opc |
| [get_op_setting_list](%D9%85%D8%AD%D8%B5%D9%88%D9%84/get_op_setting_list.md) | `/api/get_op_setting_list` | عملیات تولیدی |
| [get_opc_detail_by_detail_id](%D9%85%D8%AD%D8%B5%D9%88%D9%84/get_opc_detail_by_detail_id.md) | `/api/get_opc_detail_by_detail_id` | افزودن opc |
| [get_opc_details_by_opc_id](%D9%85%D8%AD%D8%B5%D9%88%D9%84/get_opc_details_by_opc_id.md) | `/api/get_opc_details_by_opc_id` | افزودن opc |
| [get_opc_list](%D9%85%D8%AD%D8%B5%D9%88%D9%84/get_opc_list.md) | `/api/get_opc_list` | لیست opc ایجاد شده |
| [get_qc_template_by_product_id](%D9%85%D8%AD%D8%B5%D9%88%D9%84/get_qc_template_by_product_id.md) | `/api/get_qc_template_by_product_id` | گرفتن الگوی کیفیت کالا با شناسه کالا |
| [get_qc_template_setting_by_id](%D9%85%D8%AD%D8%B5%D9%88%D9%84/get_qc_template_setting_by_id.md) | `/api/get_qc_template_setting_by_id` | گرفتن اطلاعات تنظیمات الگوی کیفیت با شناسه (ID) |
| [get_qc_template_settings](%D9%85%D8%AD%D8%B5%D9%88%D9%84/get_qc_template_settings.md) | `/api/get_qc_template_settings` | نمایش تنظیمات الگوی کیفیت |
| [get_request_product_by_id](%D9%85%D8%AD%D8%B5%D9%88%D9%84/get_request_product_by_id.md) | `/api/get_request_product_by_id` | /api/get_request_product_by_id |
| [get_reserve_by_ref](%D9%85%D8%AD%D8%B5%D9%88%D9%84/get_reserve_by_ref.md) | `/api/get_reserve_by_ref` | رزرو مربوط به شناسه ی عملیات سمت تولید |
| [import_boms](%D9%85%D8%AD%D8%B5%D9%88%D9%84/import_boms.md) | `/api/import_boms` | درون ریزی BOM |
| [link_serials](%D9%85%D8%AD%D8%B5%D9%88%D9%84/link_serials.md) | `/api/link_serials` | API لینک سریال به عملیات |
| [update_custom_form](%D9%85%D8%AD%D8%B5%D9%88%D9%84/update_custom_form.md) | `/api/update_custom_form` | تغییر api opc برای شعبه |
| [update_operation](%D9%85%D8%AD%D8%B5%D9%88%D9%84/update_operation.md) | `/api/update_operation` | ایجاد عملیات |
| [update_operation_detail_manual_weight_and_unit](%D9%85%D8%AD%D8%B5%D9%88%D9%84/update_operation_detail_manual_weight_and_unit.md) | `/api/update_operation_detail_manual_weight_and_unit` | /api/update_operation_detail_manual_weight_and_unit |
| [update_product](%D9%85%D8%AD%D8%B5%D9%88%D9%84/update_product.md) | `/api/update_product` | اضافه کردن فیلد وزن تسهیم بهای تمام شده |
| [update_product_can_accept_serial](%D9%85%D8%AD%D8%B5%D9%88%D9%84/update_product_can_accept_serial.md) | `/api/update_product_can_accept_serial` | سریال پذیر کالا از طریق API |
| [update_product_providers](%D9%85%D8%AD%D8%B5%D9%88%D9%84/update_product_providers.md) | `/api/update_product_providers` | تامین کنندگان کالا |
| [update_product_stocks](%D9%85%D8%AD%D8%B5%D9%88%D9%84/update_product_stocks.md) | `/api/update_product_stocks` | تعییر ستون تاریخ سفارش |
| [update_quantity_valid_with_request_detail_id](%D9%85%D8%AD%D8%B5%D9%88%D9%84/update_quantity_valid_with_request_detail_id.md) | `/api/update_quantity_valid_with_request_detail_id` | /api/update_quantity_valid_with_request_detail_id |
| [update_request_product_approvers](%D9%85%D8%AD%D8%B5%D9%88%D9%84/update_request_product_approvers.md) | `/api/update_request_product_approvers` | /api/update_request_product_approvers |
| [update_unit_factor](%D9%85%D8%AD%D8%B5%D9%88%D9%84/update_unit_factor.md) | `/api/update_unit_factor` | آپدیت ضریب واحد |

## تقویم

| API | آدرس | توضیح |
|-----|------|-------|
| [calendar/getUserCalendars](%D8%AA%D9%82%D9%88%DB%8C%D9%85/calendar_getUserCalendars.md) | `/api/calendar/getUserCalendars` | دریافت تقویم های کاربر |
| [event/addComment](%D8%AA%D9%82%D9%88%DB%8C%D9%85/event_addComment.md) | `/api/event/addComment` | افزودن توضیحات |
| [event/addInvitedUser](%D8%AA%D9%82%D9%88%DB%8C%D9%85/event_addInvitedUser.md) | `/api/event/addInvitedUser` | اضافه کردن کاربر به لیست مدعوین |
| [event/changeUserInviteStatus](%D8%AA%D9%82%D9%88%DB%8C%D9%85/event_changeUserInviteStatus.md) | `/api/event/changeUserInviteStatus` | تغییر وضعیت افراد در جلسه |
| [event/checkConcurrent](%D8%AA%D9%82%D9%88%DB%8C%D9%85/event_checkConcurrent.md) | `/api/event/checkConcurrent` | چک همزمانی جلسات |
| [event/deleteInvitedUser](%D8%AA%D9%82%D9%88%DB%8C%D9%85/event_deleteInvitedUser.md) | `/api/event/deleteInvitedUser` | دیلیت کردن کاربر از لیست مدعوین |
| [event/getEvent](%D8%AA%D9%82%D9%88%DB%8C%D9%85/event_getEvent.md) | `/api/event/getEvent` | دریافت یک مناسبت |
| [event/getEvents](%D8%AA%D9%82%D9%88%DB%8C%D9%85/event_getEvents.md) | `/api/event/getEvents` | دریافت چندین مناسبت با تایپ های مختلف |
| [event/updateEvent](%D8%AA%D9%82%D9%88%DB%8C%D9%85/event_updateEvent.md) | `/api/event/updateEvent` | بروزرسانی مناسبت |
| [getCalendarEvents](%D8%AA%D9%82%D9%88%DB%8C%D9%85/getCalendarEvents.md) | `/api/getCalendarEvents` | دریافت مناسبت های یک تقویم |
| [importCalendarEvents](%D8%AA%D9%82%D9%88%DB%8C%D9%85/importCalendarEvents.md) | `/api/importCalendarEvents` | ثبت مناسبت برای روز های سال |

## پروژه

| API | آدرس | توضیح |
|-----|------|-------|
| [project/AddProject](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_AddProject.md) | `/api/project/AddProject` | ایجاد پروژه جدید |
| [project/checkExistHRCalendarsInProject](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_checkExistHRCalendarsInProject.md) | `/api/project/checkExistHRCalendarsInProject` | بررسی وجود تقویم کاری پرسنلی در پروژه |
| [project/checkExistsProjectStageCrm](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_checkExistsProjectStageCrm.md) | `/api/project/checkExistsProjectStageCrm` | بررسی وجود مشتری در مرحله پروژه |
| [project/checkExistsProjectStageCrmForTaskView](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_checkExistsProjectStageCrmForTaskView.md) | `/api/project/checkExistsProjectStageCrmForTaskView` | بررسی وجود مشتری و میزان مشارکت آن در مرحله پروژه |
| [project/checkProjectShowFirstStepToAllWithProjectId](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_checkProjectShowFirstStepToAllWithProjectId.md) | `/api/project/checkProjectShowFirstStepToAllWithProjectId` | بررسی نمایش مرحله ی اول به همه کاربران در پورتال با شناسه پروژه |
| [project/customfieldupdate](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_customfieldupdate.md) | `/api/project/customfieldupdate` | بروزرسانی فیلد سفارشی |
| [project/deletePrjectStageCrm](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_deletePrjectStageCrm.md) | `/api/project/deletePrjectStageCrm` | حذف مشتری مرحله پروژه |
| [project/deleteStageLink](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_deleteStageLink.md) | `/api/project/deleteStageLink` | حذف لینک استیج پروژه |
| [project/exportProjectCSV](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_exportProjectCSV.md) | `/api/project/exportProjectCSV` | /api/project/exportProjectCSV |
| [project/getAssignedUserswithProjectIdWfId](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getAssignedUserswithProjectIdWfId.md) | `/api/project/getAssignedUserswithProjectIdWfId` | دریافت کاربران مطلع روی پروژه |
| [project/getPortalUserProjects](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getPortalUserProjects.md) | `/api/project/getPortalUserProjects` | دریافت لیست پروژه هایی که در پورتال نمایش داده میشوند |
| [project/getPortalUserProjectsId](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getPortalUserProjectsId.md) | `/api/project/getPortalUserProjectsId` | بررسی فعال بودن پروژه در پورتال |
| [project/getProject](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getProject.md) | `/api/project/getProject` | دریافت اطلاعات پروژه |
| [project/getProjectStageCRMParticipationAmount](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getProjectStageCRMParticipationAmount.md) | `/api/project/getProjectStageCRMParticipationAmount` | دریافت میزان مشارکت کاربر پورتال در پروژه |
| [project/getProjectStageCRMs](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getProjectStageCRMs.md) | `/api/project/getProjectStageCRMs` | دریافت لیست شناسه مشتریان در مرحله پروژه |
| [project/getProjectStageDescription](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getProjectStageDescription.md) | `/api/project/getProjectStageDescription` | دریافت توضیحات مرحله و هزینه پروژه |
| [project/getProjectStageProjectId](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getProjectStageProjectId.md) | `/api/project/getProjectStageProjectId` | دریافت شناسه پروژه با شناسه مرحله |
| [project/getProjectTitle](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getProjectTitle.md) | `/api/project/getProjectTitle` | دریافت عنوان پروژه |
| [project/getProjectTopicProjects](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getProjectTopicProjects.md) | `/api/project/getProjectTopicProjects` | دریافت لیست پروژه هایی که از یک موضوع اقدام استفاده کرده اند |
| [project/getProjectTopics](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getProjectTopics.md) | `/api/project/getProjectTopics` | دریافت لیست موضوعات اقدام استفاده شده در پروژه ها |
| [project/getProjects](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getProjects.md) | `/api/project/getProjects` | جستجو در عنوان پروژه |
| [project/getProjectsWithLink](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getProjectsWithLink.md) | `/api/project/getProjectsWithLink` | لیست پروژه های لینک شده |
| [project/getProjectsWithLinkCount](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getProjectsWithLinkCount.md) | `/api/project/getProjectsWithLinkCount` | تعداد پروژه هایی که لینک هستند |
| [project/getStageFlags](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getStageFlags.md) | `/api/project/getStageFlags` | دریافت وضعیت مرحله پروژه |
| [project/getStages](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getStages.md) | `/api/project/getStages` | دریافت مراحل پروژه |
| [project/getTitleProjects](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getTitleProjects.md) | `/api/project/getTitleProjects` | دریافت عنوان پروژه ها *** |
| [project/getTodoProjects](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getTodoProjects.md) | `/api/project/getTodoProjects` | دریافت عنوان و شناسه پروژه با شناسه اقدامی که لینک به مرحله شده است |
| [project/getTodoTaskProjectStages](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_getTodoTaskProjectStages.md) | `/api/project/getTodoTaskProjectStages` | دریافت شناسه پروژه ها و شناسه مراحلی که به اقدام لینک هستند |
| [project/gettopicprojects](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_gettopicprojects.md) | `/api/project/gettopicprojects` | API گرفتن نام پروژه با شناسه موضوع |
| [project/showPortalProjectViewImage](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_showPortalProjectViewImage.md) | `/api/project/showPortalProjectViewImage` | دریافت عکس پروژه با شناسه پروژه |
| [project/showProjectImage](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_showProjectImage.md) | `/api/project/showProjectImage` | بررسی وجود / عدم وجود عکس برای پروژه*** |
| [project/stageupdate](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_stageupdate.md) | `/api/project/stageupdate` | ویرایش استیج های پروژه |
| [project/updatePrjectStageCrm](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_updatePrjectStageCrm.md) | `/api/project/updatePrjectStageCrm` | اضافه کردن مشتری به مرحله پروژه |
| [project/updatePrjectStagesCrm](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_updatePrjectStagesCrm.md) | `/api/project/updatePrjectStagesCrm` | بروزرسانی مشتریان مرحله پروژه |
| [project/updateProjectStage](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_updateProjectStage.md) | `/api/project/updateProjectStage` | بروزرسانی مرحله پروژه |
| [project/updateProjectStageCrmPartipationAmountPortal](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_updateProjectStageCrmPartipationAmountPortal.md) | `/api/project/updateProjectStageCrmPartipationAmountPortal` | بروزرسانی مقدار مشارکت مشتری در مرحله پروژه |
| [project/updateStage](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_updateStage.md) | `/api/project/updateStage` | بروزرسانی مرحله پروژه |
| [project/updateStageLink](%D9%BE%D8%B1%D9%88%DA%98%D9%87/project_updateStageLink.md) | `/api/project/updateStageLink` | بروزرسانی لینک مرحله پروژه |

## شعبه

| API | آدرس | توضیح |
|-----|------|-------|
| [organization/conf_tpl/data/get](%D8%B4%D8%B9%D8%A8%D9%87/organization_conf_tpl_data_get.md) | `/api/organization/conf_tpl/data/get` | /api/organization/conf_tpl/data/get |
| [organization/default/get](%D8%B4%D8%B9%D8%A8%D9%87/organization_default_get.md) | `/api/organization/default/get` | /api/organization/default/get |
| [organization/list](%D8%B4%D8%B9%D8%A8%D9%87/organization_list.md) | `/api/organization/list` | /api/organization/list |
| [organization/unitsGet](%D8%B4%D8%B9%D8%A8%D9%87/organization_unitsGet.md) | `/api/organization/unitsGet` | /api/organization/unitsGet |

## فروش

| API | آدرس | توضیح |
|-----|------|-------|
| [invoice/create](%D9%81%D8%B1%D9%88%D8%B4/invoice_create.md) | `/api/invoice/create` | ایجاد فاکتور فروش پیش نویس |
| [invoice/get](%D9%81%D8%B1%D9%88%D8%B4/invoice_get.md) | `/api/invoice/get` | گرفتن اطلاعات فاکتور |
| [sales/back_status](%D9%81%D8%B1%D9%88%D8%B4/sales_back_status.md) | `/api/sales/back_status` | تغییر وضعیت عملیات به قبل |
| [sales/cancel_delete_invoice](%D9%81%D8%B1%D9%88%D8%B4/sales_cancel_delete_invoice.md) | `/api/sales/cancel_delete_invoice` | ابطال و حذف عملیات فروش |
| [sales/create_settlement](%D9%81%D8%B1%D9%88%D8%B4/sales_create_settlement.md) | `/api/sales/create_settlement` | ایجاد تسویه برای فاکتور فروش |
| [sales/get_custom_form](%D9%81%D8%B1%D9%88%D8%B4/sales_get_custom_form.md) | `/api/sales/get_custom_form` | دریافت اطلاعات فرم سفارشی |
| [sales/get_sales_agents](%D9%81%D8%B1%D9%88%D8%B4/sales_get_sales_agents.md) | `/api/sales/get_sales_agents` | دریافت لیست عوامل فروش |
| [sales/invoice/get_balance](%D9%81%D8%B1%D9%88%D8%B4/sales_invoice_get_balance.md) | `/api/sales/invoice/get_balance` | مبلغ و مانده فاکتور |
| [sales/pricelist/update](%D9%81%D8%B1%D9%88%D8%B4/sales_pricelist_update.md) | `/api/sales/pricelist/update` | ثبت یک سطر در لیست قیمت فروش |
| [sales/update_invoice_history](%D9%81%D8%B1%D9%88%D8%B4/sales_update_invoice_history.md) | `/api/sales/update_invoice_history` | ثبت لاگ برای عملیات های فروش |
| [sales/update_moadian_status](%D9%81%D8%B1%D9%88%D8%B4/sales_update_moadian_status.md) | `/api/sales/update_moadian_status` | تغییر وضعیت مودیان برای فاکتور |

## خرید

| API | آدرس | توضیح |
|-----|------|-------|
| [invoice/create](%D8%AE%D8%B1%DB%8C%D8%AF/invoice_create.md) | `/api/invoice/create` | ایجاد عملیات پیش نویس خرید |
| [invoice/get](%D8%AE%D8%B1%DB%8C%D8%AF/invoice_get.md) | `/api/invoice/get` | گرفتن اطلاعات عملیات |
| [invoice/update/header_footer](%D8%AE%D8%B1%DB%8C%D8%AF/invoice_update_header_footer.md) | `/api/invoice/update/header_footer` | سر برگ و پاورقی (برای قرارداد خرید) |
| [purchase/cancel_delete_invoice](%D8%AE%D8%B1%DB%8C%D8%AF/purchase_cancel_delete_invoice.md) | `/api/purchase/cancel_delete_invoice` | حذف و ابطال عملیات |
| [purchase/invoice/get_balance](%D8%AE%D8%B1%DB%8C%D8%AF/purchase_invoice_get_balance.md) | `/api/purchase/invoice/get_balance` | گرفتن جمع کل و مانده عملیات |

## کیفیت

| API | آدرس | توضیح |
|-----|------|-------|
| [createQualitiesByTemplates](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/createQualitiesByTemplates.md) | `/api/createQualitiesByTemplates` | ایجاد کیفیت با الگو |
| [create_quality_by_template](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/create_quality_by_template.md) | `/api/create_quality_by_template` | ایجاد کیفیت از طریق الگو |
| [delete_quality_by_ref](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/delete_quality_by_ref.md) | `/api/delete_quality_by_ref` | حذف کیفیت |
| [delete_quality_by_ref_id](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/delete_quality_by_ref_id.md) | `/api/delete_quality_by_ref_id` | حذف کیفیت |
| [getQualitiesByRef](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/getQualitiesByRef.md) | `/api/getQualitiesByRef` | کنترل کیفیت |
| [getQualitiesName](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/getQualitiesName.md) | `/api/getQualitiesName` | گرفتن عنوان کیفیت ها |
| [getQualityByRefAndOrg](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/getQualityByRefAndOrg.md) | `/api/getQualityByRefAndOrg` | گرفتن کیفیت با شماره مرجع و سازمان و شناسه ماژول |
| [getQualityByRefAndOrgCount](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/getQualityByRefAndOrgCount.md) | `/api/getQualityByRefAndOrgCount` | گرفتن تعداد کیفیت با شماره مرجع و سازمان و شناسه ماژول |
| [getQualityLinks](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/getQualityLinks.md) | `/api/getQualityLinks` | /api/getQualityLinks |
| [getQualityListCountForVoterUser](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/getQualityListCountForVoterUser.md) | `/api/getQualityListCountForVoterUser` | گرفتن تعداد کیفیت هایی که یک شرکت کننده پاسخ داده است |
| [getQualityListForRelatedUserInDateRange](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/getQualityListForRelatedUserInDateRange.md) | `/api/getQualityListForRelatedUserInDateRange` | گرفتن کیفیت ها در یک بازه مهلت مشخص |
| [getQualityListForVoterUser](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/getQualityListForVoterUser.md) | `/api/getQualityListForVoterUser` | گرفتن کیفیت هایی که یک شرکت کننده پاسخ داده است |
| [getQualityName](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/getQualityName.md) | `/api/getQualityName` | گرفتن عنوان یک کیفیت |
| [getScoresForAssesseeInDateRange](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/getScoresForAssesseeInDateRange.md) | `/api/getScoresForAssesseeInDateRange` | امتیازات برای ارزیابی شونده |
| [get_quality](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/get_quality.md) | `/api/get_quality` | گرفتن اطلاعات یک کیفیت |
| [get_quality_count_by_ref](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/get_quality_count_by_ref.md) | `/api/get_quality_count_by_ref` | تعداد کیفیت های شناسه مرجع |
| [get_quality_report](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/get_quality_report.md) | `/api/get_quality_report` | گرفتن نتایج کیفیت |
| [get_quality_result_status_by_ref](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/get_quality_result_status_by_ref.md) | `/api/get_quality_result_status_by_ref` | وضعیت کیفیت های یک مرجع |
| [get_templates](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/get_templates.md) | `/api/get_templates` | گرفتن لیست الگو ها |
| [poll/answer/update](%DA%A9%DB%8C%D9%81%DB%8C%D8%AA/poll_answer_update.md) | `/api/poll/answer/update` | /api/poll/answer/update |

## بودجه

| API | آدرس | توضیح |
|-----|------|-------|
| [get_budget_amount](%D8%A8%D9%88%D8%AF%D8%AC%D9%87/get_budget_amount.md) | `/api/get_budget_amount` | /api/get_budget_amount |

## گزارش

| API | آدرس | توضیح |
|-----|------|-------|
| [categories/list](%DA%AF%D8%B2%D8%A7%D8%B1%D8%B4/categories_list.md) | `/api/categories/list` | دریافت نام رده ها |
| [reports/list](%DA%AF%D8%B2%D8%A7%D8%B1%D8%B4/reports_list.md) | `/api/reports/list` | دریافت نام گزارش ها |
| [reports/name](%DA%AF%D8%B2%D8%A7%D8%B1%D8%B4/reports_name.md) | `/api/reports/name` | دریافت نام گزارش |
| [servers/list](%DA%AF%D8%B2%D8%A7%D8%B1%D8%B4/servers_list.md) | `/api/servers/list` | دریافت سرور ها |

## خدمات

| API | آدرس | توضیح |
|-----|------|-------|
| [pm/update_service](%D8%AE%D8%AF%D9%85%D8%A7%D8%AA/pm_update_service.md) | `/api/pm/update_service` | /api/pm/update_service |
| [token/compare_token](%D8%AE%D8%AF%D9%85%D8%A7%D8%AA/token_compare_token.md) | `/api/token/compare_token` | اعتبارسنجی مقدار وارد شده توکن توسط کاربر |
| [token/request_token](%D8%AE%D8%AF%D9%85%D8%A7%D8%AA/token_request_token.md) | `/api/token/request_token` | درخواست توکن یکبار مصرف |

## تولید

| API | آدرس | توضیح |
|-----|------|-------|
| [GetEstimate](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/GetEstimate.md) | `/api/GetEstimate` | ایجاد برآورد |
| [GetMaterialAnalysis](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/GetMaterialAnalysis.md) | `/api/GetMaterialAnalysis` | برنامه ریزی مواد مورد نیاز |
| [GetMps](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/GetMps.md) | `/api/GetMps` | درخواست تولید |
| [GetOpcDetByMachineOpcOp](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/GetOpcDetByMachineOpcOp.md) | `/api/GetOpcDetByMachineOpcOp` | ماشین آلات در opc |
| [GetOpcDetSumProduction](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/GetOpcDetSumProduction.md) | `/api/GetOpcDetSumProduction` | نمودار فرایند عملیات |
| [GetOperation](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/GetOperation.md) | `/api/GetOperation` | عملیات تولیدی |
| [GetOrder](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/GetOrder.md) | `/api/GetOrder` | دستور تولید در درخواست تولید |
| [GetOrdersByPlanningId](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/GetOrdersByPlanningId.md) | `/api/GetOrdersByPlanningId` | دستور با برنامه ریزی تولید |
| [GetReport](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/GetReport.md) | `/api/GetReport` | ثبت عملکرد |
| [GetReports](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/GetReports.md) | `/api/GetReports` | ثبت عملکرد |
| [checkDeleteBom](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/checkDeleteBom.md) | `/api/checkDeleteBom` | حذف bom |
| [checkDeleteOrderEntity](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/checkDeleteOrderEntity.md) | `/api/checkDeleteOrderEntity` | حذف دستور |
| [checkDeleteProduct](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/checkDeleteProduct.md) | `/api/checkDeleteProduct` | حذف محصول |
| [checkDeleteSalesOrder](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/checkDeleteSalesOrder.md) | `/api/checkDeleteSalesOrder` | حذف سفارش فروش |
| [checkDeleteStock](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/checkDeleteStock.md) | `/api/checkDeleteStock` | حذف انبار |
| [checkEditBom](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/checkEditBom.md) | `/api/checkEditBom` | ویرایش bom |
| [checkReceiptConcluded](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/checkReceiptConcluded.md) | `/api/checkReceiptConcluded` | /api/checkReceiptConcluded |
| [checkReportStatus](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/checkReportStatus.md) | `/api/checkReportStatus` | نمایش وضعیت ثبت عملکرد |
| [getReportOperationType](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/getReportOperationType.md) | `/api/getReportOperationType` | /api/getReportOperationType |
| [line/getOpc](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/line_getOpc.md) | `/api/line/getOpc` | دریافت اطلاعات یک OPC |
| [line/opcImport](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/line_opcImport.md) | `/api/line/opcImport` | درون ریزی opc |
| [order/dailyProduction](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/order_dailyProduction.md) | `/api/order/dailyProduction` | ایجاد ثبت عملکرد روزانه |
| [prod/customform/update](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/prod_customform_update.md) | `/api/prod/customform/update` | /api/prod/customform/update |
| [prod/mps/opc_detail_quantity/update](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/prod_mps_opc_detail_quantity_update.md) | `/api/prod/mps/opc_detail_quantity/update` | /api/prod/mps/opc_detail_quantity/update |
| [report/updateOverhead](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/report_updateOverhead.md) | `/api/report/updateOverhead` | آپدیت سربارهای تولید |
| [sendProductNotify](%D8%AA%D9%88%D9%84%DB%8C%D8%AF/sendProductNotify.md) | `/api/sendProductNotify` | /api/sendProductNotify |
